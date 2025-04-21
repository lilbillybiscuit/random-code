import Cocoa
import Foundation // Needed for fnmatch

// MARK: - Helper for Wildcard Matching
func wildCardMatch(_ pattern: String, _ string: String) -> Bool {
    // FNM_PATHNAME makes '*' not match '/'
    // FNM_PERIOD makes '*' not match '.' at the beginning of a component
    // FNM_NOESCAPE prevents backslashes from escaping wildcards
    return fnmatch(pattern, string, FNM_PATHNAME | FNM_PERIOD | FNM_NOESCAPE) == 0
}


// MARK: - KeyMonitorView (Handles Keyboard Shortcuts)
class KeyMonitorView: NSView {
    weak var processor: FileProcessor?
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Configure for transparency
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        if let layer = self.layer {
            layer.masksToBounds = false
            layer.isOpaque = false
        }
    }
    
    // CRITICAL: This method ensures key events are handled
    override func keyDown(with event: NSEvent) {
        // Directly check for Escape key and handle it first
        if event.keyCode == 53 { // Escape key
            processor?.window.close()
            return
        }
        
        // For other keys, let the processor handle them
        switch event.keyCode {
        case 36: // Enter key
            processor?.confirmClicked()
        case 49: // Spacebar
            processor?.toggleSelectedItem()
        case 125: // Down arrow
            processor?.selectNextItem()
        case 126: // Up arrow
            processor?.selectPreviousItem()
        default:
            super.keyDown(with: event)
        }
    }
    
    // Override this method to be the first responder when clicked
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if window?.firstResponder != self {
            self.window?.makeFirstResponder(self)
        }
    }
    
    // Override to make sure drawing is correct for transparency
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}


class KeyForwardingWindow: NSWindow {
    weak var keyDelegate: FileProcessor? // Delegate to forward keys to

    // Override keyDown to forward it
    override func keyDown(with event: NSEvent) {
        // Fast path for Escape key
        if event.keyCode == 53 { // Escape key
            self.close()
            return
        }
        
        // For other keys, try to delegate
        if let delegate = keyDelegate, delegate.handleKeyDown(with: event) {
            // If the delegate handled it, don't pass it up the chain
            return
        }
        
        // Otherwise, let the default handling occur
        super.keyDown(with: event)
    }

    // These are needed to ensure the window can become key even without text fields
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    // Override to ensure keyboard focus works properly
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        // When setting the first responder, ensure it's something that can handle keys
        if let responder = responder, responder.acceptsFirstResponder {
            return super.makeFirstResponder(responder)
        } else if let contentView = self.contentView, contentView.acceptsFirstResponder {
            // Fall back to content view if responder isn't valid
            return super.makeFirstResponder(contentView)
        }
        return super.makeFirstResponder(responder)
    }
}

// MARK: - FileItem (Represents a File or Directory)
class FileItem: NSObject {
    let path: String
    let isDirectory: Bool
    var children: [FileItem]?
    var isSelected: Bool = false {
        didSet {
            // Propagate selection change downwards for directories
            if isDirectory && oldValue != isSelected { // Only propagate if the state actually changed
                children?.forEach { $0.isSelected = isSelected }
            }
        }
    }

    var selectionState: NSControl.StateValue {
        if isDirectory {
            guard let children = children, !children.isEmpty else { return .off } // Empty dirs are off

            let selectedChildren = children.filter { $0.isSelected }
            let totalChildren = children.count

            if selectedChildren.count == totalChildren { return .on }
            if selectedChildren.count > 0 { return .mixed }
            return .off
        }
        return isSelected ? .on : .off
    }

    // Designated initializer
    init(path: String, isDirectory: Bool, processor: FileProcessor) {
        self.path = path
        self.isDirectory = isDirectory
        super.init()

        if !isDirectory {
            // Auto-select if it's an allowed file type
            self.isSelected = processor.shouldAutoSelectFile(path)
        }

        // Note: Children are loaded lazily or upon initialization if it's a directory.
        // The loadChildren call is now handled in the convenience initializer or after creation.
    }

