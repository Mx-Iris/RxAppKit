//
//  MainWindowController.swift
//  NSTableView
//
//  Created by JH on 2022/12/22.
//

import AppKit

class MainWindowController: NSWindowController {
    let mainViewController: MainViewController

    init(folderURL: URL) {
        let mainViewController = MainViewController(folderURL: folderURL)
        mainViewController.view.frame = NSRect(x: 0, y: 0, width: 1024, height: 768)
        let window = NSWindow(contentViewController: mainViewController).then {
            $0.title = folderURL.absoluteString
        }
        self.mainViewController = mainViewController
        super.init(window: window)
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.center()
    }
}
