#if AppKitPlus && canImport(AppKitPlus)
// Imported for its effect on this module, not for any symbol used below: it makes
// AppKitPlus's categories on NSTableView / NSOutlineView / NSCollectionView / NSControl
// and friends visible to every file in this target, so a name collision between an
// upstream category member and one of this library's extensions fails the build here
// rather than in a consumer's. Without this import the `AppKitPlus` trait would have no
// observable effect on compilation at all.
import AppKitPlus
#endif

/// Compile-time facts about which optional pieces of RxAppKit this build contains.
///
/// SwiftPM traits are resolved when the package graph is built, so a consumer cannot tell
/// from the outside whether the copy of RxAppKit it linked against was built with the
/// `AppKitPlus` trait on. These constants make that answer available at the call site.
public enum RxAppKitTraits {
    /// Whether this build of RxAppKit was compiled with the `AppKitPlus` package trait enabled.
    ///
    /// Enable it from a consuming package with `traits: ["AppKitPlus"]` on the package
    /// dependency, or from the command line with `swift build --traits AppKitPlus`.
    ///
    /// The trait does not re-export AppKitPlus: a consumer that wants its API declares its
    /// own dependency on `AppKitPlus-Release` and imports it directly.
    public static let isAppKitPlusEnabled: Bool = {
        #if AppKitPlus && canImport(AppKitPlus)
        true
        #else
        false
        #endif
    }()
}
