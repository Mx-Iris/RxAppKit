// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxAppKit",
    // macOS 12 is AppKitPlus's own floor. A binary target's platform requirement is
    // checked on the package graph, so neither `@available` nor `#if AppKitPlus` can
    // keep this at 10.13 while the trait is available -- see the AppKitPlus proposal
    // in Documentations/Evolutions.
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RxAppKit",
            targets: ["RxAppKit"]
        ),
    ],
    traits: [
        .trait(name: "AppKitPlus"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveX/RxSwift",
            .upToNextMajor(from: "6.6.0")
        ),
        .package(
            url: "https://github.com/ra1028/DifferenceKit",
            .upToNextMajor(from: "1.3.0")
        ),
        // 0.4.2 is a floor, not a pin. Upstream promises no API or ABI stability, so
        // every version bump needs a `swift build --traits AppKitPlus` to recheck the
        // naming conflict surface against this library's extensions.
        .package(
            url: "https://github.com/AppKitSupportProgram/AppKitPlus-Release",
            from: "0.4.2"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RxAppKit",
            dependencies: [
                "RxAppKitObjC",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "DifferenceKit", package: "DifferenceKit"),
                .product(
                    name: "AppKitPlus",
                    package: "AppKitPlus-Release",
                    condition: .when(traits: ["AppKitPlus"])
                ),
            ]
        ),

        .target(
            name: "RxAppKitObjC"
        ),

        .testTarget(
            name: "RxAppKitTests",
            dependencies: ["RxAppKit"]
        ),
    ],
    // Required, not optional: a tools-version of 6.0 or later defaults to the Swift 6
    // language mode, which would turn on strict concurrency checking across the package.
    swiftLanguageModes: [.v5]
)
