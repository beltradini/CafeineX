# VS Code Configuration for CafeineX Swift Project

## What's been configured

This workspace is now fully configured to work with the CafeineX iOS Swift project in VS Code:

### 1. **settings.json** — Swift Language Server & Editor Preferences
- **Swift Path**: Points to the active Xcode toolchain (`/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift`)
- **SourceKit-LSP Server**: Enables autocomplete, diagnostics, and code navigation
- **Format on Save**: Automatically formats Swift code
- **Tab Settings**: 4 spaces, matching the project convention
- **File Exclusions**: Hides build artifacts (DerivedData, xcuserdata, Logs)

### 2. **tasks.json** — Build, Test, and Analyze Commands
Three tasks are defined to run the project scripts:
- **Swift: Build** (Ctrl+Shift+B / Cmd+Shift+B)
- **Swift: Test** (from Task menu → Run Test Task)
- **Swift: Analyze** (from Task menu → Run Build Task)

All tasks use the reproducible `./Scripts/cx` entry point.

### 3. **extensions.json** — Recommended Extensions
- `swiftlang.swift-vscode` — Official Swift language support (already installed)
- `ms-vscode.makefile-tools` — Utility for build systems

### 4. **launch.json** — Quick Access
- Command to open the project directly in Xcode when needed

## How to Use

### Open the Project
```bash
code /Users/alexbeltran/Desktop/CafeineX
```

### Build, Test, Analyze
Press **Ctrl+Shift+B** (or Cmd+Shift+B on Mac) to build, or use:
- **Command Palette** → "Tasks: Run Build Task" → select task
- Terminal: `./Scripts/cx build`, `./Scripts/cx test`, `./Scripts/cx analyze`

### Code Navigation & Diagnostics
- **Go to Definition**: Cmd+Click or Cmd+Shift+O
- **Find References**: Cmd+Shift+F
- **Quick Fix**: Cmd+.
- Diagnostics appear inline as you type

### If SourceKit-LSP Doesn't Activate
1. Reload the window: **Command Palette** → "Developer: Reload Window"
2. Check the Output panel: **View** → **Output** → select "Swift" from the dropdown
3. Verify Xcode installation: `xcode-select -p`

## Project Structure Reference
- **CafeineX/**: Main app target
- **CafeineXTests/**: Unit test target
- **CafeineXWidgets/**: Widget extension
- **docs/**: Architecture and phase documentation
- **Scripts/cx**: Reproducible build/test entry point

## Xcode Workflow
While VS Code now provides Swift support, remember:
- **Real build**: Still runs through Xcode's build system
- **Full app development**: Open `CafeineX.xcodeproj` in Xcode for simulator, debugging, and UI testing
- **Command-line builds**: Use `./Scripts/cx` from the terminal

## Troubleshooting

### Swift version mismatch
Check your installed Xcode:
```bash
xcode-select -p
xcodebuild -version
swift --version
```
Should show Xcode 26.6+ and Swift 6.3.3+.

### .cargo/env error in scripts
The docs mention a shell configuration issue. Fix it by checking `~/.zshenv` for references to `.cargo/env` and commenting them out if that file doesn't exist.

---

**Last updated**: 2026-08-18
**Configuration**: VS Code with Swift 6, SourceKit-LSP, and CafeineX build tasks