    // Convenience initializer used during loading
    convenience init?(path: String, processor: FileProcessor) {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else {
             // print("Warning: Path does not exist: \(path)") // Too noisy
             return nil // Skip if path doesn't exist anymore (e.g., deleted)
        }

        let isDirectory = isDir.boolValue
        let filename = (path as NSString).lastPathComponent

        // Check against exclusion patterns BEFORE creating the item
        if processor.shouldExclude(filename: filename, fullPath: path, isDirectory: isDirectory) {
            // print("Excluding: \(path)") // Optional debug logging
            return nil // Exclude this item
        }

        self.init(path: path, isDirectory: isDirectory, processor: processor)

        // Load children immediately upon creation if it's a directory
        if isDirectory {
             self.loadChildren(processor: processor)
        }
    }


    func loadChildren(processor: FileProcessor) {
        guard isDirectory else { return }

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            children = contents
                .compactMap { childName -> FileItem? in
                    let fullPath = (path as NSString).appendingPathComponent(childName)
                    // Use the convenience initializer which handles exclusion checks and recursive loading
                    return FileItem(path: fullPath, processor: processor)
                }
                .filter { item -> Bool in
                    // Additional filtering: Skip binary files if they weren't already excluded
                    if !item.isDirectory && !processor.isTextFile(item.path) {
                        // print("Skipping binary file: \(item.path)") // Optional debug logging
                        return false
                    }
                    return true
                }
            children?.sort { $0.path.localizedStandardCompare($1.path) == .orderedAscending } // Natural sort order
        } catch {
            print("Error loading directory contents for \(path): \(error)")
            children = []
        }
    }
}


