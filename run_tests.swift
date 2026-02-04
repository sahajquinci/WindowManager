#!/usr/bin/env swift

import Foundation
import AppKit

// ============================================================================
// MARK: - Copy of actual types from the app (for testing)
// ============================================================================

/// Information about a window (matches WindowModel.swift)
struct WindowInfo: Identifiable {
    let id = UUID()
    let window: AXUIElement
    let title: String
    let appName: String
    let appIcon: NSImage?
    let processIdentifier: pid_t
    var orderIndex: Int = Int.max
}

/// WindowSwitcherState (matches WindowSwitcherView.swift)
class WindowSwitcherState {
    let windows: [WindowInfo]
    let onSelect: (WindowInfo) -> Void
    let onDismiss: () -> Void
    
    var selectedIndex: Int = 0
    var searchText: String = ""
    var isVerticalMode: Bool = false
    
    let columnsPerRow: Int = 4
    
    var filteredWindows: [WindowInfo] {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty {
            return windows
        }
        
        let filtered = windows.filter { window in
            let appName = window.appName.lowercased()
            let title = window.title.lowercased()
            return appName.contains(query) || title.contains(query)
        }
        
        return filtered.sorted { w1, w2 in
            let app1 = w1.appName.lowercased()
            let app2 = w2.appName.lowercased()
            
            let app1Match = app1.contains(query)
            let app2Match = app2.contains(query)
            
            if app1Match && !app2Match { return true }
            if !app1Match && app2Match { return false }
            
            if app1.hasPrefix(query) && !app2.hasPrefix(query) { return true }
            if !app1.hasPrefix(query) && app2.hasPrefix(query) { return false }
            
            return false
        }
    }
    
    init(windows: [WindowInfo], onSelect: @escaping (WindowInfo) -> Void, onDismiss: @escaping () -> Void) {
        self.windows = windows
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }
    
    func moveUp() {
        if isVerticalMode {
            if selectedIndex > 0 { selectedIndex -= 1 }
        } else {
            let newIndex = selectedIndex - columnsPerRow
            if newIndex >= 0 { selectedIndex = newIndex }
        }
    }
    
    func moveDown() {
        if isVerticalMode {
            if selectedIndex < filteredWindows.count - 1 { selectedIndex += 1 }
        } else {
            let newIndex = selectedIndex + columnsPerRow
            if newIndex < filteredWindows.count { selectedIndex = newIndex }
        }
    }
    
    func moveLeft() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }
    
    func moveRight() {
        if selectedIndex < filteredWindows.count - 1 { selectedIndex += 1 }
    }
    
    func selectCurrent() {
        if !filteredWindows.isEmpty && selectedIndex < filteredWindows.count {
            onSelect(filteredWindows[selectedIndex])
        }
    }
    
    func resetSelection() {
        selectedIndex = 0
    }
}

// ============================================================================
// MARK: - Test Framework
// ============================================================================

var testsPassed = 0
var testsFailed = 0

func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if a == b {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL: \(message.isEmpty ? "Values not equal" : message)")
        print("   Expected: \(b)")
        print("   Got: \(a)")
        print("   at \(file):\(line)")
    }
}

func XCTAssertGreaterThanOrEqual<T: Comparable>(_ a: T, _ b: T, _ message: String = "") {
    if a >= b {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL: \(message)")
        print("   \(a) is not >= \(b)")
    }
}

func test(_ name: String, _ block: () -> Void) {
    let beforeFailed = testsFailed
    block()
    if testsFailed == beforeFailed {
        print("✅ \(name)")
    }
}

// ============================================================================
// MARK: - Test Helpers
// ============================================================================

func mockWindow(title: String, appName: String) -> WindowInfo {
    return WindowInfo(
        window: AXUIElementCreateSystemWide(),
        title: title,
        appName: appName,
        appIcon: nil,
        processIdentifier: 0
    )
}

func createState(with windows: [WindowInfo]) -> WindowSwitcherState {
    return WindowSwitcherState(
        windows: windows,
        onSelect: { _ in },
        onDismiss: { }
    )
}

// ============================================================================
// MARK: - Tests
// ============================================================================

print("🧪 Running WindowSwitcherState Unit Tests\n")
print(String(repeating: "=", count: 60))
print("\n--- Search Tests ---\n")

