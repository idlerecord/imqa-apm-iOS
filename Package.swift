// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IMQAIO",
    platforms: [
        .iOS(.v13),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "IMQAIO", type: .static, targets: ["IMQAIO"])
    ],
    dependencies: [
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift",
                 exact: "1.12.1"
                ),
        .package(url: "https://github.com/kstenerud/KSCrash.git",
                 exact: "2.0.0-rc.8"),
        //package에 다운로드 되는 버전으로 setting하세요.
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.28.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        
        // core service -----------------------------------------------------------
            .target(name: "IMQAIO",
                    dependencies: [
                        "IMQAOtelInternal",
                        "IMQACollectDeviceInfo",
                        .byName(name: "MMKV"),
                        "IMQAObjCUtilsInternal",
                        "IMQACommonInternal",
                        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift"),
                        .product(name: "Recording", package: "KSCrash"),
                        .product(name: "SwiftProtobuf", package: "swift-protobuf")
                    ],
                    path: "./Sources/IMQACore",
                    resources: [
                        .copy("PrivacyInfo.xcprivacy")
                    ]
                   ),
                    
        // IMQAObjCUtilsInternal -----------------------------------------------------------
        .target(name: "IMQAObjCUtilsInternal",
                path: "./Sources/IMQAObjCUtilsInternal"
               ),
        
        .target(name: "IMQACollectDeviceInfo",
                path: "./Sources/IMQACollectDeviceInfo"
               ),
        
        // IMQAOtelInternal  -----------------------------------------------------------
        .target(name: "IMQAOtelInternal",
                path: "./Sources/IMQAOtelInternal"
               ),
        
        // IMQACommonInternal  -----------------------------------------------------------
        .target(name: "IMQACommonInternal",
                path: "./Sources/IMQACommonInternal"
               ),
        
        // MMKV  -----------------------------------------------------------
        .binaryTarget(
            name: "MMKV",
            path: "./Sources/Frameworks/MMKV.xcframework" )
    ]
    //,swiftLanguageVersions: [.version("5.9")]
)
