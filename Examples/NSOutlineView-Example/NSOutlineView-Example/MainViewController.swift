import Cocoa
import XcodeProj
import RxSwift
import RxCocoa
import RxRelay
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
        let rootGroup = try? project.pbxproj.rootProject()?.mainGroup
        let nodes = (rootGroup?.children ?? []).map { FileNode(fileElement: $0) }
        let nodesRelay = BehaviorRelay(value: nodes)

        nodesRelay.bind(to: outlineView.rx.reorderableNodes) { outlineView, tableColumn, node in
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

        outlineView.rx.nodeMoved()
            .subscribe(onNext: { move in
                var nodes = nodesRelay.value
                move.apply(to: &nodes) { parent, newChildren in
                    parent.internalChildren = newChildren
                }
                nodesRelay.accept(nodes)
            })
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
