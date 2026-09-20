import Testing
@testable import RxAppKit

@Suite("AppKitPlus trait")
struct AppKitPlusTraitTests {
    /// The trait flag must agree with the condition the module was actually compiled under.
    ///
    /// The assertion itself is light. The value of this file is that it drags the test target
    /// into the same compilation environment as a downstream consumer: the test target imports
    /// RxAppKit, which imports AppKitPlus when the trait is on, and that implicit transitive
    /// visibility is exactly the path along which an upstream category member can turn a
    /// downstream subclass's property into an illegal override.
    @Test func traitFlagMatchesCompilationCondition() {
        #if AppKitPlus && canImport(AppKitPlus)
        #expect(RxAppKitTraits.isAppKitPlusEnabled)
        #else
        #expect(!RxAppKitTraits.isAppKitPlusEnabled)
        #endif
    }
}
