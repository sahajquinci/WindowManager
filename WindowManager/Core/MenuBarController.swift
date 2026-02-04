import AppKit

/// Controls the menu bar interface
class MenuBarController {
    
    private weak var appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
}
