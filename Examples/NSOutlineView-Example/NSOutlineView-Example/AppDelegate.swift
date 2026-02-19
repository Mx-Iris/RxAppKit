//
//  AppDelegate.swift
//  SourceTree
//
//  Created by JH on 2023/5/8.
//

import Cocoa
import RxAppKit
import Then
import UniformTypeIdentifiers
import NSObject_Rx
import XcodeProj

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSOpenPanel().then {
            $0.allowedContentTypes = [.xcodeProj]
            $0.allowsMultipleSelection = false
            $0.canChooseDirectories = false
            $0.canChooseFiles = true
        }.rx.begin().subscribe(with: self) { target, element in
            guard element.result == .OK, let url = element.panel.url else { return }
            NSStoryboard.main.instantiateWindowController(as: \.main).do {
                $0.showWindow(nil)
                ($0.contentViewController as? MainViewController)?.project = try! XcodeProj(pathString: url.path())
            }
        }
        .disposed(by: rx.disposeBag)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

extension UTType {
    static let xcodeProj = UTType("com.apple.xcode.project")!
}
