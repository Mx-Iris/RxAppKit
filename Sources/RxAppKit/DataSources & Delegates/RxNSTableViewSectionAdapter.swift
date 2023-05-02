import AppKit
import RxSwift
import RxCocoa
import DifferenceKit

open class RxNSTableViewSectionAdapter<Section: DifferentiableSection>: TableViewAdapter<Section.Collection.Element>, RxNSTableViewDataSourceType {
    public typealias Element = [Section]

    public typealias Item = Section.Collection.Element

    public typealias SectionSnapshot = ArraySection<Section, Item>

    open var animation: NSTableView.AnimationOptions = []

    public enum SectionType {
        case row
        case column
    }
    
    open var sectionType: SectionType = .column
    
    private var _sectionModels: [SectionSnapshot] = []

    open var sectionModels: [Section] {
        return _sectionModels.map { Section(source: $0.model, elements: $0.elements) }
    }

    open subscript(section: Int) -> Section {
        let sectionModel = _sectionModels[section]
        return Section(source: sectionModel.model, elements: sectionModel.elements)
    }

    open subscript(section: Int, item: Int) -> Item {
        get {
            _sectionModels[section].elements[item]
        }
        set {
            var columnModel = _sectionModels[section]
            columnModel.elements[item] = newValue
            _sectionModels[section] = columnModel
        }
    }

    open func setSections(_ section: [Section]) {
        _sectionModels = section.map { SectionSnapshot(model: $0, elements: $0.elements) }
    }

    open override func numberOfRows(in tableView: NSTableView) -> Int {
        return _sectionModels.map { $0.elements.count }.max() ?? 0
    }

    open override func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var column = 0
        if let tableColumn {
            column = tableView.column(withIdentifier: tableColumn.identifier)
        }
        let item: Item
        switch sectionType {
        case .row:
            item = self[row, column]
        case .column:
            item = self[column, row]
        }
        
        return cellProvider(tableView, tableColumn, row, item)
    }

    open override func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowItems: [Item]
        switch sectionType {
        case .row:
            rowItems = _sectionModels[row].elements
        case .column:
            rowItems = _sectionModels.map { $0.elements[row] }
        }
        return rowProvider(tableView, row, rowItems)
    }

    open func tableView(_ tableView: NSTableView, observedEvent: Event<[Section]>) {
        Binder<Element>(self) { dataSource, newColumns in
            let oldColumns = dataSource.sectionModels
            let changeset = StagedChangeset(source: oldColumns, target: newColumns)
            tableView.reload(using: changeset, with: dataSource.animation) {
                dataSource.setSections($0)
            }
        }.on(observedEvent)
    }
}
