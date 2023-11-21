package main

import (
    "bytes"
    "flag"
    "fmt"
    "io/ioutil"
    "os"
    "path/filepath"
    "strings"
)

// Global flags for file extensions and excluded directories
var (
    includeExts    string
    excludeDirs    string
    allowedExts    map[string]bool
    excludedDirs   map[string]bool
)

// isBinary checks if the content appears to be binary
func isBinary(content []byte) bool {
    // Check for null bytes and other common binary patterns
    if bytes.IndexByte(content, 0) != -1 {
        return true
    }

    // Check first 512 bytes for binary content
    size := len(content)
    if size > 512 {
        size = 512
    }

    for i := 0; i < size; i++ {
        if content[i] < 32 && content[i] != '\n' && content[i] != '\r' && content[i] != '\t' {
            return true
        }
    }
    return false
}

// getCommentStyle returns the appropriate comment style based on file extension
func getCommentStyle(filename string) string {
    ext := strings.ToLower(filepath.Ext(filename))
    
    // Files that use // comments
    slashCommentExts := map[string]bool{
        ".go":   true,
        ".java": true,
        ".js":   true,
        ".cpp":  true,
        ".c":    true,
        ".h":    true,
        ".cs":   true,
        ".kt":   true,
        ".swift":true,
    }

    // Files that use # comments
    hashCommentExts := map[string]bool{
        ".py":     true,
        ".rb":     true,
        ".pl":     true,
        ".sh":     true,
        ".bash":   true,
        ".yml":    true,
        ".yaml":   true,
        ".conf":   true,
        ".txt":    true,
        ".md":     true,
        "":        true, // Files with no extension
    }

    if slashCommentExts[ext] {
        return "//"
    }
    if hashCommentExts[ext] {
        return "#"
    }
    return "//" // Default to // for unknown extensions
}

func processPath(path string) error {
    fileInfo, err := os.Stat(path)
    if err != nil {
        return fmt.Errorf("error accessing path %s: %v", path, err)
    }

    if fileInfo.IsDir() {
        return printFilesRecursively(path)
    } else {
        return processFile(path)
    }
}

func shouldProcessFile(path string) bool {
    // Check if file extension is in allowed list
    if len(allowedExts) > 0 {
        ext := strings.ToLower(filepath.Ext(path))
        if !allowedExts[ext] {
            return false
        }
    }

    // Check if file is in excluded directory
    if len(excludedDirs) > 0 {
        dir := filepath.Dir(path)
        for excludeDir := range excludedDirs {
            if strings.Contains(dir, excludeDir) {
                return false
            }
        }
    }

    return true
}

func processFile(path string) error {
    if !shouldProcessFile(path) {
        return nil
    }

    contents, err := ioutil.ReadFile(path)
    if err != nil {
        return fmt.Errorf("could not read file %s: %v", path, err)
    }

    // Skip binary files
    if isBinary(contents) {
        fmt.Printf("Skipping binary file: %s\n", path)
        return nil
    }

    // Get appropriate comment style
    commentStyle := getCommentStyle(path)

    // Print file path with appropriate comment style and contents
    fmt.Printf("%s %s\n", commentStyle, path)
    fmt.Println(string(contents))
    fmt.Println() // Add a newline for separation between files

    return nil
}

func printFilesRecursively(directory string) error {
    return filepath.Walk(directory, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return fmt.Errorf("error accessing path %s: %v", path, err)
        }

        // Skip directories in the walk
        if info.IsDir() {
            return nil
        }

        // Skip very large files (optional, adjust size as needed)
        if info.Size() > 10*1024*1024 { // 10MB limit
            fmt.Printf("Skipping large file %s (size: %d bytes)\n", path, info.Size())
            return nil
        }

        return processFile(path)
    })
}

// parseCommaSeparatedList converts a comma-separated string into a map
func parseCommaSeparatedList(input string) map[string]bool {
    result := make(map[string]bool)
    if input == "" {
        return result
    }
    
    items := strings.Split(input, ",")
    for _, item := range items {
        item = strings.TrimSpace(item)
        if item != "" {
            // For extensions, ensure they start with a dot
            if !strings.HasPrefix(item, ".") && strings.Contains(includeExts, item) {
                item = "." + item
            }
            result[item] = true
        }
    }
    return result
}

func main() {
    // Set up command-line argument parsing
    flag.StringVar(&includeExts, "ext", "", "Comma-separated list of file extensions to include (e.g., 'go,py,js')")
    flag.StringVar(&excludeDirs, "exclude-dir", "", "Comma-separated list of directories to exclude")
    
    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, "Usage: %s [options] [paths...]\n", os.Args[0])
        fmt.Fprintf(os.Stderr, "Recursively print files and their contents from specified paths.\n")
        fmt.Fprintf(os.Stderr, "Paths can be files or directories.\n\n")
        fmt.Fprintf(os.Stderr, "Options:\n")
        flag.PrintDefaults()
    }

    flag.Parse()

    // Parse extensions and excluded directories
    allowedExts = parseCommaSeparatedList(includeExts)
    excludedDirs = parseCommaSeparatedList(excludeDirs)

    // Check if at least one path is provided
    if flag.NArg() < 1 {
        flag.Usage()
        os.Exit(1)
    }

    // Process each provided path
    hasError := false
    for _, path := range flag.Args() {
        err := processPath(path)
        if err != nil {
            fmt.Fprintf(os.Stderr, "Error: %v\n", err)
            hasError = true
        }
    }

    if hasError {
        os.Exit(1)
    }
}
