//
//  MainViewController.swift
//  SourceTree
//
//  Created by JH on 2023/5/10.
//

import Cocoa
import XcodeProj
import RxSwift
import RxCocoa
import RxAppKit
import NSObject_Rx

class MainViewController: NSViewController {
    @ViewLoading @IBOutlet var outlineView: NSOutlineView

    @ViewLoading var project: XcodeProj {
        didSet {
            setupUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func setupUI() {
        outlineView.register(NSNib(nibNamed: .init(OutlineCellView.className), bundle: .main), forIdentifier: OutlineCellView.identifier)
        let nodes = project.pbxproj.groups.map { FileNode(fileElement: $0) }
        Observable.just(nodes).bind(to: outlineView.rx.nodes) { outlineView, tableColumn, node in
            let outlineCellView: OutlineCellView
            if let reuseView = outlineView.makeView(withIdentifier: OutlineCellView.identifier, owner: self) as? OutlineCellView {
                outlineCellView = reuseView
            } else {
                outlineCellView = .init()
                outlineCellView.identifier = OutlineCellView.identifier
            }
            outlineCellView.iconImageView.image = node.icon
            outlineCellView.nameLabel.stringValue = node.name ?? "The file is not found"
            return outlineCellView
        }
        .disposed(by: rx.disposeBag)

        outlineView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        outlineView.rowHeight = 30
    }
}

extension MainViewController: NSOutlineViewDelegate {}

class OutlineCellView: NSTableCellView {
    @IBOutlet var nameLabel: NSTextField!
    @IBOutlet var iconImageView: NSImageView!
    static var identifier: NSUserInterfaceItemIdentifier {
        .init(className)
    }

    static var className: String {
        .init(describing: self)
    }
}
