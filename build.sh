#!/bin/bash

# 指定路径
BUILD_DIR="./Build"
SIMULATOR_DIR="$BUILD_DIR/Release-iphonesimulator"
DEVICE_DIR="$BUILD_DIR/Release-iphoneos"
OUTPUT_DIR="$BUILD_DIR/xcframework"
TARGET_DIR="$1"

# 检查文件夹是否存在
if [ -d "$SIMULATOR_DIR" ] && [ -d "$DEVICE_DIR" ]; then
    echo "Directories exist. Deleting all files inside..."
    # 删除目录下的所有文件（保留目录本身）
    rm -rf "$SIMULATOR_DIR"/* "$DEVICE_DIR"/*
else
    echo "Directories do not exist. Creating directories..."
    # 如果目录不存在，创建目录
    mkdir -p "$SIMULATOR_DIR" "$DEVICE_DIR"
fi

# 执行 xcodebuild 构建模拟器版本
echo "Building for iOS Simulator..."
xcodebuild -workspace IMQACore.xcworkspace -scheme IMQACore -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'

# 执行 xcodebuild 构建真机版本
echo "Building for iOS Device..."
xcodebuild -workspace IMQACore.xcworkspace -scheme IMQACore -configuration Release -sdk iphoneos -destination 'generic/platform=iOS'


# 删除 Pods_ 开头的 framework
echo "Removing Pods_ prefixed frameworks..."

find "$SIMULATOR_DIR" -maxdepth 1 -type d -name "Pods_*.framework" -exec rm -rf {} +
find "$DEVICE_DIR" -maxdepth 1 -type d -name "Pods_*.framework" -exec rm -rf {} +


# 查找并合并 framework 到 XCFramework
echo "Searching for frameworks to merge into XCFramework..."

# 检查文件夹是否存在
if [ -d "$OUTPUT_DIR" ]; then
    echo "Directories exist. Deleting all files inside..."
    # 删除目录下的所有文件（保留目录本身）
    rm -rf "$OUTPUT_DIR"/*
else
    echo "Directories do not exist. Creating directories..."
    # 如果目录不存在，创建目录
    mkdir -p "$OUTPUT_DIR"
fi

SIMULATOR_FRAMEWORKS=$(find "$SIMULATOR_DIR" -type d -name "*.framework")

for FRAMEWORK in $SIMULATOR_FRAMEWORKS; do
    FRAMEWORK_NAME=$(basename "$FRAMEWORK")
    
    # 查找 device 目录是否有对应的 framework（递归）
    DEVICE_FRAMEWORK_PATH=$(find "$DEVICE_DIR" -type d -name "$FRAMEWORK_NAME" | head -n 1)
    
    if [ -n "$DEVICE_FRAMEWORK_PATH" ]; then
        echo "Merging $FRAMEWORK_NAME into XCFramework..."
        xcodebuild -create-xcframework \
            -framework "$FRAMEWORK" \
            -framework "$DEVICE_FRAMEWORK_PATH" \
            -output "$OUTPUT_DIR/${FRAMEWORK_NAME%.framework}.xcframework"
            
        echo "✅ Created: $OUTPUT_DIR/${FRAMEWORK_NAME%.framework}.xcframework"
    fi
done

# 📌 复制 PrivacyInfo.xcprivacy 到 XCFramework 里的 framework 目录
echo "Copying PrivacyInfo.xcprivacy to IMQACore.xcframework..."

# 指定 PrivacyInfo.xcprivacy 的源文件（从 Release-iphoneos 目录复制）
PRIVACY_FILE="./Sources/IMQACore/PrivacyInfo.xcprivacy"

if [ -f "$PRIVACY_FILE" ]; then
    echo "✅ Found PrivacyInfo.xcprivacy in $DEVICE_DIR"

    # 递归查找 IMQACore.xcframework 目录下所有 IMQACore.framework 并复制
    find "$OUTPUT_DIR/IMQACore.xcframework" -type d -name "IMQACore.framework" | while read -r framework_dir; do
        echo "📂 Copying to: $framework_dir"
        cp "$PRIVACY_FILE" "$framework_dir/"
    done

    echo "✅ PrivacyInfo.xcprivacy copied successfully!"
else
    echo "❌ Error: PrivacyInfo.xcprivacy not found in $DEVICE_DIR"
fi


# 📌 检查输出目录的 xcframework 是否存在
if [ -d "$OUTPUT_DIR" ]; then
    # 📌 替换指定目录的 xcframework（仅当目标目录存在时）
    if [ -d "$TARGET_DIR" ]; then
        echo "Removing old xcframework in $TARGET_DIR..."
        rm -rf "$TARGET_DIR"
        
            # 复制新的 xcframework 目录到目标位置
        echo "Copying new xcframework to $TARGET_DIR..."
        cp -R "$OUTPUT_DIR/" "$TARGET_DIR/"

        echo "✅ Successfully replaced xcframework in $TARGET_DIR!"
    else
        echo "❌ Please enter a valid address"
    fi

else
    echo "⚠️ The generated xcframework does not exist in $OUTPUT_DIR."
fi

echo "✅ Build and copy process completed!"
