//
//  AppDelegate.swift
//  NSTableView
//
//  Created by JH on 2022/12/22.
//

import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false
        dialog.begin { result in
            if case .OK = result, let url = dialog.url {
                let mainWC = MainWindowController(folderURL: url)
                mainWC.showWindow(nil)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

