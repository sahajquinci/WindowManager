#!/usr/bin/env swift

import Foundation

// ============================================================================
// MARK: - Mock Types (matching the real app types)
// ============================================================================

struct MockWindowInfo {
    let title: String
    let appName: String
}

// ============================================================================
// MARK: - Search Logic (copied from WindowSwitcherView.swift)
// ============================================================================

func filterWindows(_ windows: [MockWindowInfo], searchText: String) -> [MockWindowInfo] {
    let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
    
    // If no search query, return all windows
    if query.isEmpty {
        return windows
    }
    
    // Simple search: filter windows where app name OR title contains query
    let filtered = windows.filter { window in
        let appName = window.appName.lowercased()
        let title = window.title.lowercased()
        
        return appName.contains(query) || title.contains(query)
    }
    
    // Sort matches: app name matches first, then title matches
    return filtered.sorted { w1, w2 in
        let app1 = w1.appName.lowercased()
        let app2 = w2.appName.lowercased()
        
        let app1Match = app1.contains(query)
        let app2Match = app2.contains(query)
        
        if app1Match && !app2Match { return true }
        if !app1Match && app2Match { return false }
        
        // Both match app name or both match title - prefer starts with
        if app1.hasPrefix(query) && !app2.hasPrefix(query) { return true }
        if !app1.hasPrefix(query) && app2.hasPrefix(query) { return false }
        
        return false
    }
}

// ============================================================================
// MARK: - Test Framework
// ============================================================================

var testsPassed = 0
var testsFailed = 0

func test(_ name: String, _ condition: Bool, _ message: String = "") {
    if condition {
        print("✅ PASS: \(name)")
        testsPassed += 1
    } else {
        print("❌ FAIL: \(name)")
        if !message.isEmpty {
            print("   └─ \(message)")
        }
        testsFailed += 1
    }
}

// ============================================================================
// MARK: - Test Cases
// ============================================================================

print("🧪 Running WindowManager Search Tests\n")
print(String(repeating: "=", count: 50))

// Test data
let testWindows = [
    MockWindowInfo(title: "GitHub - Mozilla Firefox", appName: "Firefox"),
    MockWindowInfo(title: "Tab 1 - Google Chrome", appName: "Google Chrome"),
    MockWindowInfo(title: "Tab 2 - Google Chrome", appName: "Google Chrome"),
    MockWindowInfo(title: "Document.txt", appName: "TextEdit"),
    MockWindowInfo(title: "Inbox - Mail", appName: "Mail"),
    MockWindowInfo(title: "my-project - Visual Studio Code", appName: "Code"),
    MockWindowInfo(title: "Google Search", appName: "Safari"),
    MockWindowInfo(title: "Chrome Extensions Help", appName: "Safari"),
]

// Test 1: Empty search returns all windows
do {
    let result = filterWindows(testWindows, searchText: "")
    test("Empty search returns all windows", 
         result.count == testWindows.count,
         "Expected \(testWindows.count), got \(result.count)")
}

// Test 2: Whitespace-only search returns all windows
do {
    let result = filterWindows(testWindows, searchText: "   ")
    test("Whitespace-only search returns all windows",
         result.count == testWindows.count,
         "Expected \(testWindows.count), got \(result.count)")
}

// Test 3: Search "chrome" finds Google Chrome windows
do {
    let result = filterWindows(testWindows, searchText: "chrome")
    let chromeWindows = result.filter { $0.appName == "Google Chrome" }
    test("Search 'chrome' finds Google Chrome",
         chromeWindows.count == 2,
         "Expected 2 Chrome windows, got \(chromeWindows.count). Total results: \(result.count)")
}

// Test 4: Search is case insensitive
do {
    let result1 = filterWindows(testWindows, searchText: "CHROME")
    let result2 = filterWindows(testWindows, searchText: "Chrome")
    let result3 = filterWindows(testWindows, searchText: "chrome")
    test("Search is case insensitive",
         result1.count == result2.count && result2.count == result3.count,
         "Different cases returned different results")
}

// Test 5: Search by exact app name
do {
    let result = filterWindows(testWindows, searchText: "Firefox")
    test("Search by exact app name 'Firefox'",
         result.count == 1 && result.first?.appName == "Firefox",
         "Expected Firefox, got \(result.first?.appName ?? "nil")")
}

// Test 6: Search by partial app name
do {
    let result = filterWindows(testWindows, searchText: "fire")
    test("Search by partial app name 'fire'",
         result.count == 1 && result.first?.appName == "Firefox",
         "Expected Firefox, got \(result.first?.appName ?? "nil")")
}

// Test 7: Search by window title
do {
    let result = filterWindows(testWindows, searchText: "my-project")
    test("Search by window title 'my-project'",
         result.count == 1 && result.first?.appName == "Code",
         "Expected VS Code, got \(result.first?.appName ?? "nil")")
}

// Test 8: Search matches multiple windows
do {
    let result = filterWindows(testWindows, searchText: "google")
    test("Search 'google' matches multiple windows",
         result.count >= 3,
         "Expected at least 3 matches (2 Chrome + Safari with Google title), got \(result.count)")
}

// Test 9: No matches returns empty
do {
    let result = filterWindows(testWindows, searchText: "notepad")
    test("No matches returns empty",
         result.count == 0,
         "Expected 0, got \(result.count)")
}

// Test 10: Search trims whitespace
do {
    let result1 = filterWindows(testWindows, searchText: "firefox")
    let result2 = filterWindows(testWindows, searchText: "  firefox  ")
    test("Search trims whitespace",
         result1.count == result2.count,
         "Trimmed and untrimmed searches returned different results")
}

