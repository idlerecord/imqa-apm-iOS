# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'IMQACollectDeviceInfo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IMQACollectDeviceInfo

end

target 'IMQACommonInternal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IMQACommonInternal

end

target 'IMQACore' do
  use_frameworks! :linkage => :static

  # Pods for IMQACore
  pod 'KSCrash', '2.0.0-rc.8'
  pod 'OpenTelemetry-Swift-Sdk', '~> 1.12.1'
  pod 'OpenTelemetry-Swift-Api', '~> 1.12.1'
  pod 'SwiftProtobuf', '~> 1.28.2'
  pod 'MMKV', '~> 2.0.2'
end

target 'IMQAObjCUtilsInternal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IMQAObjCUtilsInternal

end

target 'IMQAOtelInternal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for IMQAOtelInternal

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_DIR'] = '../Build'
      config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -ObjC'
    end
  end
end
