//
//  TableView.swift
//  NSTableView
//
//  Created by JH on 2022/12/24.
//

import AppKit

class TableView: NSTableView {

    override func deselectRow(_ row: Int) {
        super.deselectRow(row)
        print(row)
    }
    
}