// Test 11: App name matches sorted before title matches
do {
    let result = filterWindows(testWindows, searchText: "chrome")
    // Should have Google Chrome windows first (app name match),
    // then Safari window with "Chrome Extensions Help" title
    let firstResult = result.first
    test("App name matches sorted before title matches",
         firstResult?.appName == "Google Chrome",
         "Expected Google Chrome first, got \(firstResult?.appName ?? "nil")")
}

// Test 12: Search "mail" finds Mail app
do {
    let result = filterWindows(testWindows, searchText: "mail")
    test("Search 'mail' finds Mail app",
         result.count >= 1 && result.first?.appName == "Mail",
         "Expected Mail, got \(result.first?.appName ?? "nil")")
}

// Test 13: Search "code" finds VS Code
do {
    let result = filterWindows(testWindows, searchText: "code")
    test("Search 'code' finds VS Code",
         result.count >= 1 && result.contains(where: { $0.appName == "Code" }),
         "Expected to find Code app in results")
}

// ============================================================================
// MARK: - Additional Tests for Edge Cases
// ============================================================================

print("\n--- Additional Edge Case Tests ---\n")

// Test 14: Search in window title (not just app name)
do {
    let result = filterWindows(testWindows, searchText: "github")
    test("Search 'github' finds window by title",
         result.count == 1 && result.first?.title.lowercased().contains("github") == true,
         "Expected to find GitHub window by title, got \(result.count) results")
}

// Test 15: Search "tab" matches window titles
do {
    let result = filterWindows(testWindows, searchText: "tab")
    test("Search 'tab' finds windows with 'Tab' in title",
         result.count == 2,
         "Expected 2 windows with Tab in title, got \(result.count)")
}

// Test 16: Search "inbox" finds Mail by title
do {
    let result = filterWindows(testWindows, searchText: "inbox")
    test("Search 'inbox' finds Mail window by title",
         result.count == 1 && result.first?.appName == "Mail",
         "Expected Mail app (title: Inbox), got \(result.first?.appName ?? "nil")")
}

// Test 17: Search finds partial match at end of word
do {
    let result = filterWindows(testWindows, searchText: "edit")
    test("Search 'edit' finds TextEdit",
         result.count >= 1 && result.contains(where: { $0.appName == "TextEdit" }),
         "Expected to find TextEdit")
}

// Test 18: Search single character
do {
    let result = filterWindows(testWindows, searchText: "a")
    test("Search single char 'a' finds matches",
         result.count > 0,
         "Expected at least 1 match for 'a', got \(result.count)")
}

// Test 19: Search special characters in title
do {
    let windowsWithSpecial = [
        MockWindowInfo(title: "my-project - VS Code", appName: "Code"),
        MockWindowInfo(title: "file_name.txt", appName: "TextEdit"),
    ]
    let result = filterWindows(windowsWithSpecial, searchText: "my-project")
    test("Search handles hyphens in title",
         result.count == 1,
         "Expected 1 match, got \(result.count)")
}

// Test 20: Search ".txt" in title
do {
    let result = filterWindows(testWindows, searchText: ".txt")
    test("Search '.txt' finds document",
         result.count == 1 && result.first?.title.contains(".txt") == true,
         "Expected Document.txt, got \(result.first?.title ?? "nil")")
}

// Test 21: Verify both appName AND title are searched
do {
    // "visual" is in the title "Visual Studio Code" but the appName is "Code"
    let result = filterWindows(testWindows, searchText: "visual")
    test("Search 'visual' finds VS Code via title",
         result.count == 1 && result.first?.appName == "Code",
         "Expected Code app (title contains 'Visual'), got \(result.first?.appName ?? "nil")")
}

// Test 22: Search "studio" in title
do {
    let result = filterWindows(testWindows, searchText: "studio")
    test("Search 'studio' finds VS Code via title",
         result.count == 1 && result.first?.appName == "Code",
         "Expected Code app, got \(result.first?.appName ?? "nil")")
}

// ============================================================================
// MARK: - State Simulation Tests
// ============================================================================

print("\n--- State Update Simulation Tests ---\n")

// Test 23: Simulate typing one character at a time
do {
    var searchText = ""
    var results: [[MockWindowInfo]] = []
    
    for char in "chrome" {
        searchText += String(char)
        results.append(filterWindows(testWindows, searchText: searchText))
    }
    
    // Each progressive search should narrow or maintain results
    let progressivelyNarrowing = zip(results.dropLast(), results.dropFirst()).allSatisfy { prev, curr in
        curr.count <= prev.count
    }
    test("Progressive typing narrows results",
         progressivelyNarrowing,
         "Results should narrow as more chars are typed")
}

// Test 24: Simulate clearing search
do {
    let withSearch = filterWindows(testWindows, searchText: "chrome")
    let cleared = filterWindows(testWindows, searchText: "")
    test("Clearing search restores all windows",
         cleared.count == testWindows.count && cleared.count > withSearch.count,
         "Expected all windows after clear")
}

// Test 25: Rapid search changes
do {
    let search1 = filterWindows(testWindows, searchText: "fire")
    let search2 = filterWindows(testWindows, searchText: "chrome")
    let search3 = filterWindows(testWindows, searchText: "mail")
    
    test("Rapid search changes return correct results",
         search1.first?.appName == "Firefox" &&
         search2.first?.appName == "Google Chrome" &&
         search3.first?.appName == "Mail",
         "Each search should return correct app")
}

// ============================================================================
// MARK: - Summary
// ============================================================================

print(String(repeating: "=", count: 50))
print("\n📊 Results: \(testsPassed) passed, \(testsFailed) failed\n")

if testsFailed > 0 {
    print("❌ Some tests failed!")
    exit(1)
} else {
    print("✅ All tests passed!")
    exit(0)
}
