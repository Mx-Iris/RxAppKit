import Foundation

/// Data source with access to underlying rows model.
public protocol RowsViewDataSourceType {
    /// Returns model at row.
    ///
    /// In case data source doesn't contain any sections when this method is being called, `RxCocoaError.ItemsNotYetBound(object: self)` is thrown.

    /// - parameter row: Model row index
    /// - returns: Model at row index.
    func model(at row: Int) throws -> Any
}
