# !usr/bin/bash


echo "starting..."

SOURCE_ROOT="/Users/yongrui/Desktop/Tweak"

BUILT_PRODUCTS_DIR="/Users/yongrui/Desktop/Tweak"

echo "$SOURCE_ROOT"

PP_CONFIG_PATH="PP_SIDELOADER_OPTIONS.plist"

PP_EXTERNAL_TWEAK_PATH="$SOURCE_ROOT/pptweak.zip"

OVERWRITE_ORIGINAL_APP=$(/usr/libexec/PlistBuddy -c "Print OVERWRITE_ORIGINAL_APP" "$PP_CONFIG_PATH")
echo "OVERWRITE_ORIGINAL_APP: $OVERWRITE_ORIGINAL_APP"

KEEP_ORIGINAL_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print KEEP_ORIGINAL_APP_NAME" "$PP_CONFIG_PATH")
echo "KEEP_ORIGINAL_APP_NAME: $KEEP_ORIGINAL_APP_NAME"

REMOVE_PLUGINS=$(/usr/libexec/PlistBuddy -c "Print REMOVE_PLUGINS" "$PP_CONFIG_PATH")
echo "REMOVE_PLUGINS: $REMOVE_PLUGINS"

EXPANDED_CODE_SIGN_IDENTITY="F7653878B397923A0BC390AAAE93D899D671226E"

#define some common paths
TEMP_PATH="$SOURCE_ROOT/temp"
echo "REMOVE_PLUGINS: $TEMP_PATH"

WORKING_DIR="$SOURCE_ROOT/working_dir"
echo "REMOVE_PLUGINS: $WORKING_DIR"

EXTRACTED_IPA_PATH="$TEMP_PATH/EXTRACTED_IPA"
echo "REMOVE_PLUGINS: $EXTRACTED_IPA_PATH"

rm -rf "$TEMP_PATH" || true
rm -rf "$WORKING_DIR" || true

mkdir -p "$TEMP_PATH" || true
mkdir -p "$WORKING_DIR" || true

#lets extract the IPA
echo "EXTRACTING IPA"
unzip -oqq "$SOURCE_ROOT/app.ipa" -d "$EXTRACTED_IPA_PATH"

#find the .app path
APP_PATH=$(set -- "$EXTRACTED_IPA_PATH/Payload/"*.app; echo "$1")
echo "FOUND APP PATH: $APP_PATH"

#define some common variables
TARGET_NAME="ppsideloader"

PP_TWEAK_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/pptweak.dylib"
HOOKED_APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$APP_PATH/Info.plist")

HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$APP_PATH/Info.plist")
HOOKED_APP_NAME="$HOOKED_APP_NAME ++"

HOOKED_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$APP_PATH/Info.plist")
HOOKED_EXE_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$HOOKED_EXECUTABLE"

PP_TWEAK_ZIP_PATH="$TEMP_PATH/pptweak.zip"
if [ -f $PP_EXTERNAL_TWEAK_PATH ]; then
    echo "USING PPTWEAK AT $PP_EXTERNAL_TWEAK_PATH"
    cp "$PP_EXTERNAL_TWEAK_PATH" "$PP_TWEAK_ZIP_PATH"
else
    echo "DOWNLOADING PPTWEAK FROM UNLIMAPPS"
    #lets download the pp tweak for the app located in root
    echo "DOWNLOADING PP TWEAK"
    curl -L "https://beta.unlimapps.com/ppsideloaded/$HOOKED_APP_BUNDLE_ID" -o "$PP_TWEAK_ZIP_PATH"
fi

#now we can unzip the tweak into working directory
echo "EXTRACTING PP TWEAK"
unzip -oqq "$PP_TWEAK_ZIP_PATH" -d "$WORKING_DIR"

#copy over the app contents
echo "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"
rm -rf "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app" || true
mkdir -p "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app" || true
cp -rf "$APP_PATH/" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"

#copy over all the dylibs
cp -rf "$WORKING_DIR/" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"

#lets make sure the HOOKED_EXE has correct permissions
if ! [[ -x "$HOOKED_EXE_PATH" ]]
then
    echo "EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
    chmod +x "$HOOKED_EXE_PATH"
else
    echo "EXE IS EXECUTABLE"
fi

#change the display name to ++
if [ "$KEEP_ORIGINAL_APP_NAME" != true ] ; then
    echo 'KEEP_ORIGINAL_APP_NAME IS NOT ENABLED'
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $HOOKED_APP_NAME" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/Info.plist"
fi

if [ "$OVERWRITE_ORIGINAL_APP" != true ] ; then
    echo 'PUSH IS NOT ENABLED'
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/Info.plist"
fi

#add the dylib
"$SOURCE_ROOT/insert_dylib" --all-yes --inplace --overwrite "@executable_path/pptweak.dylib" "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/$HOOKED_EXECUTABLE"

##add the correct entitlements
TEMP_PLIST="$TEMP_PATH/temp.plist"
REAL_CODE_SIGN_ENTITLEMENTS="$TEMP_PATH/app.entitlements"
security cms -D -i "/Users/yongrui/Desktop/efg.mobileprovision" -o "$TEMP_PLIST"
/usr/libexec/PlistBuddy -c "Print Entitlements" "$TEMP_PLIST" -x > "$REAL_CODE_SIGN_ENTITLEMENTS"
#
#sign all the executable binaries
for DYLIB in "$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/"*.dylib
do
    FILENAME=$(basename $DYLIB)
    echo "SIGNING: $FILENAME"
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$DYLIB" 
done

