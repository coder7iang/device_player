import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidBecomeActive(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN) //Ignore signal
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
