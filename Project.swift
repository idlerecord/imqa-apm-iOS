import ProjectDescription

let settings = Settings.settings(
    base: [
        "SWIFT_VERSION": "5.9"//,
//        "OTHER_LDFLAGS": "$(inherited) -ObjC"
          ]
)

let project = Project(
    name: "IMQACore",
    organizationName: "ONYCOM",
    settings: settings,
    targets: [
        .target(name: "IMQACollectDeviceInfo",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.onycom.IMQACollectDeviceInfo",
                deploymentTargets: .iOS("13.0"),
                sources: ["Sources/IMQACollectDeviceInfo/**"],
                headers: .headers(public: "Sources/IMQACollectDeviceInfo/include/**/*.h"),
                dependencies: [],
                settings: .settings(base: [
                    "HEADER_SEARCH_PATHS": ["$(SRCROOT)/Sources/IMQACollectDeviceInfo/include"],
                    "MODULEMAP_FILE": "$(SRCROOT)/Sources/IMQACollectDeviceInfo/include/module.modulemap",
                    "SKIP_INSTALL": "NO",
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "DEAD_CODE_STRIPPING": "NO",
                    "LINK_WITH_STANDARD_LIBRARIES" : "NO",
                    "ONLY_ACTIVE_ARCH" : "NO",
                    "BUILD_DIR": "$(PROJECT_DIR)/Build"
                ])
               ),
        .target(name: "IMQAObjCUtilsInternal",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.onycom.IMQAObjCUtilsInternal",
                deploymentTargets: .iOS("13.0"),
                sources: ["Sources/IMQAObjCUtilsInternal/**"],
                headers: .headers(public: "Sources/IMQAObjCUtilsInternal/include/**/*.h"),
                dependencies: [],
                settings: .settings(base: [
                    "HEADER_SEARCH_PATHS": ["$(SRCROOT)/Sources/IMQAObjCUtilsInternal/include"],
                    "MODULEMAP_FILE": "$(SRCROOT)/Sources/IMQAObjCUtilsInternal/include/module.modulemap",
                    "SKIP_INSTALL": "NO",
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "DEAD_CODE_STRIPPING": "NO",
                    "LINK_WITH_STANDARD_LIBRARIES" : "NO",
                    "ONLY_ACTIVE_ARCH" : "NO",
                    "BUILD_DIR": "$(PROJECT_DIR)/Build"
                ])
               ),
        .target(name: "IMQACommonInternal",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.onycom.IMQACommonInternal",
                deploymentTargets: .iOS("13.0"),
                sources: ["Sources/IMQACommonInternal/**"],
                dependencies: [],
                settings: .settings(base: [
                    "SKIP_INSTALL": "NO",
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "DEAD_CODE_STRIPPING": "NO",
                    "LINK_WITH_STANDARD_LIBRARIES" : "NO",
                    "ONLY_ACTIVE_ARCH" : "NO",
                    "BUILD_DIR": "$(PROJECT_DIR)/Build"
                ])
               ),
        .target(name: "IMQAOtelInternal",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.onycom.IMQAOtelInternal",
                deploymentTargets: .iOS("13.0"),
                sources: ["Sources/IMQAOtelInternal/**"],
                dependencies: [],
                settings: .settings(base: [
                    "SKIP_INSTALL": "NO",
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "DEAD_CODE_STRIPPING": "NO",
                    "LINK_WITH_STANDARD_LIBRARIES" : "NO",
                    "ONLY_ACTIVE_ARCH" : "NO",
                    "BUILD_DIR": "$(PROJECT_DIR)/Build"
                ])
               ),
        
        .target(name: "IMQACore",
                destinations: .iOS,
                product: .staticFramework,
                bundleId: "com.onycom.IMQACore",
                deploymentTargets: .iOS("13.0"),
                sources: ["Sources/IMQACore/**/*.swift"],
//                resources: [.glob(pattern: Path.path("Sources/IMQACore/PrivacyInfo.xcprivacy"), excluding: [], tags: [], inclusionCondition: nil) ],
                resources: ["PrivacyInfo.xcprivacy"],
                dependencies: [
                    .target(name: "IMQACollectDeviceInfo"),
                    .target(name: "IMQAObjCUtilsInternal"),
                    .target(name: "IMQACommonInternal"),
                    .target(name: "IMQAOtelInternal"),
                ],
                settings: .settings(base: [
                    "OTHER_LDFLAGS": ["-lc++ -lz"],
                    "SKIP_INSTALL": "NO",
                    "BUILD_LIBRARY_FOR_DISTRIBUTION": "YES",
                    "DEAD_CODE_STRIPPING": "NO",
                    "LINK_WITH_STANDARD_LIBRARIES" : "NO",
                    "ONLY_ACTIVE_ARCH" : "NO",
                    "BUILD_DIR": "$(PROJECT_DIR)/Build"
                ])
               )
    ]
)