// MARK: - FileProcessor (Main Application Logic)
class FileProcessor: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    var outlineView: NSOutlineView!
    var textView: NSTextView!
    var rootItem: FileItem!
    var statusLabel: NSTextField! // Label for copy status

    // --- Configuration ---
    let defaultExtensions = ["swift", "py", "js", "java", "cpp", "h", "c", "rb", "go", "kt", "m", "mm", "ts", "tsx", "cs", "php", "html", "css", "scss", "json", "xml", "yaml", "yml", "md", "sh"]
    // Default exclusions using wildcard patterns
    let defaultExclusionPatterns = [".git", "node_modules", "__pycache__", ".venv", "venv", "build", "dist", ".DS_Store", "*.pyc", "*.o", "*.class", "*.exe", "*.dll", "*.so", "*.dylib", "*.dSYM", "*.app", "*.framework", "*.xcassets", "*.xcodeproj", "*.xcworkspace"]

    var allowedExtensions: Set<String>
    var exclusionPatterns: Set<String>
    var inclusionPatterns: Set<String> // Added for potential future use or overriding excludes

    override init() {
        // Initialize collections first
        var cmdExtensions: [String] = []
        var cmdExclusions: [String] = []
        var cmdInclusions: [String] = []

        let args = CommandLine.arguments
        for arg in args.dropFirst() {
            if arg.hasPrefix("--ext=") {
                let ext = String(arg.dropFirst("--ext=".count)).lowercased()
                if !ext.isEmpty { cmdExtensions.append(ext) }
            } else if arg.hasPrefix("--exclude=") {
                let pattern = String(arg.dropFirst("--exclude=".count))
                 if !pattern.isEmpty { cmdExclusions.append(pattern) }
            } else if arg.hasPrefix("--include=") {
                 let pattern = String(arg.dropFirst("--include=".count))
                 if !pattern.isEmpty { cmdInclusions.append(pattern) }
            }
        }

        // Use command line extensions if specified, otherwise use defaults
        allowedExtensions = Set(cmdExtensions.isEmpty ? defaultExtensions : cmdExtensions)
        // Combine default and command-line exclusions
        exclusionPatterns = Set(defaultExclusionPatterns).union(cmdExclusions)
        // Store inclusions
        inclusionPatterns = Set(cmdInclusions)

        super.init()
        
        // Set up the window BEFORE attempting to load data
        setupWindow()
        
        // IMPORTANT: Make sure we don't access data before it's loaded
        outlineView.dataSource = nil
        
        // Load data AFTER UI is set up
        loadCurrentDirectory()
    }
    
    func setupTextView() {
        textView = NSTextView()
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        
        // Add custom key handling for the text view
        class EscapeHandlingTextView: NSTextView {
            weak var processor: FileProcessor?
            
            override func keyDown(with event: NSEvent) {
                if event.keyCode == 53 { // Escape key
                    processor?.window.close()
                    return
                }
                super.keyDown(with: event)
            }
        }
        
        // Replace with our custom text view
        let customTextView = EscapeHandlingTextView(frame: .zero)
        customTextView.isEditable = false
        customTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        customTextView.drawsBackground = true
        customTextView.backgroundColor = NSColor.textBackgroundColor
        customTextView.textColor = NSColor.labelColor
        customTextView.isVerticallyResizable = true
        customTextView.isHorizontallyResizable = true
        customTextView.textContainer?.widthTracksTextView = true
        customTextView.processor = self
        
        // Use our custom text view instead
        textView = customTextView
    }

    // Determine if a file/directory should be excluded
    func shouldExclude(filename: String, fullPath: String, isDirectory: Bool) -> Bool {
        // 1. Check inclusions first: If it matches an include pattern, DON'T exclude it.
        // Check both filename and full path against inclusion patterns
        for pattern in inclusionPatterns {
            if wildCardMatch(pattern, filename) || wildCardMatch(pattern, fullPath) {
                // print("Including \(fullPath) due to pattern: \(pattern)") // Debugging
                return false // Force include
            }
        }

        // 2. Check exclusions: If it matches an exclude pattern, DO exclude it.
        // Check both filename and full path against exclusion patterns
        for pattern in exclusionPatterns {
            if wildCardMatch(pattern, filename) || wildCardMatch(pattern, fullPath) {
                // print("Excluding \(fullPath) due to pattern: \(pattern)") // Debugging
                return true // Exclude
            }
        }

        // 3. Default: Don't exclude
        return false
    }

    func toggleSelectedItem() {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0, let item = outlineView.item(atRow: selectedRow) as? FileItem {
            // Determine the new selection state based on the current state
            // If currently off or mixed, the new state is on (selected)
            // If currently on, the new state is off (not selected)
            let newStateSelected: Bool
            switch item.selectionState {
                case .off:
                    newStateSelected = true
                case .mixed:
                    newStateSelected = true
                case .on:
                    newStateSelected = false
                default: // Handle any unexpected future cases of NSControl.StateValue
                    newStateSelected = !item.isSelected // Fallback to simple toggle
            }

            // Update the model
            item.isSelected = newStateSelected

            // Reload the item to update its checkbox state
            outlineView.reloadItem(item)

            // If it's a directory, reload its children visually to update their checkboxes
            if item.isDirectory {
                outlineView.reloadItem(item, reloadChildren: true)
            }

            // Reload the parent item to update its mixed state if necessary
            if let parent = outlineView.parent(forItem: item) {
                outlineView.reloadItem(parent)
            } else {
                 // If the toggled item is a top-level item (child of the hidden root),
                 // reload the root item itself to potentially update its state (mixed/on/off)
                 outlineView.reloadItem(rootItem)
            }

            // Update the aggregated text view
            updateTextView()
        }
    }

    func selectNextItem() {
        let currentRow = outlineView.selectedRow
        // Use let as the variable is not mutated in this basic implementation
        let nextRow = currentRow + 1

        // Basic implementation: Select the next visible row index
        if nextRow < outlineView.numberOfRows {
            outlineView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
            outlineView.scrollRowToVisible(nextRow)
        }
    }

    func selectPreviousItem() {
        let currentRow = outlineView.selectedRow
         // Use let as the variable is not mutated in this basic implementation
        let previousRow = currentRow - 1

        // Basic implementation: Select the previous visible row index
        if previousRow >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: previousRow), byExtendingSelection: false)
            outlineView.scrollRowToVisible(previousRow)
        }
    }

    func shouldAutoSelectFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return allowedExtensions.contains(ext)
    }

    
    func setupWindow() {
        let rect = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        // Create window with appropriate style masks for transparency
        window = KeyForwardingWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window for transparency
        window.title = "File Processor"
        window.minSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        
        // Set window to appear on top of everything, including full-screen apps
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // This ensures window appears even when app doesn't have focus
        NSApp.setActivationPolicy(.accessory)
        
        // Create key monitor view as content view
        let keyMonitorView = KeyMonitorView()
        keyMonitorView.processor = self
        window.contentView = keyMonitorView
        
        // Assign the window as its own key delegate
        (window as? KeyForwardingWindow)?.keyDelegate = self
        
        // Visual Effect View - critical for transparency
        let visualEffectView = NSVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        keyMonitorView.addSubview(visualEffectView)
        
        // Split View - main content container
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        // Outline View (Left Side)
        let outlineScrollView = NSScrollView()
        outlineScrollView.hasVerticalScroller = true
        outlineScrollView.hasHorizontalScroller = true
        outlineScrollView.autohidesScrollers = true
        outlineScrollView.borderType = .noBorder
        outlineScrollView.drawsBackground = false
        outlineScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        outlineView = NSOutlineView()
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Files"))
        column.title = "Files"
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.allowsMultipleSelection = false
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.headerView = nil
        outlineView.rowHeight = 20
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.backgroundColor = .clear
        outlineView.sizeLastColumnToFit()
        
        outlineScrollView.documentView = outlineView
        
        // Text View (Right Side) - with escape key handling
        let textScrollView = NSScrollView()
        textScrollView.hasVerticalScroller = true
        textScrollView.hasHorizontalScroller = true
        textScrollView.autohidesScrollers = true
        textScrollView.borderType = .noBorder
        textScrollView.drawsBackground = true
        textScrollView.backgroundColor = NSColor.textBackgroundColor
        textScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create custom text view with escape key handling
        class EscapeHandlingTextView: NSTextView {
            weak var processor: FileProcessor?
            
            override func keyDown(with event: NSEvent) {
                if event.keyCode == 53 { // Escape key
                    processor?.window.close()
                    return
                }
                super.keyDown(with: event)
            }
        }
        
        // Create and configure the custom text view
        let customTextView = EscapeHandlingTextView(frame: .zero)
        customTextView.isEditable = false
        customTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        customTextView.drawsBackground = true
        customTextView.backgroundColor = NSColor.textBackgroundColor
        customTextView.textColor = NSColor.labelColor
        customTextView.isVerticallyResizable = true
        customTextView.isHorizontallyResizable = true
        customTextView.textContainer?.widthTracksTextView = true
        customTextView.processor = self
        
        // Use our custom text view
        textView = customTextView
        
        textScrollView.documentView = textView
        
        // Add views to Split View
        splitView.addArrangedSubview(outlineScrollView)
        splitView.addArrangedSubview(textScrollView)
        
        // Bottom Controls
        let confirmButton = NSButton(title: "Confirm", target: self, action: #selector(confirmClicked))
        confirmButton.bezelStyle = .rounded
        confirmButton.setButtonType(.momentaryPushIn)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.alignment = .right
        
        let bottomControlsStack = NSStackView(views: [statusLabel, confirmButton])
        bottomControlsStack.orientation = .horizontal
        bottomControlsStack.spacing = 8
        bottomControlsStack.distribution = .fill
        bottomControlsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Main Stack View - uses all available space
        let mainStackView = NSStackView(views: [splitView, bottomControlsStack])
        mainStackView.orientation = .vertical
        mainStackView.spacing = 5
        mainStackView.distribution = .fill
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add mainStackView to visualEffectView
        visualEffectView.addSubview(mainStackView)
        
        // CONSTRAINTS
        NSLayoutConstraint.activate([
            // Visual Effect View fills entire window
            visualEffectView.topAnchor.constraint(equalTo: keyMonitorView.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: keyMonitorView.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: keyMonitorView.trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: keyMonitorView.bottomAnchor),
            
            // Main Stack View fills visual effect view with minimal margins
            mainStackView.topAnchor.constraint(equalTo: visualEffectView.safeAreaLayoutGuide.topAnchor, constant: 4),
            mainStackView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 4),
            mainStackView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -4),
            mainStackView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -4),
            
            // Force split view to fill width of its container
            splitView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
            
            // Force split view to expand in height
            splitView.heightAnchor.constraint(equalTo: mainStackView.heightAnchor, constant: -30),
            
            // Minimum widths for scroll views
            outlineScrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            textScrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            
            // Fixed height for button controls
            bottomControlsStack.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Set initial split view position
        DispatchQueue.main.async {
            let totalWidth = self.window.frame.width - 8
            let position = totalWidth / 3
            splitView.setPosition(position, ofDividerAt: 0)
        }
        
        // Ensure the window appears on top and is key/visible
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(keyMonitorView)
        window.center()
        
        // Initialize text view content
        DispatchQueue.main.async {
            self.updateTextView()
        }
    }

    func loadCurrentDirectory() {
        let currentPath = FileManager.default.currentDirectoryPath
        
        // --- Synchronous Initialization Attempt ---
        // Attempt to create the root item with silent error handling
        do {
            // Create the root item
            if let validRoot = FileItem(path: currentPath, processor: self) {
                self.rootItem = validRoot
            } else {
                // Failable initializer failed - create a backup silently
                var isDirFallback: ObjCBool = false
                let existsFallback = FileManager.default.fileExists(atPath: currentPath, isDirectory: &isDirFallback)
                
                if existsFallback {
                    self.rootItem = FileItem(path: currentPath, isDirectory: isDirFallback.boolValue, processor: self)
                    if self.rootItem.isDirectory {
                        self.rootItem.loadChildren(processor: self)
                    }
                } else {
                    // Path doesn't exist - create dummy
                    self.rootItem = FileItem(path: "Error", isDirectory: true, processor: self)
                    self.rootItem.children = []
                }
            }
        } catch {
            // Create emergency fallback silently
            self.rootItem = FileItem(path: "Error", isDirectory: true, processor: self)
            self.rootItem.children = []
        }
        
        // Final safety check
        if self.rootItem == nil {
            self.rootItem = FileItem(path: "Error", isDirectory: true, processor: self)
            self.rootItem.children = []
        }

        // --- Asynchronous UI Updates ---
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // NOW set the data source, AFTER we have a valid rootItem
            self.outlineView.dataSource = self
            
            // Now it's safe to reload
            self.outlineView.reloadData()
            self.outlineView.expandItem(self.rootItem)

            // Select first actual child item
            if self.outlineView.numberOfRows > 1 {
                self.outlineView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
                self.outlineView.scrollRowToVisible(1)
            } else if self.outlineView.numberOfRows > 0 {
                self.outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                self.outlineView.scrollRowToVisible(0)
            }

            self.updateTextView()

            // Ensure key monitor has focus
            if let keyMonitor = self.window.contentView as? KeyMonitorView {
                _ = self.window.makeFirstResponder(keyMonitor)
            }
        }
    }

    @objc func confirmClicked() {
        let outputString = textView.string
        let charCount = outputString.count
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(outputString, forType: .string)
        
        // Print character count message (only output of the program)
        print("\(charCount) characters copied to clipboard")
        
        // Terminate immediately without delay
        NSApplication.shared.terminate(nil)
    }

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Silently handle nil root item
        guard rootItem != nil else {
            return 0
        }
        
        // If item is nil, we are asking for the number of root items.
        if item == nil {
            return 1 // We always have one root item conceptually
        }

        // Otherwise, return the number of children of the given FileItem.
        guard let fileItem = item as? FileItem else {
            return 0
        }
        
        return fileItem.children?.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Silently handle nil root item
        guard let root = rootItem else {
            // Return a temporary dummy item to prevent the crash
            let dummy = FileItem(path: "Error", isDirectory: true, processor: self)
            dummy.children = []
            return dummy
        }
        
        // If item is nil, return the root item.
        if item == nil {
            return root
        }

        // Otherwise, return the specific child of the given FileItem.
        guard let fileItem = item as? FileItem,
              let children = fileItem.children,
              index < children.count else {
            // Return a dummy item to prevent crash
            let dummy = FileItem(path: "Error", isDirectory: false, processor: self)
            return dummy
        }
        
        return children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // Silently handle unexpected cases
        guard rootItem != nil else { return false }
        guard let fileItem = item as? FileItem else { return false }
        
        // Only directories with children are expandable visually
        return fileItem.isDirectory && (fileItem.children?.count ?? 0) > 0
    }

    // MARK: - NSOutlineViewDelegate

     func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let fileItem = item as? FileItem else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("FileCell")
        var view = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

        var checkbox: NSButton!
        var label: NSTextField!

        if view == nil {
            view = NSTableCellView()
            view?.identifier = identifier

            checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxClicked(_:)))
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            checkbox.allowsMixedState = true // Important for directory state
            // Store row index in tag (simple approach) - Tag needs to be updated if rows reorder!
            // A better approach is to get the item from the cell's superview in the action.
            // Let's remove the tag and rely on the superview method.

            label = NSTextField(labelWithString: "")
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            label.lineBreakMode = .byTruncatingTail // Prevent long names overflowing

            view?.addSubview(checkbox)
            view?.addSubview(label)
            view?.textField = label // Associate label for default text field behavior

            // Optional: Add an image view for icons
            let imageView = NSImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view?.addSubview(imageView)
            view?.imageView = imageView // Associate image view

            NSLayoutConstraint.activate([
                // Icon
                imageView.leadingAnchor.constraint(equalTo: view!.leadingAnchor, constant: 2),
                imageView.centerYAnchor.constraint(equalTo: view!.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 16), // Icon size
                imageView.heightAnchor.constraint(equalToConstant: 16), // Icon size

                // Checkbox positioned after icon
                checkbox.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 2), // Space after icon
                checkbox.centerYAnchor.constraint(equalTo: view!.centerYAnchor),
                checkbox.widthAnchor.constraint(equalToConstant: 18), // Standard checkbox size

                // Label positioned after checkbox
                label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 4), // Space between checkbox and text
                label.centerYAnchor.constraint(equalTo: view!.centerYAnchor),
                // Let the label expand towards the trailing edge, respecting the column's width
                label.trailingAnchor.constraint(lessThanOrEqualTo: view!.trailingAnchor, constant: -2)
            ])
        } else {
            // Reuse existing checkbox and label
            checkbox = view?.subviews.first(where: { $0 is NSButton }) as? NSButton
            label = view?.textField
            // No need to update tag if we get item from superview
        }

        // Configure the cell content
        label.stringValue = (fileItem.path as NSString).lastPathComponent
        checkbox.state = fileItem.selectionState

        // Set icon based on type
        // Use NSWorkspace to get the standard icon
        let icon = NSWorkspace.shared.icon(forFile: fileItem.path)
        icon.size = NSSize(width: 16, height: 16)
        view?.imageView?.image = icon


        return view
    }

     // Optional: Adjust row height if needed
     func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
         return 20 // Consistent row height
     }

     // Handle selection changes to update text view
     func outlineViewSelectionDidChange(_ notification: Notification) {
         // We might want to show the content of the *selected* file,
         // but the primary purpose here is collecting *checked* files.
         // Let's keep the text view showing the aggregate of checked files.
         // If you wanted to preview the selected file, you'd add logic here.
         // updateTextView() // Re-running this on selection change might be too slow/confusing
     }


    @objc func checkboxClicked(_ sender: NSButton) {
        // Find the item associated with the clicked checkbox by getting the row from the cell view
        guard let cellView = sender.superview as? NSTableCellView else {
            print("Error: Checkbox superview is not NSTableCellView")
            return
        }
        let row = outlineView.row(for: cellView)
        guard row >= 0,
              let item = outlineView.item(atRow: row) as? FileItem else {
            print("Error: Could not find item for checkbox at row \(row)")
            return
        }

        // Determine the new selection state based on the current state
        // If currently off or mixed, the new state is on (selected)
        // If currently on, the new state is off (not selected)
        let newStateSelected: Bool
        switch item.selectionState {
            case .off:
                newStateSelected = true
            case .mixed:
                newStateSelected = true
            case .on:
                newStateSelected = false
            default: // Handle any unexpected future cases of NSControl.StateValue
                 // Fallback: Toggle the underlying isSelected state
                newStateSelected = !item.isSelected
                 print("Warning: Encountered unexpected NSControl.StateValue: \(item.selectionState)")
        }

        // Update the model
        item.isSelected = newStateSelected

        // Reload data to reflect changes visually
        // Reload the specific item first for immediate checkbox feedback
        outlineView.reloadItem(item)

        // If it's a directory, reload its children visually to update their checkboxes
        if item.isDirectory {
             outlineView.reloadItem(item, reloadChildren: true)
        }
         // Reload parent to update its mixed state if necessary
         if let parent = outlineView.parent(forItem: item) {
             outlineView.reloadItem(parent)
         } else {
             // If the toggled item is a top-level item (child of the hidden root),
             // reload the root item itself to potentially update its state (mixed/on/off)
             outlineView.reloadItem(rootItem)
         }


        // Update the aggregated text view
        updateTextView()
    }
    
    func handleKeyDown(with event: NSEvent) -> Bool {
        switch event.keyCode {
        case 36: // Enter key
            confirmClicked()
            return true // Indicate handled
        case 53: // Escape key
            window.close()
            return true // Indicate handled
        case 49: // Spacebar
            toggleSelectedItem()
            return true // Indicate handled
        case 125: // Down arrow
            selectNextItem()
            return true // Indicate handled
        case 126: // Up arrow
            selectPreviousItem()
            return true // Indicate handled
        default:
            return false // Indicate not handled by this method
        }
    }


    func updateTextView() {
        var output = ""
        let currentPath = FileManager.default.currentDirectoryPath
        var fileCount = 0

        // Recursive function to process items
        func processItem(_ item: FileItem) {
            // Base case: Process selected files
            if !item.isDirectory && item.isSelected {
                do {
                    // Optimization: Only read files up to a certain size? Maybe not necessary yet.
                    let content = try String(contentsOfFile: item.path, encoding: .utf8)
                    let commentStyle = getCommentStyle(forPath: item.path)
                    // Make path relative to the starting directory
                    let relativePath = item.path.replacingOccurrences(of: currentPath + "/", with: "")

                    output += "\(commentStyle) File: \(relativePath)\n"
                    output += "\(commentStyle) === Start Content ===\n"
                    output += content
                    output += "\n\(commentStyle) === End Content ===\n\n"
                    fileCount += 1
                } catch {
                    // Handle read errors silently - no debug prints
                    let relativePath = item.path.replacingOccurrences(of: currentPath + "/", with: "")
                    output += "# Error reading file: \(relativePath)\n"
                }
            }

            // Recursive step: Process children if it's a directory
            if item.isDirectory {
                // Sort children before processing to ensure consistent output order
                item.children?.sorted(by: { $0.path.localizedStandardCompare($1.path) == .orderedAscending }).forEach { processItem($0) }
            }
        }

        // Start processing from the actual root item's children, or the root item if it's a file itself
        // Process the root item itself if it's selected (e.g., if the tool is run on a single file)
        if !rootItem.isDirectory && rootItem.isSelected {
             processItem(rootItem)
        } else if rootItem.isDirectory {
             // Process children of the root if it's a directory
             rootItem.children?.sorted(by: { $0.path.localizedStandardCompare($1.path) == .orderedAscending }).forEach { processItem($0) }
        }

        // Update the text view on the main thread
        DispatchQueue.main.async { [weak self] in
             self?.textView.string = output
             
             // Update status label with character and file count (no debug prints)
             let charCount = output.count
             self?.statusLabel.stringValue = "\(charCount) characters in preview (\(fileCount) files)"
        }
    }

    func getCommentStyle(forPath path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()

        // Expanded list of comment styles
        switch ext {
            case "swift", "go", "java", "js", "ts", "tsx", "cpp", "c", "h", "cs", "kt", "m", "mm", "scala", "rs", "dart":
                return "//"
            case "py", "rb", "pl", "sh", "bash", "yml", "yaml", "conf", "toml", "r":
                return "#"
            case "html", "xml", "vue", "svelte", "md", "txt": // Use # for single-line comments in these contexts
                return "#"
            case "css", "scss", "less": // Use // for single-line comments in these contexts
                return "//"
            case "sql", "lua":
                return "--"
            case "bat", "cmd":
                return "REM"
            case "vb", "vbs":
                return "'"
            default: // Default fallback
                return "#"
        }
    }

    // Improved text file detection
    func isTextFile(_ path: String) -> Bool {
        // 1. Check common known text extensions (including allowed ones)
        let knownTextExtensions = allowedExtensions.union(["txt", "md", "json", "xml", "yaml", "yml", "conf", "ini", "csv", "log", "plist", "strings", "markdown", "gitignore", "editorconfig", "gitattributes", "gitmodules", "npmignore", "dockerfile", "gradle", "properties", "rst", "tex", "latex", "bib", "tsv"])
        let ext = (path as NSString).pathExtension.lowercased()
        if knownTextExtensions.contains(ext) {
            return true
        }

        // 2. Check common known binary extensions
        let knownBinaryExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "ico", "icns",
                                                 "mp3", "wav", "aac", "m4a", "ogg", "flac",
                                                 "mp4", "mov", "avi", "mkv", "wmv", "flv",
                                                 "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
                                                 "zip", "gz", "tar", "rar", "7z", "bz2", "dmg", "iso",
                                                 "app", "exe", "dll", "so", "dylib", "o", "a", "lib",
                                                 "class", "jar", "pyc", "pyd", "bin", "dat", "data",
                                                 "db", "sqlite", "mdb", "accdb", "ttf", "otf", "woff", "woff2",
                                                 "eot", "psd", "ai", "eps", "svg", // SVG can be text, but often treated as binary asset
                                                 "dylib", "bundle", "framework"]

        if knownBinaryExtensions.contains(ext) {
            return false
        }

        // 3. Check file content for null bytes (heuristic)
        // Optimization: Only read the first few KB
        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            return false // Cannot open file
        }
        defer { fileHandle.closeFile() }

        // Read up to 4KB
        guard let data = try? fileHandle.read(upToCount: 4096) else {
             return false // Error reading
        }

        if data.isEmpty {
            return true // Empty file is considered text
        }

        // Check for null byte
        if data.contains(0) {
            return false // Contains null byte, likely binary
        }

        // 4. Check for non-UTF8 sequences (another heuristic)
        // If the beginning of the file isn't valid UTF-8, it's less likely to be a text file we want.
        // This might filter out files with other encodings, but UTF-8 is the most common for code.
        if String(data: data, encoding: .utf8) == nil {
             // It's not UTF-8. Could it be another common text encoding?
             // Try Latin-1 (ISO-8859-1) or Windows-1252
             if String(data: data, encoding: .isoLatin1) != nil || String(data: data, encoding: .windowsCP1252) != nil {
                 // If it decodes as Latin-1 or Windows-1252, it's likely text.
                 return true
             }
            return false // Doesn't seem to be a common text encoding
        }

        // If it passes all checks, assume it's text
        return true
    }

    // MARK: - NSWindowDelegate
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(nil) // Ensure app quits when window closes
    }
}


// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var processor: FileProcessor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show usage if --help is specified
        if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
            print("""
            Usage: \(CommandLine.arguments[0]) [options]

            Options:
              --ext=<extension>    Specify file extensions to auto-select (default: common code files).
                                   Can be used multiple times (e.g., --ext=py --ext=js).
              --exclude=<pattern>  Specify a file/directory name pattern to exclude (e.g., --exclude=*.log).
                                   Uses wildcard matching (*, ?). Applied after default excludes.
                                   Can be used multiple times. Matches filename OR full path.
              --include=<pattern>  Specify a file/directory name pattern to force include, overriding default excludes.
                                   (e.g., --include=build/important.txt). Uses wildcard matching.
                                   Can be used multiple times. Matches filename OR full path.
              --help, -h           Show this help message and exit.

            Default Exclusions: \(FileProcessor().defaultExclusionPatterns.joined(separator: ", "))
            Default Extensions: \(FileProcessor().defaultExtensions.joined(separator: ", "))

            Description:
              Scans the current directory, allowing selection of files. Copies the content
              of selected files, prefixed with their relative paths, to the clipboard upon 'Confirm'.

            Keyboard Shortcuts:
              Enter: Confirm and copy to clipboard
              Esc:   Close the window
              Space: Toggle selection of the highlighted item
              Up/Down Arrow: Navigate the file list
            """)
            NSApplication.shared.terminate(nil)
            return
        }
        
        // Configure the application as an accessory app for proper window behavior
        NSApp.setActivationPolicy(.accessory)
        
        // Create the processor
        processor = FileProcessor()

        // Ensure UI setup happens on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Activate app and bring window to front
            NSApp.activate(ignoringOtherApps: true)
            
            // Make sure window is ordered front regardless of other apps
            self.processor.window.orderFrontRegardless()
            
            // Set focus to the key monitor view
            if let keyMonitorView = self.processor.window.contentView as? KeyMonitorView {
                self.processor.window.makeFirstResponder(keyMonitorView)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Handle application activation - ensure window stays visible
    func applicationDidBecomeActive(_ notification: Notification) {
        processor?.window.orderFrontRegardless()
    }
    
    // Handle losing focus - keep window visible
    func applicationDidResignActive(_ notification: Notification) {
        // This ensures the window stays visible even when the app loses focus
        processor?.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        processor?.window.orderFrontRegardless()
    }
}

// MARK: - Application Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Ensure the app runs as a regular foreground application
NSApp.setActivationPolicy(.regular)
// Activate immediately on launch
// app.activate(ignoringOtherApps: true) // Moved to applicationDidFinishLaunching for better timing
app.run()
