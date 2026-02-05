import SwiftUI
import AppKit

// Observable controller to handle keyboard events properly
class WindowSwitcherState: ObservableObject {
    let windows: [WindowInfo]
    let onSelect: (WindowInfo) -> Void
    let onDismiss: () -> Void
    
    @Published var selectedIndex: Int = 0
    @Published var searchText: String = "" {
        didSet {
            updateFilteredWindows()
        }
    }
    @Published var isVerticalMode: Bool = false
    @Published var filteredWindows: [WindowInfo] = []
    
    // Grid layout info - 3 columns for larger preview cards
    let columnsPerRow: Int = 3
    
    init(windows: [WindowInfo], onSelect: @escaping (WindowInfo) -> Void, onDismiss: @escaping () -> Void) {
        self.windows = windows
        self.onSelect = onSelect
        self.onDismiss = onDismiss
        self.filteredWindows = windows
    }
    
    func updateFilteredWindows() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        print("🔍 FILTER called - query: '\(query)', searchText: '\(searchText)'")
        
        // If no search query, return all windows
        if query.isEmpty {
            print("🔍 Empty query, returning all \(windows.count) windows")
            filteredWindows = windows
            return
        }
        
        // Simple search: filter windows where app name OR title contains query
        let filtered = windows.filter { window in
            let appName = window.appName.lowercased()
            let title = window.title.lowercased()
            
            let matchesApp = appName.contains(query)
            let matchesTitle = title.contains(query)
            
            return matchesApp || matchesTitle
        }
        
        print("🔍 Filtered result: \(filtered.count) windows")
        
        // Sort matches: app name matches first, then title matches
        filteredWindows = filtered.sorted { w1, w2 in
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
    
    func moveUp() {
        if isVerticalMode {
            // List mode: move up one item
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
        } else {
            // Grid mode: move up one row
            let newIndex = selectedIndex - columnsPerRow
            if newIndex >= 0 {
                selectedIndex = newIndex
            }
        }
    }
    
    func moveDown() {
        if isVerticalMode {
            // List mode: move down one item
            if selectedIndex < filteredWindows.count - 1 {
                selectedIndex += 1
            }
        } else {
            // Grid mode: move down one row
            let newIndex = selectedIndex + columnsPerRow
            if newIndex < filteredWindows.count {
                selectedIndex = newIndex
            }
        }
    }
    
    func moveLeft() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func moveRight() {
        if selectedIndex < filteredWindows.count - 1 {
            selectedIndex += 1
        }
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

// Custom NSView that handles key events
class KeyHandlingView: NSView {
    weak var state: WindowSwitcherState?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard let state = state else {
            super.keyDown(with: event)
            return
        }
        
        switch event.keyCode {
        case 126: // Up arrow
            DispatchQueue.main.async {
                state.moveUp()
            }
        case 125: // Down arrow
            DispatchQueue.main.async {
                state.moveDown()
            }
        case 123: // Left arrow
            DispatchQueue.main.async {
                state.moveLeft()
            }
        case 124: // Right arrow
            DispatchQueue.main.async {
                state.moveRight()
            }
        case 36: // Return/Enter
            DispatchQueue.main.async {
                state.selectCurrent()
            }
        case 53: // Escape
            DispatchQueue.main.async {
                state.onDismiss()
            }
        case 48: // Tab
            DispatchQueue.main.async {
                if event.modifierFlags.contains(.shift) {
                    state.moveLeft()
                } else {
                    state.moveRight()
                }
            }
        default:
            super.keyDown(with: event)
        }
    }
}

struct KeyHandlingViewRepresentable: NSViewRepresentable {
    let state: WindowSwitcherState
    
    func makeNSView(context: Context) -> KeyHandlingView {
        let view = KeyHandlingView()
        view.state = state
        // Make it first responder after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: KeyHandlingView, context: Context) {
        nsView.state = state
    }
}

// Custom search field that passes special keys to parent
class SearchTextField: NSTextField {
    var onArrowKey: ((UInt16) -> Void)?
    var onEscape: (() -> Void)?
    var onEnter: (() -> Void)?
    var onTab: ((Bool) -> Void)? // Bool = isShiftPressed
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126, 125, 123, 124: // Arrow keys
            onArrowKey?(event.keyCode)
        case 53: // Escape
            onEscape?()
        case 36: // Enter
            onEnter?()
        case 48: // Tab
            onTab?(event.modifierFlags.contains(.shift))
        default:
            super.keyDown(with: event)
        }
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Handle special keys even when they might be intercepted
        switch event.keyCode {
        case 126, 125, 123, 124: // Arrow keys
            onArrowKey?(event.keyCode)
            return true
        case 48: // Tab
            onTab?(event.modifierFlags.contains(.shift))
            return true
        case 53: // Escape
            onEscape?()
            return true
        case 36: // Enter
            onEnter?()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

struct FocusableSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let state: WindowSwitcherState
    
    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }
    
    func makeNSView(context: Context) -> SearchTextField {
        let textField = SearchTextField()
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 16)
        textField.delegate = context.coordinator
        
        // Handle arrow keys
        textField.onArrowKey = { keyCode in
            switch keyCode {
            case 126: state.moveUp()
            case 125: state.moveDown()
            case 123: state.moveLeft()
            case 124: state.moveRight()
            default: break
            }
        }
        
        textField.onEscape = {
            state.onDismiss()
        }
        
        textField.onEnter = {
            state.selectCurrent()
        }
        
        textField.onTab = { isShift in
            if isShift {
                state.moveLeft()
            } else {
                state.moveRight()
            }
        }
        
        // Auto-focus after appearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            textField.window?.makeFirstResponder(textField)
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: SearchTextField, context: Context) {
        // Sync text field with state
        if nsView.stringValue != state.searchText {
            nsView.stringValue = state.searchText
        }
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let state: WindowSwitcherState
        
        init(state: WindowSwitcherState) {
            self.state = state
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                let newText = textField.stringValue
                print("📝 TEXT CHANGED: '\(newText)'")
                state.searchText = newText
                print("📝 filteredWindows count: \(state.filteredWindows.count)")
            }
        }
    }
}

