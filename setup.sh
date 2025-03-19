#/bin/sh
set -e
echo "✅Delete ~/Library/Developer/Xcode/DerivedData"
rm -rf "~/Library/Developer/Xcode/DerivedData"

echo "✅Tuist clean"
#tuist clean
/Users/huntapark/.local/share/mise/installs/tuist/4.41.0/bin/tuist clean

echo "✅Delete files <.xcodeproj><.xcworkspace>"
rm -rf "./*.xcodeproj" "./*.xcworkspace"

echo "✅tuist generate"
#tuist generate
/Users/huntapark/.local/share/mise/installs/tuist/4.41.0/bin/tuist generate

echo "✅pod install"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
#pod install
/Users/huntapark/.rbenv/shims/pod install

echo "🎉setup completed"
