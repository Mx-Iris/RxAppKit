//
//  Storyboard.swift
//  SourceTree
//
//  Created by JH on 2023/5/10.
//

import AppKit

struct WindowScenes {
    let main = MainWindowController.self
}

struct ViewScenes {
    let main = MainViewController.self
}

extension NSStoryboard {
    static let main = NSStoryboard(name: "Main", bundle: .main)

    func instantiateViewController<Controller: NSViewController>(as controllerType: KeyPath<ViewScenes, Controller.Type>) -> Controller {
        instantiateController(identifier: Controller.className().removeCurrentModuleNamespace)
    }

    func instantiateWindowController<Controller: NSWindowController>(as controllerType: KeyPath<WindowScenes, Controller.Type>) -> Controller {
        instantiateController(identifier: Controller.className().removeCurrentModuleNamespace)
    }
}
extension String {
    var asNSString: NSString {
        self as NSString
    }
    
    var removeCurrentModuleNamespace: String {
        asNSString.replacingOccurrences(of: "SourceTree.", with: "")
    }
}
