import Cocoa


class KeyMonitorView: NSView {
    weak var processor: FileProcessor?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36: // Enter key
            processor?.confirmClicked()
        case 53: // Escape key
            processor?.window.close()
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
}


class FileProcessor: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, NSWindowDelegate {
    var window: NSWindow!
    var outlineView: NSOutlineView!
    var textView: NSTextView!
    var rootItem: FileItem!

    // Default extensions if none specified
    let defaultExtensions = ["swift", "py", "js", "java", "cpp", "h", "c", "rb", "go", "kt"]
    // Extensions specified via command line
    var allowedExtensions: [String]

    override init() {
       // Parse command line arguments for extensions
       let args = CommandLine.arguments
       var cmdExtensions: [String] = []

       for (_, arg) in args.enumerated() {
           if arg.hasPrefix("--ext=") {
               let ext = arg.replacingOccurrences(of: "--ext=", with: "")
               cmdExtensions.append(ext.lowercased())
           }
       }

       // Use command line extensions if specified, otherwise use defaults
       allowedExtensions = cmdExtensions.isEmpty ? defaultExtensions : cmdExtensions

       super.init()
       setupWindow()
       loadCurrentDirectory()
    }

    func toggleSelectedItem() {
        let selectedRow = outlineView.selectedRow
        if selectedRow >= 0,
           let item = outlineView.item(atRow: selectedRow) as? FileItem {
            item.isSelected = !item.isSelected
            outlineView.reloadData()
            updateTextView()
        }
    }

    func selectNextItem() {
        let currentRow = outlineView.selectedRow
        let nextRow = currentRow + 1
        if nextRow < outlineView.numberOfRows {
            outlineView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
            outlineView.scrollRowToVisible(nextRow)
        }
    }

