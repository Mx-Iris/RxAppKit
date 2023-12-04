//
//  MainWindowController.swift
//  SourceTree
//
//  Created by JH on 2023/5/10.
//

import Cocoa
import XcodeProj
import RxSwift
import RxCocoa


class MainWindowController: NSWindowController {
    
    @WindowLoading var mainViewController: MainViewController
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.center()
        
    }

}