struct WindowSwitcherView: View {
    @ObservedObject var state: WindowSwitcherState
    
    // Initialize with existing state object
    init(state: WindowSwitcherState) {
        self.state = state
    }
    
    // Convenience initializer for creating new state
    init(windows: [WindowInfo], onSelect: @escaping (WindowInfo) -> Void, onDismiss: @escaping () -> Void) {
        self.state = WindowSwitcherState(
            windows: windows,
            onSelect: onSelect,
            onDismiss: onDismiss
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Window list
            if state.filteredWindows.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "macwindow")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No windows found")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if state.isVerticalMode {
                // Vertical list mode
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(state.filteredWindows.enumerated()), id: \.element.id) { index, window in
                                WindowListRow(
                                    window: window,
                                    isSelected: index == state.selectedIndex
                                )
                                .id(index)
                                .onTapGesture {
                                    state.onSelect(window)
                                }
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: state.selectedIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            } else {
                // Grid mode (like Windows Alt+Tab with previews)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320, maximum: 360))], spacing: 20) {
                            ForEach(Array(state.filteredWindows.enumerated()), id: \.element.id) { index, window in
                                WindowGridItem(
                                    window: window,
                                    isSelected: index == state.selectedIndex
                                )
                                .id(index)
                                .onTapGesture {
                                    state.onSelect(window)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: state.selectedIndex) { _, newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer with hints
            HStack {
                Text("↑↓ Navigate")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Spacer()
                
                Text("↵ Select")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Spacer()
                
                Text("Esc Close")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 1200, height: 800)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.4), radius: 30)
        .onChange(of: state.searchText) { _, _ in
            state.resetSelection()
        }
    }
}

struct WindowListRow: View {
    let window: WindowInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = window.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 24))
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(window.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(window.appName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

struct WindowGridItem: View {
    let window: WindowInfo
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Window thumbnail preview - large size for clarity
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 300, height: 200)
                
                if let thumbnail = window.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 294, height: 194)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Fallback to large app icon if no thumbnail
                    if let icon = window.appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 80, height: 80)
                    } else {
                        Image(systemName: "macwindow")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // App info below the preview
            HStack(spacing: 8) {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                Text(window.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: 300)
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 4)
        )
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    WindowSwitcherView(
        windows: [
            WindowInfo(
                window: AXUIElementCreateSystemWide(),
                title: "Project - Xcode",
                appName: "Xcode",
                appIcon: NSImage(systemSymbolName: "hammer", accessibilityDescription: nil),
                processIdentifier: 0
            ),
            WindowInfo(
                window: AXUIElementCreateSystemWide(),
                title: "Safari",
                appName: "Safari",
                appIcon: NSImage(systemSymbolName: "safari", accessibilityDescription: nil),
                processIdentifier: 0
            ),
        ],
        onSelect: { _ in },
        onDismiss: { }
    )
}