import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidBecomeActive(_ notification: Notification) {
        signal(SIGPIPE, SIG_IGN) //Ignore signal
    }
    
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 配合 Flutter 侧的 window_manager，一般不在最后一个窗口关闭时自动退出，
        // 而是交给托盘菜单来控制真正退出。
        return false
    }
    
    // 点击程序坞图标时，恢复被 hide()/orderOut 隐藏的主窗口
    // macOS 13+ 上只 makeKeyAndOrderFront 不够，需要 deminiaturize + orderFrontRegardless + activate 三连
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.deminiaturize(self)
                window.makeKeyAndOrderFront(self)
                window.orderFrontRegardless()
            }
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    // 通过 Cmd+H 或 NSApp.hide 把整个 App 隐藏后再点 dock 时，
    // 系统会发 unhide 而不是 reopen——这里同样把窗口顶到前面
    override func applicationDidUnhide(_ notification: Notification) {
        super.applicationDidUnhide(notification)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(self)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
