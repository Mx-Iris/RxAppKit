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
                Self.applyMove(move, to: &nodes)
                nodesRelay.accept(nodes)
            })
            .disposed(by: rx.disposeBag)

        outlineView.rx.setDelegate(self).disposed(by: rx.disposeBag)
        outlineView.rowHeight = 30
    }

    // MARK: - Apply Move

    private static func findNode(at path: IndexPath, in roots: [FileNode]) -> FileNode? {
        var current = roots
        for (i, index) in path.enumerated() {
            guard index >= 0, index < current.count else { return nil }
            if i == path.count - 1 { return current[index] }
            current = current[index].children
        }
        return nil
    }

    private static func applyMove(_ move: OutlineMove, to nodes: inout [FileNode]) {
        let sourceParent = move.sourceParentPath.flatMap { findNode(at: $0, in: nodes) }
        let destParent = move.destinationParentPath.flatMap { findNode(at: $0, in: nodes) }
        let sameParent = move.sourceParentPath == move.destinationParentPath
        let sortedAsc = move.sourceIndexes.sorted()

        if sameParent {
            var children = sourceParent?.children ?? nodes
            let movedItems = sortedAsc.compactMap { $0 < children.count ? children[$0] : nil }
            guard movedItems.count == sortedAsc.count else { return }

            for index in move.sourceIndexes.sorted(by: >) {
                children.remove(at: index)
            }
            var targetIndex = move.destinationIndex
            for index in move.sourceIndexes.sorted(by: >) where index < targetIndex {
                targetIndex -= 1
            }
            let clamped = max(0, min(targetIndex, children.count))
            for (offset, item) in movedItems.enumerated() {
                children.insert(item, at: clamped + offset)
            }

            if let sourceParent {
                sourceParent.internalChildren = children
            } else {
                nodes = children
            }
        } else {
            // Snapshot both sides before any mutation
            var srcChildren = sourceParent?.children ?? nodes
            var dstChildren = destParent?.children ?? nodes
            let movedItems = sortedAsc.compactMap { $0 < srcChildren.count ? srcChildren[$0] : nil }
            guard movedItems.count == sortedAsc.count else { return }

            // Remove from source
            for index in move.sourceIndexes.sorted(by: >) {
                srcChildren.remove(at: index)
            }
            if let sourceParent {
                sourceParent.internalChildren = srcChildren
            } else {
                nodes = srcChildren
            }

            // Insert at destination
            let clamped = max(0, min(move.destinationIndex, dstChildren.count))
            for (offset, item) in movedItems.enumerated() {
                dstChildren.insert(item, at: clamped + offset)
            }
            if let destParent {
                destParent.internalChildren = dstChildren
            } else {
                nodes = dstChildren
            }
        }
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
