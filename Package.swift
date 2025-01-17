// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "imqa-apm-iOS",
    platforms: [
        .iOS(.v13),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "imqa-apm-iOS", targets: ["imqa-apm-iOS"]),
        .library(name: "imqa-apm-iOS", targets: ["IMQACore"]),
        .library(name: "imqa-apm-iOS", targets: ["IMQAOtelInternal"]),
        .library(name: "imqa-apm-iOS", targets: ["IMQACommonInternal"]),
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
            name: "imqa-apm-iOS",
            dependencies: [
                "IMQACore"
            ]),
        
        // core service -----------------------------------------------------------
            .target(name: "IMQACore",
                    dependencies: [
                        "IMQACaptureService",
                        "IMQAOtelInternal",
                        "IMQACommonInternal",
                        "IMQACollectDeviceInfo",
                        .byName(name: "MMKV"),
                        "IMQAObjCUtilsInternal",
                        .product(name: "Installations", package: "KSCrash"),
                        .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
                        .product(name: "ResourceExtension", package: "opentelemetry-swift"),
                        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift"),
                    ],
                    path: "Sources/IMQACore"
                   ),
        
        // IMQACaptureService -----------------------------------------------------------
        .target(name: "IMQACaptureService",
                    dependencies: [
                        "IMQAOtelInternal",
                        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift")
                    ]),
                
        // IMQAObjCUtilsInternal -----------------------------------------------------------
        .target(name: "IMQAObjCUtilsInternal"),
        
        .target(name: "IMQACollectDeviceInfo"),
        
        // IMQAOtelInternal  -----------------------------------------------------------
        .target(name: "IMQAOtelInternal",
                    dependencies: [
                        "IMQACommonInternal",
                        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift"),
                        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift")
                    ],
                    path: "./Sources/IMQAOtelInternal",
                linkerSettings: [
                    // 添加 UIKit 作为系统框架依赖
                    .linkedFramework("UIKit")
                ]
               ),
        
        
        
        // IMQACommonInternal  -----------------------------------------------------------
        .target(name: "IMQACommonInternal",
                dependencies: [
                    
                ],
                path: "./Sources/IMQACommonInternal",
                
                linkerSettings: [
                    // 添加 UIKit 作为系统框架依赖
                    .linkedFramework("UIKit")
                ]
               ),
        
        // MMKV  -----------------------------------------------------------
        .binaryTarget(
            name: "MMKV",
            path: "./Sources/Frameworks/MMKV.xcframework" )
    ]//,
//    swiftLanguageModes:[.version("5.9")]
    
)
