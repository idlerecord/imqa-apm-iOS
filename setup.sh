#/bin/sh
echo "✅Delete ~/Library/Developer/Xcode/DerivedData"
rm -rf "~/Library/Developer/Xcode/DerivedData"

echo "✅Tuist clean"
tuist clean

echo "✅Delete files <.xcodeproj><.xcworkspace>"
rm -rf "./*.xcodeproj" "./*.xcworkspace"

echo "✅tuist generate"
tuist generate

echo "✅pod install"
pod install

echo "🎉setup completed"
