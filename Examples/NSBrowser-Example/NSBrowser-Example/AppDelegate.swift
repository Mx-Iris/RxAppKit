//
//  AppDelegate.swift
//  NSBrowser-Demo
//
//  Created by JH on 2023/5/1.
//

import AppKit
import RxSwift
import RxCocoa
import RxAppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSBrowserDelegate {
    @IBOutlet var window: NSWindow!

    @IBOutlet var browser: NSBrowser!

    let rootNode: FileSystemNode = .rootNode

    let disposeBag = DisposeBag()

    func applicationDidFinishLaunching(_ notification: Notification) {
        browser.setCellClass(FileSystemBrowserCell.self)
        browser.maxVisibleColumns = 3
        Observable.just(rootNode).asDriver(onErrorJustReturn: .rootNode).drive(browser.rx.rootNode(cellClass: FileSystemBrowserCell.self)) { node, cell, row, column in
            cell.iconImage = node.icon
        }
        .disposed(by: disposeBag)

        browser.rx.clickedIndex.subscribe { (row: Int, column: Int) in
            print(row, column)
        }
        .disposed(by: disposeBag)

        browser.rx.path.subscribe { (path: String) in
            print(path)
        }
        .disposed(by: disposeBag)

        browser.rx.doubleClicked.subscribe { (row: Int, column: Int) in
            print("doubleClick", row, column)
        }
        .disposed(by: disposeBag)

        browser.rx.setDelegate(self).disposed(by: disposeBag)
    }

    func bind() {
        
    }

    func browser(_ browser: NSBrowser, heightOfRow row: Int, inColumn columnIndex: Int) -> CGFloat {
        return 20
    }
}

class FileSystemBrowserCell: NSBrowserCell {
    static let iconSize: CGFloat = 16.0
    static let iconInsetHoriz: CGFloat = 4.0
    static let iconTextSpacing: CGFloat = 2.0
    static let iconInsetVert: CGFloat = 2.0

    var labelColor: NSColor?
    var iconImage: NSImage?
//    override init() {
//        super.init()
//    }
    
    override init(textCell: String) {
        super.init(textCell: textCell)
        self.lineBreakMode = .byTruncatingTail
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone) as! FileSystemBrowserCell
        if let iconImage = result.iconImage {
            let _ = Unmanaged<NSImage>.passRetained(iconImage)
        }
        return result
    }

    override func imageRect(forBounds bounds: NSRect) -> NSRect {
        var newBounds = bounds
        newBounds.origin.x += FileSystemBrowserCell.iconInsetHoriz
        newBounds.size.width = FileSystemBrowserCell.iconSize
        newBounds.origin.y += trunc((bounds.size.height - FileSystemBrowserCell.iconSize) / 2.0)
        newBounds.size.height = FileSystemBrowserCell.iconSize
        return newBounds
    }

    override func titleRect(forBounds bounds: NSRect) -> NSRect {
        let inset = (FileSystemBrowserCell.iconInsetHoriz + FileSystemBrowserCell.iconSize + FileSystemBrowserCell.iconTextSpacing)
        var newBounds = bounds
        newBounds.origin.x += inset
        newBounds.size.width -= inset
        return super.titleRect(forBounds: newBounds)
    }

    override func cellSize(forBounds aRect: NSRect) -> NSSize {
        var theSize = super.cellSize(forBounds: aRect)
        theSize.width += (FileSystemBrowserCell.iconInsetHoriz + FileSystemBrowserCell.iconSize + FileSystemBrowserCell.iconTextSpacing)
        theSize.height = FileSystemBrowserCell.iconInsetVert + FileSystemBrowserCell.iconSize + FileSystemBrowserCell.iconInsetVert
        return theSize
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        if let labelColor = labelColor {
            labelColor.withAlphaComponent(0.2).set()
            cellFrame.fill(using: .sourceOver)
        }

        let imageRect = self.imageRect(forBounds: cellFrame)
        if let image = iconImage {
            image.draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        }

        let inset = (FileSystemBrowserCell.iconInsetHoriz + FileSystemBrowserCell.iconSize + FileSystemBrowserCell.iconTextSpacing)
        var newCellFrame = cellFrame
        newCellFrame.origin.x += inset
        newCellFrame.size.width -= inset
        newCellFrame.origin.y += 1 // Looks better
        newCellFrame.size.height -= 1
        super.drawInterior(withFrame: newCellFrame, in: controlView)
    }

    override func draw(withExpansionFrame cellFrame: NSRect, in view: NSView) {
        super.drawInterior(withFrame: cellFrame, in: view)
    }
}
