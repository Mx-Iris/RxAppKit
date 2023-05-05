// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxAppKit",
    platforms: [.macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RxAppKit",
            targets: ["RxAppKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", .upToNextMajor(from: "6.5.0")),
        .package(url: "https://github.com/ra1028/DifferenceKit", .upToNextMajor(from: "1.3.0")),
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
            ]
        ),
        .target(name: "RxAppKitObjC"),
        .testTarget(
            name: "RxAppKitTests",
            dependencies: ["RxAppKit"]
        ),
    ]
)
