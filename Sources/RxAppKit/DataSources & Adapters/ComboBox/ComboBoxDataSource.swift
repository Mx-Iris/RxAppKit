import AppKit

open class ComboBoxDataSource: NSObject, NSComboBoxDataSource {
    open var contents: [String] = []

    public typealias IndexOfItem = (_ comboBox: NSComboBox, _ stringValue: String) -> Int
    public typealias CompletedString = (_ comboBox: NSComboBox, _ completedString: String) -> String?

    open var indexOfItem: IndexOfItem?
    open var completedString: CompletedString?

    open func numberOfItems(in comboBox: NSComboBox) -> Int {
        return contents.count
    }

    open func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return contents[index]
    }

    open func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return indexOfItem?(comboBox, string) ?? contents.firstIndex(of: string) ?? -1
    }

    open func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        if let completedString {
            return completedString(comboBox, string)
        }
        for content in contents {
            if content.hasPrefix(string) {
                return content
            }
        }
        return nil
    }
}
