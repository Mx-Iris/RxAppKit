import AppKit

public struct TableViewAnimationConfiguration {
    public let insertAnimation: NSTableView.AnimationOptions
    public let reloadAnimation: NSTableView.AnimationOptions
    public let deleteAnimation: NSTableView.AnimationOptions

    public init(
        insertAnimation: NSTableView.AnimationOptions = [],
        reloadAnimation: NSTableView.AnimationOptions = [],
        deleteAnimation: NSTableView.AnimationOptions = []
    ) {
        self.insertAnimation = insertAnimation
        self.reloadAnimation = reloadAnimation
        self.deleteAnimation = deleteAnimation
    }
}