test("Empty search returns all windows") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari"),
        mockWindow(title: "Inbox", appName: "Mail")
    ]
    let state = createState(with: windows)
    state.searchText = ""
    XCTAssertEqual(state.filteredWindows.count, 3, "Empty search should return all windows")
}

test("Whitespace-only search returns all windows") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari")
    ]
    let state = createState(with: windows)
    state.searchText = "   "
    XCTAssertEqual(state.filteredWindows.count, 2)
}

test("Search by exact app name") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari"),
        mockWindow(title: "Inbox", appName: "Mail")
    ]
    let state = createState(with: windows)
    state.searchText = "Safari"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
}

test("Search by partial app name") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari")
    ]
    let state = createState(with: windows)
    state.searchText = "saf"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
}

test("Search is case insensitive") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari")
    ]
    let state = createState(with: windows)
    state.searchText = "SAFARI"
    XCTAssertEqual(state.filteredWindows.count, 1)
}

test("Search 'chrome' finds Google Chrome") {
    let windows = [
        mockWindow(title: "GitHub", appName: "Google Chrome"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    state.searchText = "chrome"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
}

test("Search finds window by title only") {
    let windows = [
        mockWindow(title: "my-project - Visual Studio Code", appName: "Code"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    state.searchText = "visual"
    XCTAssertEqual(state.filteredWindows.count, 1, "Should find VS Code via title 'visual'")
    XCTAssertEqual(state.filteredWindows.first?.appName, "Code")
}

test("Search finds GitHub in window title") {
    let windows = [
        mockWindow(title: "GitHub - Mozilla Firefox", appName: "Firefox"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    state.searchText = "github"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Firefox")
}

test("Search 'inbox' finds Mail by title") {
    let windows = [
        mockWindow(title: "Inbox - Mail", appName: "Mail"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    state.searchText = "inbox"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
}

test("Search matches both app name and title") {
    let windows = [
        mockWindow(title: "Tab 1 - Google Chrome", appName: "Google Chrome"),
        mockWindow(title: "Tab 2 - Google Chrome", appName: "Google Chrome"),
        mockWindow(title: "Google Search Results", appName: "Safari"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    state.searchText = "google"
    XCTAssertEqual(state.filteredWindows.count, 3, "Should find all windows with 'google'")
}

test("Search with no matches returns empty") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari")
    ]
    let state = createState(with: windows)
    state.searchText = "firefox"
    XCTAssertEqual(state.filteredWindows.count, 0)
}

test("Search trims whitespace") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Google", appName: "Safari")
    ]
    let state = createState(with: windows)
    state.searchText = "  safari  "
    XCTAssertEqual(state.filteredWindows.count, 1)
}

test("App name matches sorted before title matches") {
    let windows = [
        mockWindow(title: "Chrome Extensions", appName: "Safari"),
        mockWindow(title: "GitHub", appName: "Google Chrome")
    ]
    let state = createState(with: windows)
    state.searchText = "chrome"
    XCTAssertEqual(state.filteredWindows.count, 2)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome", "App name match first")
}

test("Search '.txt' in title") {
    let windows = [
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Image.png", appName: "Preview")
    ]
    let state = createState(with: windows)
    state.searchText = ".txt"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.title, "Document.txt")
}

print("\n--- State Update Tests ---\n")

test("Search text change updates filtered windows") {
    let windows = [
        mockWindow(title: "Tab 1", appName: "Google Chrome"),
        mockWindow(title: "Document.txt", appName: "TextEdit"),
        mockWindow(title: "Inbox", appName: "Mail")
    ]
    let state = createState(with: windows)
    
    XCTAssertEqual(state.filteredWindows.count, 3)
    
    state.searchText = "chrome"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
    
    state.searchText = "mail"
    XCTAssertEqual(state.filteredWindows.count, 1)
    XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
    
    state.searchText = ""
    XCTAssertEqual(state.filteredWindows.count, 3)
}

test("Progressive typing narrows results") {
    let windows = [
        mockWindow(title: "Tab 1", appName: "Google Chrome"),
        mockWindow(title: "Tab 2", appName: "Google Chrome"),
        mockWindow(title: "Chrome Help", appName: "Safari"),
        mockWindow(title: "Document.txt", appName: "TextEdit")
    ]
    let state = createState(with: windows)
    
    state.searchText = "c"
    let countC = state.filteredWindows.count
    
    state.searchText = "ch"
    let countCH = state.filteredWindows.count
    
    state.searchText = "chr"
    let countCHR = state.filteredWindows.count
    
    state.searchText = "chrome"
    let countCHROME = state.filteredWindows.count
    
    XCTAssertGreaterThanOrEqual(countC, countCH)
    XCTAssertGreaterThanOrEqual(countCH, countCHR)
    XCTAssertGreaterThanOrEqual(countCHR, countCHROME)
    XCTAssertEqual(countCHROME, 3)
}

test("Rapid search changes return correct results") {
    let windows = [
        mockWindow(title: "Tab 1", appName: "Firefox"),
        mockWindow(title: "Tab 1", appName: "Google Chrome"),
        mockWindow(title: "Inbox", appName: "Mail")
    ]
    let state = createState(with: windows)
    
    state.searchText = "fire"
    XCTAssertEqual(state.filteredWindows.first?.appName, "Firefox")
    
    state.searchText = "chrome"
    XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
    
    state.searchText = "mail"
    XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
}

print("\n--- Navigation Tests ---\n")

test("Move right increments index") {
    let windows = [
        mockWindow(title: "Window 1", appName: "App1"),
        mockWindow(title: "Window 2", appName: "App2"),
        mockWindow(title: "Window 3", appName: "App3")
    ]
    let state = createState(with: windows)
    XCTAssertEqual(state.selectedIndex, 0)
    
    state.moveRight()
    XCTAssertEqual(state.selectedIndex, 1)
    
    state.moveRight()
    XCTAssertEqual(state.selectedIndex, 2)
}

test("Move right stops at end") {
    let windows = [
        mockWindow(title: "Window 1", appName: "App1"),
        mockWindow(title: "Window 2", appName: "App2")
    ]
    let state = createState(with: windows)
    state.selectedIndex = 1
    
    state.moveRight()
    XCTAssertEqual(state.selectedIndex, 1, "Should not go past last")
}

test("Move left decrements index") {
    let windows = [
        mockWindow(title: "Window 1", appName: "App1"),
        mockWindow(title: "Window 2", appName: "App2")
    ]
    let state = createState(with: windows)
    state.selectedIndex = 1
    
    state.moveLeft()
    XCTAssertEqual(state.selectedIndex, 0)
}

test("Move left stops at zero") {
    let windows = [
        mockWindow(title: "Window 1", appName: "App1"),
        mockWindow(title: "Window 2", appName: "App2")
    ]
    let state = createState(with: windows)
    state.selectedIndex = 0
    
    state.moveLeft()
    XCTAssertEqual(state.selectedIndex, 0, "Should not go below 0")
}

test("Reset selection sets index to zero") {
    let windows = [
        mockWindow(title: "Window 1", appName: "App1"),
        mockWindow(title: "Window 2", appName: "App2")
    ]
    let state = createState(with: windows)
    state.selectedIndex = 1
    
    state.resetSelection()
    XCTAssertEqual(state.selectedIndex, 0)
}

test("Move down in grid mode jumps by row") {
    let windows = (1...8).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
    let state = createState(with: windows)
    state.isVerticalMode = false
    XCTAssertEqual(state.selectedIndex, 0)
    
    state.moveDown()
    XCTAssertEqual(state.selectedIndex, 4, "Should move down one row (4 columns)")
}

test("Move up in grid mode jumps by row") {
    let windows = (1...8).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
    let state = createState(with: windows)
    state.isVerticalMode = false
    state.selectedIndex = 5
    
    state.moveUp()
    XCTAssertEqual(state.selectedIndex, 1, "Should move up one row")
}

test("Move down in vertical mode moves one item") {
    let windows = (1...4).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
    let state = createState(with: windows)
    state.isVerticalMode = true
    XCTAssertEqual(state.selectedIndex, 0)
    
    state.moveDown()
    XCTAssertEqual(state.selectedIndex, 1)
}

test("Move up in vertical mode moves one item") {
    let windows = (1...4).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
    let state = createState(with: windows)
    state.isVerticalMode = true
    state.selectedIndex = 2
    
    state.moveUp()
    XCTAssertEqual(state.selectedIndex, 1)
}

// ============================================================================
// MARK: - Summary
// ============================================================================

print("\n" + String(repeating: "=", count: 60))
print("\n📊 Results: \(testsPassed) passed, \(testsFailed) failed\n")

if testsFailed > 0 {
    print("❌ Some tests failed!")
    exit(1)
} else {
    print("✅ All tests passed!")
    exit(0)
}
