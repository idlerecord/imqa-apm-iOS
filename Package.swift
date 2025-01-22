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
        .library(name: "IMQAIO", type: .dynamic, targets: ["IMQAIO"])
    ],
    dependencies: [
        .package(url: "https://github.com/open-telemetry/opentelemetry-swift",
                 exact: "1.12.1"
                ),
        .package(url: "https://github.com/kstenerud/KSCrash.git",
                 exact: "2.0.0-rc.8")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "IMQAIO",
            dependencies: [
                "IMQACore"
            ]),
        
        // core service -----------------------------------------------------------
            .target(name: "IMQACore",
                    dependencies: [
                        "IMQACaptureService",
                        .byName(name: "IMQAOtelInternal"),
                        .byName(name: "IMQACollectDeviceInfo"),
                        .byName(name: "MMKV"),
                        .byName(name: "IMQAObjCUtilsInternal"),
                        .product(name: "Installations", package: "KSCrash"),
                        .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
                        .product(name: "ResourceExtension", package: "opentelemetry-swift"),
                    ],
                    path: "Sources/IMQACore",
                    resources: [
                        .copy("PrivacyInfo.xcprivacy")
                    ]
                   ),
        
        // IMQACaptureService -----------------------------------------------------------
        .target(name: "IMQACaptureService",
                    dependencies: [
                        .byName(name: "IMQAOtelInternal")
                    ]),
                
        // IMQAObjCUtilsInternal -----------------------------------------------------------
        .binaryTarget(name: "IMQAObjCUtilsInternal",
                      path: "./Sources/IMQAObjCUtilsInternal/IMQAObjCUtilsInternal.xcframework"),
        
        .binaryTarget(name: "IMQACollectDeviceInfo",
                      path: "./Sources/IMQACollectDeviceInfo/IMQACollectDeviceInfo.xcframework"),
        
        // IMQAOtelInternal  -----------------------------------------------------------
        .target(name: "IMQAOtelInternal",
                    dependencies: [
                        .byName(name: "IMQACommonInternal"),
                        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift")
                    ],
                path: "./Sources/IMQAOtelInternal"
               ),
        
        
        // IMQACommonInternal  -----------------------------------------------------------
        .binaryTarget(name: "IMQACommonInternal",
                path: "./Sources/IMQACommonInternal/IMQACommonInternal.xcframework"
               ),
        
        // MMKV  -----------------------------------------------------------
        .binaryTarget(
            name: "MMKV",
            path: "./Sources/Frameworks/MMKV.xcframework" )
    ]
    //,swiftLanguageVersions: [.version("5.9")]
)