    func selectPreviousItem() {
        let currentRow = outlineView.selectedRow
        let previousRow = currentRow - 1
        if previousRow >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: previousRow), byExtendingSelection: false)
            outlineView.scrollRowToVisible(previousRow)
        }
    }

    // Update FileItem initialization to pre-select allowed files
    func shouldAutoSelectFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return allowedExtensions.contains(ext)
    }

    class FileItem: NSObject {
        let path: String
        let isDirectory: Bool
        var children: [FileItem]?
        var isSelected: Bool = false {
            didSet {
                if isDirectory {
                    children?.forEach { $0.isSelected = isSelected }
                }
            }
        }

        var selectionState: NSControl.StateValue {
            if isDirectory {
                let selectedChildren = children?.filter { $0.isSelected } ?? []
                let totalChildren = children?.count ?? 0

                if totalChildren == 0 { return .off }
                if selectedChildren.count == totalChildren { return .on }
                if selectedChildren.count > 0 { return .mixed }
                return .off
            }
            return isSelected ? .on : .off
        }

        init(path: String, processor: FileProcessor) {
            self.path = path
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            self.isDirectory = isDir.boolValue
            super.init()

            // Skip hidden files/folders
            if (path as NSString).lastPathComponent.hasPrefix(".") {
                return
            }

            if !isDirectory {
                // Auto-select if it's an allowed file
                self.isSelected = processor.shouldAutoSelectFile(path)
            }

            if isDirectory {
                self.loadChildren(processor: processor)
            }
        }

        func loadChildren(processor: FileProcessor) {
            guard isDirectory else { return }

            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: path)
                children = contents
                    .filter { !$0.hasPrefix(".") } // Skip hidden files
                    .compactMap { childPath -> FileItem? in
                        let fullPath = (path as NSString).appendingPathComponent(childPath)  // Use childPath instead of $0
                        let item = FileItem(path: fullPath, processor: processor)

                        // Skip binary files
                        if !item.isDirectory && !processor.isTextFile(fullPath) {
                            return nil
                        }

                        return item
                    }
                children?.sort { $0.path < $1.path }
            } catch {
                print("Error loading directory contents: \(error)")
                children = []
            }
        }
    }

    func setupWindow() {
        // Reduce window dimensions
        let rect = NSRect(x: 0, y: 0, width: 480, height: 320)  // Smaller default size
        window = NSWindow(contentRect: rect,
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered,
                         defer: false)
        window.title = "File Processor"
        window.minSize = NSSize(width: 400, height: 250)  // Smaller minimum size
        window.collectionBehavior = []
        window.isReleasedWhenClosed = false
        window.delegate = self

        let keyMonitor = KeyMonitorView()
        keyMonitor.processor = self
        keyMonitor.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = keyMonitor

        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin

        // Reduce scroll view width
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 160, height: rect.height))  // Narrower width
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        outlineView = NSOutlineView(frame: scrollView.bounds)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Files"))
        column.title = "Files"
        column.width = 140  // Narrower column width
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.allowsMultipleSelection = true
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.headerView = nil
        outlineView.rowHeight = 18  // Slightly smaller row height

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        let textScrollView = NSScrollView(frame: NSRect(x: 160, y: 0, width: rect.width - 160, height: rect.height))
        textScrollView.hasVerticalScroller = true
        textScrollView.hasHorizontalScroller = true
        textScrollView.autohidesScrollers = true
        textScrollView.borderType = .noBorder

        textView = NSTextView(frame: textScrollView.bounds)
        textView.isEditable = false
        textView.autoresizingMask = [.width, .height]
        textView.font = NSFont.systemFont(ofSize: 11)
        textScrollView.documentView = textView

        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(textScrollView)
        splitView.setPosition(160, ofDividerAt: 0)  // Set smaller initial divider position

        let confirmButton = NSButton(title: "Confirm", target: self, action: #selector(confirmClicked))
        confirmButton.bezelStyle = .rounded
        confirmButton.setButtonType(.momentaryPushIn)

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 2  // Reduced spacing
        stackView.edgeInsets = NSEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)  // Smaller margins
        stackView.addArrangedSubview(splitView)
        stackView.addArrangedSubview(confirmButton)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        splitView.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)

        keyMonitor.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: keyMonitor.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: keyMonitor.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: keyMonitor.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: keyMonitor.bottomAnchor),

            splitView.topAnchor.constraint(equalTo: stackView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            splitView.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.95),

            confirmButton.heightAnchor.constraint(equalToConstant: 20)  // Smaller button height
        ])

        window.setFrame(rect, display: true)
        window.center()
    }




    func loadCurrentDirectory() {
        let currentPath = FileManager.default.currentDirectoryPath
        rootItem = FileItem(path: currentPath, processor: self)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.outlineView.reloadData()
            self.outlineView.expandItem(nil, expandChildren: true)

            // Select the first item
            if self.outlineView.numberOfRows > 0 {
                self.outlineView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }

            // Make sure pre-selected items are reflected in the UI
            for row in 0..<self.outlineView.numberOfRows {
                if let item = self.outlineView.item(atRow: row) as? FileItem,
                   !item.isDirectory && self.shouldAutoSelectFile(item.path) {
                    item.isSelected = true
                }
            }

            self.outlineView.reloadData()
            self.updateTextView()

            // Ensure key monitor has focus
            if let keyMonitor = self.window.contentView as? KeyMonitorView {
                self.window.makeFirstResponder(keyMonitor)
            }
        }
    }

    @objc func confirmClicked() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textView.string, forType: .string)
        NSApplication.shared.terminate(nil)
    }

    // MARK: - NSOutlineViewDataSource

    // MARK: - NSOutlineViewDataSource

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1
        }
        guard let fileItem = item as? FileItem else { return 0 }
        return fileItem.children?.count ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            guard let root = rootItem else { return FileItem(path: "", processor: self) }
            return root
        }
        guard let fileItem = item as? FileItem,
              let children = fileItem.children,
              index < children.count else { return FileItem(path: "", processor: self) }
        return children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let fileItem = item as? FileItem else { return false }
        return fileItem.isDirectory && (fileItem.children?.count ?? 0) > 0
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let fileItem = item as? FileItem else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("Cell")
        var cell = outlineView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier

            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxClicked(_:)))
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            checkbox.allowsMixedState = true

            let label = NSTextField(labelWithString: "")
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isEditable = false
            label.isBordered = false
            label.drawsBackground = false
            label.alignment = .left  // Ensure left alignment
            label.lineBreakMode = .byTruncatingTail

            cell?.addSubview(checkbox)
            cell?.addSubview(label)

            NSLayoutConstraint.activate([
                // Position checkbox with minimal left padding
                checkbox.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 2),
                checkbox.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                checkbox.widthAnchor.constraint(equalToConstant: 20),  // Fixed width for checkbox

                // Position label immediately after checkbox with minimal spacing
                label.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 2),
                label.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -2)
            ])
        }

        if let checkbox = cell?.subviews.first as? NSButton {
            checkbox.state = fileItem.selectionState
        }

        if let label = cell?.subviews.last as? NSTextField {
            label.stringValue = (fileItem.path as NSString).lastPathComponent
        }

        return cell
    }

    @objc func checkboxClicked(_ sender: NSButton) {
        guard let cell = sender.superview as? NSTableCellView else { return }
        let row = outlineView.row(for: cell)
        guard row >= 0,
              let item = outlineView.item(atRow: row) as? FileItem else { return }

        // Simply toggle the selection state
        item.isSelected = !item.isSelected

        outlineView.reloadData()
        updateTextView()
    }



    func updateTextView() {
        var output = ""
        let currentPath = FileManager.default.currentDirectoryPath

        func processItem(_ item: FileItem) {
            if item.isSelected && !item.isDirectory {
                do {
                    let content = try String(contentsOfFile: item.path, encoding: .utf8)
                    let commentStyle = getCommentStyle(forPath: item.path)
                    // Convert absolute path to relative path
                    let relativePath = item.path.replacingOccurrences(of: currentPath + "/", with: "")
                    output += "\(commentStyle) \(relativePath)\n"
                    output += content
                    output += "\n\n"
                } catch {
                    output += "Error reading \(item.path): \(error)\n"
                }
            }

            item.children?.forEach { processItem($0) }
        }

        processItem(rootItem)
        textView.string = output
    }


    func getCommentStyle(forPath path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()

        let slashCommentExts = ["go", "java", "js", "cpp", "c", "h", "cs", "kt", "swift"]
        let hashCommentExts = ["py", "rb", "pl", "sh", "bash", "yml", "yaml", "conf", "txt", "md"]

        if slashCommentExts.contains(ext) {
            return "//"
        }
        if hashCommentExts.contains(ext) {
            return "#"
        }
        return "//"
    }

    func isTextFile(_ path: String) -> Bool {
        let textExtensions = Set(allowedExtensions + ["txt", "md", "json", "xml", "yaml", "yml", "conf", "ini"])
        let ext = (path as NSString).pathExtension.lowercased()

        // If it has a known text extension, consider it text
        if textExtensions.contains(ext) {
            return true
        }

        // For files without extension or unknown extensions, check content
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped) else {
            return false
        }

        // Check first 8KB of the file
        let size = min(8192, data.count)
        var bytes = [UInt8](repeating: 0, count: size)
        data.copyBytes(to: &bytes, count: size)

        // Check for null bytes (common in binary files)
        for byte in bytes {
            if byte == 0 {
                return false
            }
        }

        return true
    }

}



// extension FileProcessor: NSWindowDelegate {
//     func windowWillClose(_ notification: Notification) {
//         NSApplication.shared.terminate(nil)
//     }
// }
class AppDelegate: NSObject, NSApplicationDelegate {
    var processor: FileProcessor!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show usage if --help is specified
        if CommandLine.arguments.contains("--help") {
            print("Usage: \(CommandLine.arguments[0]) [--ext=extension] ...")
            print("Examples:")
            print("  \(CommandLine.arguments[0]) --ext=py              # Select Python files")
            print("  \(CommandLine.arguments[0]) --ext=py --ext=swift  # Select Python and Swift files")
            NSApplication.shared.terminate(nil)
            return
        }

        processor = FileProcessor()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.processor.window.makeKeyAndOrderFront(nil)
            self.processor.window.orderFrontRegardless()

            if let keyMonitor = self.processor.window.contentView as? KeyMonitorView {
                self.processor.window.makeFirstResponder(keyMonitor)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Start the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
NSApp.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
