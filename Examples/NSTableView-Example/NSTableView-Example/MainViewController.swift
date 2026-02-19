//
//  MainViewController.swift
//  NSTableView
//
//  Created by JH on 2022/12/22.
//

import AppKit
import RxSwift
import RxCocoa
import RxAppKit

class MainViewController: NSViewController {
    let scrollView = NSScrollView()
    
    let tableView = TableView()

    let directory: Directory

    let datas: [Metadata]

    let sizeFormatter = ByteCountFormatter()

    let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd hh:mm:ss"
    }

    let disposeBag = DisposeBag()

    init(folderURL: URL) {
        let directory = Directory(folderURL: folderURL)
        self.directory = directory
        self.datas = directory.contentsOrderedBy(.name, ascending: true)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Column: String {
        case name
        case date
        case size
        var reuseID: NSUserInterfaceItemIdentifier { .init(rawValue) }
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.documentView = tableView
        view.addSubview(scrollView)

        NSTableColumn(identifier: Column.name.reuseID).then {
            $0.title = "Name"
            $0.minWidth = 300
            $0.maxWidth = 1000
            tableView.addTableColumn($0)
        }
        NSTableColumn(identifier: Column.date.reuseID).then {
            $0.title = "Name"
            $0.minWidth = 300
            $0.maxWidth = 500
            tableView.addTableColumn($0)
        }
        NSTableColumn(identifier: Column.size.reuseID).then {
            $0.title = "Name"
            $0.minWidth = 100
            $0.maxWidth = 100
            tableView.addTableColumn($0)
        }
        tableView.register(NSNib(nibNamed: .init(describing: TableViewCell.self), bundle: .main), forIdentifier: Column.name.reuseID)
        tableView.register(NSNib(nibNamed: .init(describing: TableViewCell.self), bundle: .main), forIdentifier: Column.date.reuseID)
        tableView.register(NSNib(nibNamed: .init(describing: TableViewCell.self), bundle: .main), forIdentifier: Column.size.reuseID)

        Observable.just(datas).asDriver(onErrorJustReturn: []).drive(tableView.rx.items) { [weak self] tableView, tableColumn, row, item in
            guard let self = self else { return nil }
            guard let tableColumn = tableColumn,
                  let columnID = Column(rawValue: tableColumn.identifier.rawValue),
                  let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? TableViewCell
            else { return nil }

            switch columnID {
            case .name:
                cell.imageView?.image = item.icon
                cell.textField?.stringValue = item.name
            case .date:
                cell.textField?.stringValue = dateFormatter.string(from: item.date)
            case .size:
                cell.textField?.stringValue = item.isFolder ? "--" : sizeFormatter.string(fromByteCount: item.size)
            }
            return cell
        }
        .disposed(by: disposeBag)
        
        
        tableView.rx.itemClicked()
            .subscribe { (clickedRow: Int, clickedColumn: Int) in
                print(clickedRow, clickedColumn)
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemDoubleClicked()
            .subscribe { [weak self] (clickedRow: Int, clickedColumn: Int) in
                guard let self = self, clickedRow != -1, clickedColumn != -1 else { return }
                let data = self.datas[clickedRow]
                NSWorkspace.shared.open(data.url)
            }
            .disposed(by: disposeBag)
        
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        tableView.rx.didAddRow()
            .subscribe(with: self) { target, row in
                print("didAddRow", row.row)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        scrollView.frame = view.bounds
    }
}

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        30
    }
}
