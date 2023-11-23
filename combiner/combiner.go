package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
)

type FileNode struct {
	path     string
	isDir    bool
	selected bool
	children []*FileNode
}

type FileProcessor struct {
	window    fyne.Window
	tree      *widget.Tree
	nodes     map[string]*FileNode
	rootNode  *FileNode
	outputBox *widget.Entry
}

func NewFileProcessor() *FileProcessor {
	myApp := app.New()
	myWindow := myApp.NewWindow("File Processor")

	fp := &FileProcessor{
		window: myWindow,
		nodes:  make(map[string]*FileNode),
	}

	fp.setupUI()

	// Get current directory and load it immediately
	currentDir, err := os.Getwd()
	if err != nil {
		dialog.ShowError(err, fp.window)
		return fp
	}
	fp.loadDirectory(currentDir)

	return fp
}

func (fp *FileProcessor) setupUI() {
	// Create confirm button
	confirmButton := widget.NewButton("Confirm", func() {
		content := fp.outputBox.Text
		fp.window.Clipboard().SetContent(content)
		fp.window.Close()
	})

	// Create main layout containers
	mainContainer := container.NewVBox(
		container.NewHSplit(
			container.NewVScroll(fp.createTree()),
			container.NewVScroll(fp.createOutput()),
		),
		container.NewHBox(
			widget.NewLabel(""), // Spacer
			confirmButton,
		),
	)

	// Set window content and size
	fp.window.SetContent(mainContainer)
	fp.window.Resize(fyne.NewSize(800, 600))
}

func (fp *FileProcessor) createTree() fyne.CanvasObject {
	fp.tree = &widget.Tree{
		ChildUIDs: func(uid string) []string {
			node := fp.nodes[uid]
			if node == nil {
				return []string{}
			}
			childUIDs := make([]string, len(node.children))
			for i, child := range node.children {
				childUIDs[i] = child.path
			}
			return childUIDs
		},
		IsBranch: func(uid string) bool {
			node := fp.nodes[uid]
			return node != nil && node.isDir
		},
		CreateNode: func(branch bool) fyne.CanvasObject {
			return container.NewHBox(
				widget.NewCheck("", nil),
				widget.NewLabel(""),
			)
		},
		UpdateNode: func(uid string, branch bool, obj fyne.CanvasObject) {
			node := fp.nodes[uid]
			if node == nil {
				return
			}

			container := obj.(*fyne.Container)
			check := container.Objects[0].(*widget.Check)
			label := container.Objects[1].(*widget.Label)

			check.Checked = node.selected
			check.OnChanged = func(checked bool) {
				node.selected = checked
				fp.updateSelection(node, checked)
				fp.processSelectedFiles()
			}

			label.SetText(filepath.Base(node.path))
		},
	}

	return fp.tree
}

func (fp *FileProcessor) createOutput() fyne.CanvasObject {
	fp.outputBox = widget.NewMultiLineEntry()
	fp.outputBox.Disable()
	return fp.outputBox
}

func (fp *FileProcessor) loadDirectory(path string) {
	fp.nodes = make(map[string]*FileNode)
	fp.rootNode = &FileNode{
		path:  path,
		isDir: true,
	}
	fp.nodes[path] = fp.rootNode

	err := filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		node := &FileNode{
			path:  path,
			isDir: info.IsDir(),
		}
		fp.nodes[path] = node

		// Add to parent's children
		parent := fp.nodes[filepath.Dir(path)]
		if parent != nil {
			parent.children = append(parent.children, node)
		}

		return nil
	})

	if err != nil {
		dialog.ShowError(err, fp.window)
		return
	}

	fp.tree.Root = path
	fp.tree.Refresh()
}

func (fp *FileProcessor) updateSelection(node *FileNode, checked bool) {
	if node.isDir {
		for _, child := range node.children {
			child.selected = checked
			fp.updateSelection(child, checked)
		}
	}
	fp.tree.Refresh()
}

func (fp *FileProcessor) processSelectedFiles() {
	var output strings.Builder

	var processNode func(*FileNode)
	processNode = func(node *FileNode) {
		if node.selected && !node.isDir {
			content, err := ioutil.ReadFile(node.path)
			if err != nil {
				output.WriteString(fmt.Sprintf("Error reading %s: %v\n", node.path, err))
				return
			}

			if !isBinary(content) {
				commentStyle := getCommentStyle(node.path)
				output.WriteString(fmt.Sprintf("%s %s\n", commentStyle, node.path))
				output.WriteString(string(content))
				output.WriteString("\n\n")
			}
		}

		for _, child := range node.children {
			processNode(child)
		}
	}

	processNode(fp.rootNode)
	fp.outputBox.SetText(output.String())
}

func isBinary(content []byte) bool {
	if bytes.IndexByte(content, 0) != -1 {
		return true
	}

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

func getCommentStyle(filename string) string {
	ext := strings.ToLower(filepath.Ext(filename))

	slashCommentExts := map[string]bool{
		".go":    true,
		".java":  true,
		".js":    true,
		".cpp":   true,
		".c":     true,
		".h":     true,
		".cs":    true,
		".kt":    true,
		".swift": true,
	}

	hashCommentExts := map[string]bool{
		".py":   true,
		".rb":   true,
		".pl":   true,
		".sh":   true,
		".bash": true,
		".yml":  true,
		".yaml": true,
		".conf": true,
		".txt":  true,
		".md":   true,
		"":      true,
	}

	if slashCommentExts[ext] {
		return "//"
	}
	if hashCommentExts[ext] {
		return "#"
	}
	return "//"
}

func main() {
	fp := NewFileProcessor()
	fp.window.ShowAndRun()
}
