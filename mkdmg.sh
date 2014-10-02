#!/bin/sh
set -e 

VOLNAME=Vocabulist
APPNAME=Vocabulist
TARGET_BUILD_DIR=$(PWD)/build/Release
VERSION=`grep -A 1 CFBundleShortVersionString Vocabulist/Vocabulist-Info.plist | tail -1 | sed 's/[^0-9]*>//' | sed 's/<.*//'`

rm -Rf build
xcodebuild -configuration Release -alltargets

if [ -e "/Volumes/$VOLNAME" ]; then
	echo "Detaching old $VOLNAME"
	hdiutil detach "/Volumes/$VOLNAME"
fi

rm -f "$TARGET_BUILD_DIR/$VOLNAME.dmg" "$TARGET_BUILD_DIR/${VOLNAME}_big.dmg"

# create/attach dmg for distribution
echo "Creating blank DMG"

hdiutil create -size 15000k -volname "$VOLNAME" -attach -fs HFS+ "$TARGET_BUILD_DIR/${VOLNAME}_big.dmg"

cp -R "$TARGET_BUILD_DIR/$APPNAME.app" "/Volumes/$VOLNAME/"

sign="Mac Developer: Oleksandr Tymoshenko (JVN4Z6SEGD)"

echo --sign app--
codesign --preserve-metadata=identifier,entitlements,resource-rules,requirements --force --deep --verify --verbose --sign "$sign" "/Volumes/$VOLNAME/$APPNAME.app"
ls -la "/Volumes/$VOLNAME/"

codesign --deep-verify --display -vvv "/Volumes/$VOLNAME/$APPNAME.app"

hdiutil detach "/Volumes/$VOLNAME"

echo "Compresing disk image"
rm -f "$APPNAME-$VERSION.dmg"
hdiutil convert -format UDZO -o "$APPNAME-$VERSION.dmg" "$TARGET_BUILD_DIR/${VOLNAME}_big.dmg"

rm -f "$TARGET_BUILD_DIR/${VOLNAME}_big.dmg"
