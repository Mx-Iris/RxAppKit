import AppKit

class ComboBoxDataSource: NSObject, NSComboBoxDataSource {
    var contents: [String] = []

    typealias IndexOfItem = (NSComboBox, String) -> Int
    typealias CompletedString = (NSComboBox, String) -> String?

    var indexOfItem: IndexOfItem?
    var completedString: CompletedString?

    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return contents.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return contents[index]
    }

    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        return indexOfItem?(comboBox, string) ?? contents.firstIndex(of: string) ?? -1
    }

    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
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