APP_PLUGINS_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/PlugIns"
if [ "$OVERWRITE_ORIGINAL_APP" != true ] || [ "$REMOVE_PLUGINS" == true ] ; then
    echo 'REMOVING IPA PLUGINS'
    #plugins cant be used on duplicate so lets just delete them
    rm -rf "$APP_PLUGINS_PATH" || true
fi

if [ -d "$APP_PLUGINS_PATH" ]; then
    for PLUGIN in "$APP_PLUGINS_PATH/"*.appex
    do
        #grab the plugin exe name
        #echo "PLUGIN: $PLUGIN"

        #if we don't care about push we can install it as an additional app
        PLUGIN_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN/Info.plist")
        echo "PLUGIN_ID: $PLUGIN_ID"

        PLUGIN_EXE=$PLUGIN/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN/Info.plist")
        echo "PLUGIN_EXE: $PLUGIN_EXE"

        #lets make sure the plugin has correct permissions
        if ! [[ -x "$PLUGIN_EXE" ]]
        then
            echo "PLUGIN_EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
            chmod +x "$PLUGIN_EXE"
        else
            echo "PLUGIN_EXE IS EXECUTABLE"
        fi

        #sign the extension
        echo "SIGNING: $PLUGIN_ID"
        /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$PLUGIN_EXE" 
#
        #we also need to sign and update the plist of any app inside the plugin
        for PLUGIN_APP in "$PLUGIN/"*.app
        do
            echo "PLUGIN_APP: $PLUGIN_APP"
            if [ -d "$PLUGIN_APP" ]; then
                PLUGIN_APP_EXE=$PLUGIN_APP/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN_APP/Info.plist")
                echo "PLUGIN_APP_EXE: $PLUGIN_APP_EXE"

                #lets make sure the plugin has correct permissions
                if ! [[ -x "$PLUGIN_APP_EXE" ]]
                then
                    echo "PLUGIN_APP_EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
                    chmod +x "$PLUGIN_APP_EXE"
                else
                    echo "PLUGIN_APP_EXE IS EXECUTABLE"
                fi

                PLUGIN_APP_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN_APP/Info.plist")
                echo "PLUGIN_APP_ID: $PLUGIN_APP_ID"

                #sign the extension
                echo "SIGNING: $PLUGIN_APP_ID"
                /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$PLUGIN_APP_EXE" 
            fi
        done
    done
fi

APP_FRAMEWORKS_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app/Frameworks"
if [ -d "$APP_FRAMEWORKS_PATH" ]; then
for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
do
    #sign the FRAMEWORK
    FILENAME=$(basename $FRAMEWORK)
    echo "SIGNING: $FILENAME WITH $EXPANDED_CODE_SIGN_IDENTITY"
#
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi

#make sure to add entitlements to the original app binary
echo "SIGNING: FINAL BINARY WITH $EXPANDED_CODE_SIGN_IDENTITY ENTITLEMENTS: $REAL_CODE_SIGN_ENTITLEMENTS"
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$HOOKED_EXE_PATH"

#cd "$EXTRACTED_IPA_PATH"
#ls
#zip -9r "built.ipa" Payload/ >/dev/null 2>&1
#cp -rf "built.ipa" "$SOURCE_ROOT"
#cd ..
#cd ..
#rm -rf "$TEMP_PATH" || true
#TEMP_PATH="$SOURCE_ROOT/temp"
#WORKING_DIR="${SRCROOT}/working_dir"
#EXTRACTED_IPA_PATH="$TEMP_PATH/EXTRACTED_IPA"
TEMP="/Users/yongrui/Desktop/Tweak/build_temp"
LOG_FILE="$TEMP/build.log"
PRODUCTS_CONTAINER="$SOURCE_ROOT/products"

mkdir -p "$TEMP"
echo "DONE BUILDING" >> "$LOG_FILE"

#find the .app path
APP_PATH="$(set -- $EXTRACTED_IPA_PATH/Payload/*.app; echo "$1")"
echo "FOUND APP PATH: $APP_PATH"

HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$APP_PATH/Info.plist")
echo "HOOKED_APP_NAME: $HOOKED_APP_NAME"
APP_IPA_FOLDER="$PRODUCTS_CONTAINER/$HOOKED_APP_NAME"
echo "APP_IPA_FOLDER: $APP_IPA_FOLDER"
#PRODUCT_SETTINGS_PATH
PP_CONFIG_PATH="$SOURCE_ROOT/PP_SIDELOADER_OPTIONS.plist"
echo "PP_CONFIG_PATH: $PP_CONFIG_PATH"

CREATE_IPA_FILES=$(/usr/libexec/PlistBuddy -c "Print CREATE_IPA_FILES" "$PP_CONFIG_PATH")
echo "CREATE_IPA_FILES: $CREATE_IPA_FILES"

if [ "$CREATE_IPA_FILES" = true ] ; then

#lets clear out IPA folder if one exists
rm -rf "$APP_IPA_FOLDER" || true

#create a new ipa tempalte
mkdir -p "$APP_IPA_FOLDER/Payload"

#copy .app to payload folder
PRODUCT_NAME="ppsideloader"
cp -rf "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app" "$APP_IPA_FOLDER/Payload"

#go into the app folder get ready to zip
cd "$APP_IPA_FOLDER"

#zip contents
/usr/bin/zip -r $PRODUCT_NAME.ipa Payload
mv $PRODUCT_NAME.ipa "$APP_IPA_FOLDER++.ipa"
rm -rf "$APP_IPA_FOLDER"

fi

#cleanup
rm -rf "$WORKING_DIR" || true
rm -rf "$TEMP_PATH" || true

exit 0
