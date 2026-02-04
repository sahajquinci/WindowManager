import XCTest
@testable import WindowManager

/// Unit tests for WindowSwitcherState search functionality
final class WindowSwitcherSearchTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    /// Create a mock WindowInfo for testing
    private func mockWindow(title: String, appName: String) -> WindowInfo {
        return WindowInfo(
            window: AXUIElementCreateSystemWide(),
            title: title,
            appName: appName,
            appIcon: nil,
            processIdentifier: 0
        )
    }
    
    /// Create a WindowSwitcherState with given windows for testing
    private func createState(with windows: [WindowInfo]) -> WindowSwitcherState {
        return WindowSwitcherState(
            windows: windows,
            onSelect: { _ in },
            onDismiss: { }
        )
    }
    
    // MARK: - Search Tests
    
    func testEmptySearchReturnsAllWindows() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari"),
            mockWindow(title: "Inbox", appName: "Mail")
        ]
        
        let state = createState(with: windows)
        state.searchText = ""
        
        XCTAssertEqual(state.filteredWindows.count, 3, "Empty search should return all windows")
    }
    
    func testWhitespaceOnlySearchReturnsAllWindows() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "   "
        
        XCTAssertEqual(state.filteredWindows.count, 2, "Whitespace-only search should return all windows")
    }
    
    func testSearchByExactAppName() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari"),
            mockWindow(title: "Inbox", appName: "Mail")
        ]
        
        let state = createState(with: windows)
        state.searchText = "Safari"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find exactly one window")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
    }
    
    func testSearchByPartialAppName() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari"),
            mockWindow(title: "Inbox", appName: "Mail")
        ]
        
        let state = createState(with: windows)
        state.searchText = "saf"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find Safari with partial match 'saf'")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
    }
    
    func testSearchIsCaseInsensitive() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "SAFARI"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Search should be case insensitive")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
    }
    
    func testSearchChromeFindsGoogleChrome() {
        let windows = [
            mockWindow(title: "GitHub", appName: "Google Chrome"),
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "chrome"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find Google Chrome when searching 'chrome'")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
    }
    
    func testSearchByWindowTitle() {
        let windows = [
            mockWindow(title: "my-project - Visual Studio Code", appName: "Code"),
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "my-project"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find window by title")
        XCTAssertEqual(state.filteredWindows.first?.title, "my-project - Visual Studio Code")
    }
    
    func testSearchMatchesMultipleWindows() {
        let windows = [
            mockWindow(title: "Tab 1", appName: "Google Chrome"),
            mockWindow(title: "Tab 2", appName: "Google Chrome"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "google"
        
        XCTAssertEqual(state.filteredWindows.count, 3, "Should find all windows containing 'google'")
    }
    
    func testSearchWithNoMatches() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "firefox"
        
        XCTAssertEqual(state.filteredWindows.count, 0, "Should return empty when no matches")
    }
    
    func testSearchTrimsWhitespace() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Google", appName: "Safari")
        ]
        
        let state = createState(with: windows)
        state.searchText = "  safari  "
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should trim whitespace from search query")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Safari")
    }
    
    func testAppNameMatchesSortedFirst() {
        let windows = [
            mockWindow(title: "Chrome Extensions", appName: "Safari"),  // title contains "chrome"
            mockWindow(title: "GitHub", appName: "Google Chrome")       // app name contains "chrome"
        ]
        
        let state = createState(with: windows)
        state.searchText = "chrome"
        
        XCTAssertEqual(state.filteredWindows.count, 2, "Should find both windows")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome", "App name match should come first")
    }
    
    // MARK: - Navigation Tests
    
    func testMoveRightIncrementsIndex() {
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
    
    func testMoveRightStopsAtEnd() {
        let windows = [
            mockWindow(title: "Window 1", appName: "App1"),
            mockWindow(title: "Window 2", appName: "App2")
        ]
        
        let state = createState(with: windows)
        state.selectedIndex = 1
        
        state.moveRight()
        XCTAssertEqual(state.selectedIndex, 1, "Should not go past last window")
    }
    
    func testMoveLeftDecrementsIndex() {
        let windows = [
            mockWindow(title: "Window 1", appName: "App1"),
            mockWindow(title: "Window 2", appName: "App2")
        ]
        
        let state = createState(with: windows)
        state.selectedIndex = 1
        
        state.moveLeft()
        XCTAssertEqual(state.selectedIndex, 0)
    }
    
    func testMoveLeftStopsAtZero() {
        let windows = [
            mockWindow(title: "Window 1", appName: "App1"),
            mockWindow(title: "Window 2", appName: "App2")
        ]
        
        let state = createState(with: windows)
        state.selectedIndex = 0
        
        state.moveLeft()
        XCTAssertEqual(state.selectedIndex, 0, "Should not go below 0")
    }
    
    func testResetSelectionSetsIndexToZero() {
        let windows = [
            mockWindow(title: "Window 1", appName: "App1"),
            mockWindow(title: "Window 2", appName: "App2")
        ]
        
        let state = createState(with: windows)
        state.selectedIndex = 1
        
        state.resetSelection()
        XCTAssertEqual(state.selectedIndex, 0)
    }
    
    // MARK: - Additional Title Search Tests
    
    func testSearchFindsWindowByTitleOnly() {
        // App name is "Code" but title contains "Visual Studio"
        let windows = [
            mockWindow(title: "my-project - Visual Studio Code", appName: "Code"),
            mockWindow(title: "Document.txt", appName: "TextEdit")
        ]
        
        let state = createState(with: windows)
        state.searchText = "visual"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find VS Code via title 'visual'")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Code")
    }
    
    func testSearchFindsWindowByTitleSubstring() {
        let windows = [
            mockWindow(title: "GitHub - Mozilla Firefox", appName: "Firefox"),
            mockWindow(title: "Document.txt", appName: "TextEdit")
        ]
        
        let state = createState(with: windows)
        state.searchText = "github"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find Firefox window via title 'github'")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Firefox")
    }
    
    func testSearchFindsInboxByTitle() {
        let windows = [
            mockWindow(title: "Inbox - Mail", appName: "Mail"),
            mockWindow(title: "Document.txt", appName: "TextEdit")
        ]
        
        let state = createState(with: windows)
        state.searchText = "inbox"
        
        XCTAssertEqual(state.filteredWindows.count, 1, "Should find Mail via title 'inbox'")
        XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
    }
    
    func testSearchMatchesBothAppNameAndTitle() {
        let windows = [
            mockWindow(title: "Tab 1 - Google Chrome", appName: "Google Chrome"),
            mockWindow(title: "Tab 2 - Google Chrome", appName: "Google Chrome"),
            mockWindow(title: "Google Search Results", appName: "Safari"),
            mockWindow(title: "Document.txt", appName: "TextEdit")
        ]
        
        let state = createState(with: windows)
        state.searchText = "google"
        
        XCTAssertEqual(state.filteredWindows.count, 3, "Should find all windows with 'google' in app name OR title")
    }
    
    func testSearchWithSpecialCharactersInTitle() {
        let windows = [
            mockWindow(title: "my-project_v2.0", appName: "Code"),
            mockWindow(title: "file.txt", appName: "TextEdit")
        ]
        
        let state = createState(with: windows)
        state.searchText = "my-project"
        
        XCTAssertEqual(state.filteredWindows.count, 1)
        XCTAssertEqual(state.filteredWindows.first?.appName, "Code")
    }
    
    func testSearchWithDotInQuery() {
        let windows = [
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Image.png", appName: "Preview")
        ]
        
        let state = createState(with: windows)
        state.searchText = ".txt"
        
        XCTAssertEqual(state.filteredWindows.count, 1)
        XCTAssertEqual(state.filteredWindows.first?.title, "Document.txt")
    }
    
    // MARK: - State Update Tests
    
    func testSearchTextChangeUpdatesFilteredWindows() {
        let windows = [
            mockWindow(title: "Tab 1", appName: "Google Chrome"),
            mockWindow(title: "Document.txt", appName: "TextEdit"),
            mockWindow(title: "Inbox", appName: "Mail")
        ]
        
        let state = createState(with: windows)
        
        // Initially all windows
        XCTAssertEqual(state.filteredWindows.count, 3)
        
        // Filter to Chrome
        state.searchText = "chrome"
        XCTAssertEqual(state.filteredWindows.count, 1)
        XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
        
        // Change to Mail
        state.searchText = "mail"
        XCTAssertEqual(state.filteredWindows.count, 1)
        XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
        
        // Clear search
        state.searchText = ""
        XCTAssertEqual(state.filteredWindows.count, 3)
    }
    
    func testProgressiveTypingNarrowsResults() {
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
        
        state.searchText = "chro"
        let countCHRO = state.filteredWindows.count
        
        state.searchText = "chrom"
        let countCHROM = state.filteredWindows.count
        
        state.searchText = "chrome"
        let countCHROME = state.filteredWindows.count
        
        // Results should narrow or stay same as we type more
        XCTAssertGreaterThanOrEqual(countC, countCH)
        XCTAssertGreaterThanOrEqual(countCH, countCHR)
        XCTAssertGreaterThanOrEqual(countCHR, countCHRO)
        XCTAssertGreaterThanOrEqual(countCHRO, countCHROM)
        XCTAssertGreaterThanOrEqual(countCHROM, countCHROME)
        XCTAssertEqual(countCHROME, 3) // 2 Chrome + 1 Safari with "Chrome Help"
    }
    
    func testRapidSearchChanges() {
        let windows = [
            mockWindow(title: "Tab 1", appName: "Firefox"),
            mockWindow(title: "Tab 1", appName: "Google Chrome"),
            mockWindow(title: "Inbox", appName: "Mail")
        ]
        
        let state = createState(with: windows)
        
        // Rapidly change search
        state.searchText = "fire"
        XCTAssertEqual(state.filteredWindows.first?.appName, "Firefox")
        
        state.searchText = "chrome"
        XCTAssertEqual(state.filteredWindows.first?.appName, "Google Chrome")
        
        state.searchText = "mail"
        XCTAssertEqual(state.filteredWindows.first?.appName, "Mail")
        
        state.searchText = "fire"
        XCTAssertEqual(state.filteredWindows.first?.appName, "Firefox")
    }
    
    // MARK: - Grid Navigation Tests
    
    func testMoveDownInGridMode() {
        // Create 8 windows (2 rows of 4)
        let windows = (1...8).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
        
        let state = createState(with: windows)
        state.isVerticalMode = false // Grid mode
        XCTAssertEqual(state.selectedIndex, 0)
        
        state.moveDown()
        XCTAssertEqual(state.selectedIndex, 4, "Should move down one row (4 columns)")
    }
    
    func testMoveUpInGridMode() {
        let windows = (1...8).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
        
        let state = createState(with: windows)
        state.isVerticalMode = false
        state.selectedIndex = 5
        
        state.moveUp()
        XCTAssertEqual(state.selectedIndex, 1, "Should move up one row")
    }
    
    func testMoveDownInVerticalMode() {
        let windows = (1...4).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
        
        let state = createState(with: windows)
        state.isVerticalMode = true
        XCTAssertEqual(state.selectedIndex, 0)
        
        state.moveDown()
        XCTAssertEqual(state.selectedIndex, 1, "Should move down one item in list mode")
    }
    
    func testMoveUpInVerticalMode() {
        let windows = (1...4).map { mockWindow(title: "Window \($0)", appName: "App\($0)") }
        
        let state = createState(with: windows)
        state.isVerticalMode = true
        state.selectedIndex = 2
        
        state.moveUp()
        XCTAssertEqual(state.selectedIndex, 1, "Should move up one item in list mode")
    }
}
