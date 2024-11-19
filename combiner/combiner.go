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

func processFile(path string) error {
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

func main() {
    // Set up command-line argument parsing
    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, "Usage: %s [paths...]\n", os.Args[0])
        fmt.Fprintf(os.Stderr, "Recursively print files and their contents from specified paths.\n")
        fmt.Fprintf(os.Stderr, "Paths can be files or directories.\n")
        flag.PrintDefaults()
    }

    flag.Parse()

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
