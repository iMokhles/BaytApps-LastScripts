# !/bin/bash

AppIPA="$1"
CertNAME="$2"
ProfilePATH="$3"
OutPATH="$4"
SERVERURL="$5"
DUPLINumber="$6"
ISTWEAK="$7"
AppNewName="$8"
AppNewIconURL="$9"

for (( dupNUM=1; dupNUM<=DUPLINumber; dupNUM++ ))
do

DEFAULT_ENTITLEMENTS="/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/app.entitlements"
DECODER_PATH="/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/Tools/mpdecoder"
LOG_FILE="/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/AppDistrubtion.log"

SOURCE_ROOT="/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs"
ServerDownURL="https://cloud.baytapps.net/api/v1/index.php?downloadipa="
#    BUILT_PRODUCTS_DIR="$SOURCE_ROOT"

PP_CONFIG_PATH="$SOURCE_ROOT/PP_SIDELOADER_OPTIONS.plist"

PP_EXTERNAL_TWEAK_PATH="$SOURCE_ROOT/pptweak.zip"

OVERWRITE_ORIGINAL_APP=$(/usr/libexec/PlistBuddy -c "Print OVERWRITE_ORIGINAL_APP" "$PP_CONFIG_PATH")

echo "OVERWRITE_ORIGINAL_APP: $OVERWRITE_ORIGINAL_APP"

KEEP_ORIGINAL_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print KEEP_ORIGINAL_APP_NAME" "$PP_CONFIG_PATH")

echo "KEEP_ORIGINAL_APP_NAME: $KEEP_ORIGINAL_APP_NAME"

REMOVE_PLUGINS=$(/usr/libexec/PlistBuddy -c "Print REMOVE_PLUGINS" "$PP_CONFIG_PATH")

echo "REMOVE_PLUGINS: $REMOVE_PLUGINS"

EXPANDED_CODE_SIGN_IDENTITY="$CertNAME"




OUTPUT_PATH="$OutPATH"
WORKING_PATH="$OutPATH/WorkingPath"
EXTRACTED_IPA_PATH="$WORKING_PATH/EXTRACTED_IPA"
TEMP_PATH="$OutPATH/temp"
ICONS_TEMP_PATH="$OutPATH/temp/icons"
WORKING_DIR="$OutPATH/working_dir"

echo "OUTPUT_PATH: $OUTPUT_PATH"


echo "[   ] Checking Working Paths"

CURRENT_TIME_EPOCH=$(date +"%s")

if [ -d "$TEMP_PATH" ];then
rm -Rf "$TEMP_PATH"
fi
mkdir -p "$TEMP_PATH" || true

if [ -d "$ICONS_TEMP_PATH" ];then
rm -Rf "$ICONS_TEMP_PATH"
fi
mkdir -p "$ICONS_TEMP_PATH" || true


if [ -d "$EXTRACTED_IPA_PATH" ];then
rm -Rf "$EXTRACTED_IPA_PATH"
fi
mkdir -p "$EXTRACTED_IPA_PATH" || true

if [ -d "$OUTPUT_PATH" ];then
echo "Folder already exist"
else
mkdir -p "$OUTPUT_PATH" || true
fi


echo "[   ] Creating App Icons"
/usr/local/Cellar/wget/1.19.1/bin/wget $AppNewIconURL -O "$TEMP_PATH/appIcon.png"
/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/icon_generator.sh "$TEMP_PATH/appIcon.png" "$ICONS_TEMP_PATH"


echo "[   ] Extracting IPA"

# wget $AppIPA -o $OutPATH/$AppFileName

echo "*** $AppIPA"
unzip -oqq "$AppIPA" -d "$EXTRACTED_IPA_PATH"

echo "[   ] Getting App Name and ID"
APP_PATH=$(set -- "$EXTRACTED_IPA_PATH/Payload/"*.app; echo "$1")
echo "FOUND APP PATH: $APP_PATH"
HOOKED_APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$APP_PATH/Info.plist")
HOOKED_APP_BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion"  "$APP_PATH/Info.plist")
val=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$APP_PATH/Info.plist" 2>/dev/null)
# Save the exit code, which indicates success v. failure
exitCode=$?

if (( exitCode == 0 )); then
HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$APP_PATH/Info.plist")
else
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string" "$APP_PATH/Info.plist"
HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName"  "$APP_PATH/Info.plist")
fi

# iphone icons
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles array" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0 $(basename $ICONS_TEMP_PATH/Icon-60)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:1 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:1 $(basename $ICONS_TEMP_PATH/Icon-small-40)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:2 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:2 $(basename $ICONS_TEMP_PATH/Icon-small)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:3 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:3 $(basename $ICONS_TEMP_PATH/Icon)" "$APP_PATH/Info.plist"


# ipad icons
/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles array" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:0 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:0 $(basename $ICONS_TEMP_PATH/Icon-60)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:1 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:1 $(basename $ICONS_TEMP_PATH/Icon-small-40)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:2 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:2 $(basename $ICONS_TEMP_PATH/Icon-small)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:3 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:3 $(basename $ICONS_TEMP_PATH/Icon)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:4 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:4 $(basename $ICONS_TEMP_PATH/Icon-72)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:5 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:5 $(basename $ICONS_TEMP_PATH/Icon-76)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:6 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:6 $(basename $ICONS_TEMP_PATH/Icon-83.5)" "$APP_PATH/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:7 string" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:7 $(basename $ICONS_TEMP_PATH/Icon-small-50)" "$APP_PATH/Info.plist"


echo "[   ] Copying App Icons"
cp "$ICONS_TEMP_PATH/"*.png "$APP_PATH/"


HOOKED_APP_BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName"  "$APP_PATH/Info.plist")
HOOKED_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$APP_PATH/Info.plist")
HOOKED_EXE_PATH="$APP_PATH/$HOOKED_EXECUTABLE"

filename=$(basename "$HOOKED_EXE_PATH")
extension="${filename##*.}"
filename="${filename%.*}"

HOOKED_APP_BUNDLE_NAME="$HOOKED_APP_BUNDLE_NAME"
HOOKED_APP_BUNDLE_NAME=${HOOKED_APP_BUNDLE_NAME// /_}

HOOKED_APP_NAME="$HOOKED_APP_NAME"
HOOKED_APP_NAME=${HOOKED_APP_NAME// /_}


echo "[   ] Make App Binary Executable"

if ! [[ -x "$HOOKED_EXE_PATH" ]]; then
echo "EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
chmod +x "$HOOKED_EXE_PATH"
else
echo "EXE IS EXECUTABLE"
fi

/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:0 integer 1" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:1 integer 2" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 8.0" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $AppNewName$dupNUM" "$APP_PATH/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $AppNewName$dupNUM" "$APP_PATH/Info.plist"
#compareNUM="1"

#if [ "$DUPLINumber" == "$compareNUM" ];then
#echo "number 1"
#else
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH" "$APP_PATH/Info.plist"
//fi

#/usr/libexec/PlistBuddy -c "Set :bundleDisplayName $AppNewName$dupNUM" "$EXTRACTED_IPA_PATH/iTunesMetadata.plist"
compareTEXT="YES"
if [ "$ISTWEAK" == "$compareTEXT" ];then

echo "**************************this is tweak app**********"
echo "**************************$ISTWEAK**********"
TARGET_NAME="ppsideloader"

PP_TWEAK_PATH="$APP_PATH/pptweak.dylib"

PP_TWEAK_ZIP_PATH="$TEMP_PATH/pptweak.zip"

if [ -f $PP_EXTERNAL_TWEAK_PATH ]; then
echo "USING PPTWEAK AT $PP_EXTERNAL_TWEAK_PATH"
cp "$PP_EXTERNAL_TWEAK_PATH" "$PP_TWEAK_ZIP_PATH"
else
echo "DOWNLOADING PPTWEAK FROM UNLIMAPPS"
#   lets download the pp tweak for the app located in root
echo "DOWNLOADING PP TWEAK"
curl -L "https://beta.unlimapps.com/ppsideloaded/$HOOKED_APP_BUNDLE_ID" -o "$PP_TWEAK_ZIP_PATH"
fi
echo "EXTRACTING PP TWEAK"
unzip -oqq "$PP_TWEAK_ZIP_PATH" -d "$WORKING_DIR"

cp -rf "$WORKING_DIR/" "$APP_PATH"

"$SOURCE_ROOT/insert_dylib" --all-yes --inplace --overwrite "@executable_path/pptweak.dylib" "$APP_PATH/$HOOKED_EXECUTABLE"

for DYLIB in "$APP_PATH/"*.dylib
do
FILENAME=$(basename $DYLIB)
echo "SIGNING: $FILENAME"
security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" "$DYLIB"
done

fi

#
#TEMP_PLIST="$TEMP_PATH/temp.plist"
#
#REAL_CODE_SIGN_ENTITLEMENTS="$TEMP_PATH/app.entitlements"
#
#security find-identity -p codesigning -v login.keychain
#
#sudo security cms -D -i "$ProfilePATH" -o "$TEMP_PLIST"
#
#
#/usr/libexec/PlistBuddy -c "Print Entitlements" "$TEMP_PLIST" -x > "$REAL_CODE_SIGN_ENTITLEMENTS"
#
##sign all the executable binaries
#
#for DYLIB in "$APP_PATH/"*.dylib
#do
#FILENAME=$(basename $DYLIB)
#echo "SIGNING: $FILENAME"
#security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
#/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" "$DYLIB"
#done
#
APP_PLUGINS_PATH="$APP_PATH/PlugIns"
if [ "$OVERWRITE_ORIGINAL_APP" != true ] || [ "$REMOVE_PLUGINS" == true ] ; then
echo 'REMOVING IPA PLUGINS'
#plugins cant be used on duplicate so lets just delete them
rm -rf "$APP_PLUGINS_PATH" || true
fi
#
#if [ -d "$APP_PLUGINS_PATH" ]; then
#for PLUGIN in "$APP_PLUGINS_PATH/"*.appex
#do
##grab the plugin exe name
##echo "PLUGIN: $PLUGIN"
#
##if we don't care about push we can install it as an additional app
#PLUGIN_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN/Info.plist")
#echo "PLUGIN_ID: $PLUGIN_ID"
#
#PLUGIN_EXE=$PLUGIN/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN/Info.plist")
#echo "PLUGIN_EXE: $PLUGIN_EXE"
#
##lets make sure the plugin has correct permissions
#if ! [[ -x "$PLUGIN_EXE" ]]
#then
#echo "PLUGIN_EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
#chmod +x "$PLUGIN_EXE"
#else
#echo "PLUGIN_EXE IS EXECUTABLE"
#fi
#
##sign the extension
#echo "SIGNING: $PLUGIN_ID"
#
#security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
#/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" "$PLUGIN_EXE"
##
##we also need to sign and update the plist of any app inside the plugin
#for PLUGIN_APP in "$PLUGIN/"*.app
#do
#echo "PLUGIN_APP: $PLUGIN_APP"
#if [ -d "$PLUGIN_APP" ]; then
#PLUGIN_APP_EXE=$PLUGIN_APP/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN_APP/Info.plist")
#echo "PLUGIN_APP_EXE: $PLUGIN_APP_EXE"
#
##lets make sure the plugin has correct permissions
#if ! [[ -x "$PLUGIN_APP_EXE" ]]
#then
#echo "PLUGIN_APP_EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
#chmod +x "$PLUGIN_APP_EXE"
#else
#echo "PLUGIN_APP_EXE IS EXECUTABLE"
#fi
#
#PLUGIN_APP_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN_APP/Info.plist")
#echo "PLUGIN_APP_ID: $PLUGIN_APP_ID"
#
##sign the extension
#echo "SIGNING: $PLUGIN_APP_ID"
##/usr/bin/codesign ${VERBOSE} ${KEYCHAIN_FLAG} -f -s "$CertNAME" "$PLUGIN_APP_EXE"
#security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
#/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" "$PLUGIN_APP_EXE"
#fi
#done
#done
#fi
#
#APP_FRAMEWORKS_PATH="$APP_PATH/Frameworks"
#if [ -d "$APP_FRAMEWORKS_PATH" ]; then
#for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
#do
##sign the FRAMEWORK
#FILENAME=$(basename $FRAMEWORK)
#echo "SIGNING: $FILENAME WITH $CertNAME"
##
##/usr/bin/codesign ${VERBOSE} ${KEYCHAIN_FLAG} -f -s "$CertNAME" "$FRAMEWORK"
#security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
#/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" "$FRAMEWORK"
#done
#fi
#
##make sure to add entitlements to the original app binary
#echo "SIGNING: FINAL BINARY WITH $CertNAME ENTITLEMENTS: $REAL_CODE_SIGN_ENTITLEMENTS"
##/usr/bin/codesign --force --sign ${VERBOSE} ${KEYCHAIN_FLAG} -f -s "$CertNAME"  --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$HOOKED_EXE_PATH"
#security unlock-keychain -p asd123 "/Users/administrator/Library/Keychains/login.keychain"
#/usr/bin/codesign --keychain /Users/administrator/Library/Keychains/login.keychain --force --sign "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$HOOKED_EXE_PATH"
#
#cp "$ProfilePATH" "$APP_PATH/embedded.mobileprovision"
##  	security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"

echo "[   ] Create distrubtion.plist"
OTA_PLIST="/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/manifest.plist"
OTA_PLIST_PATH="$OutPATH/Plist/"
OTA_IPA_PATH="$OutPATH/ipa/"
OTA_IMG_PATH="$OutPATH/img/"

if [ -d "$OTA_PLIST_PATH" ];then
echo "plist path already exist"
else
mkdir -p "$OTA_PLIST_PATH" || true
fi

if [ -d "$OTA_IPA_PATH" ];then
echo "ipa path already exist"
else
mkdir -p "$OTA_IPA_PATH" || true
fi

if [ -d "$OTA_IMG_PATH" ];then
echo "img path already exist"
else
mkdir -p "$OTA_IMG_PATH" || true
fi

appIcon="$TEMP_PATH/appIcon.png"
cp "$appIcon" "$OutPATH/img/$HOOKED_APP_BUNDLE_ID.png"

OTA_MODIFIED_PLIST_PATH="$OutPATH/Plist/$HOOKED_APP_BUNDLE_ID-$dupNUM.plist"
# cp "$OTA_PLIST" "$OTA_MODIFIED_PLIST_PATH"


echo "-----------------------------------------------------------------------------------------"
echo "$ServerDownURL"

echo "${10}"
MadeLink="${10}"

echo "$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa"

echo "$ServerDownURL/${10}ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa"

echo "--------------------------------------------------------------------------------------------"

/usr/libexec/PlistBuddy -c "Add :items array" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Delete :items: dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items: dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets array" $OTA_MODIFIED_PLIST_PATH

/usr/libexec/PlistBuddy -c "Add :items:0:assets:0 dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:kind string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:kind software-package" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:url string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:url $ServerDownURL/${10}ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" $OTA_MODIFIED_PLIST_PATH

/usr/libexec/PlistBuddy -c "Add :items:0:assets:1 dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:1:kind string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:1:kind display-image" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:1:url string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:1:url $SERVERURL/img/$HOOKED_APP_BUNDLE_ID.png" $OTA_MODIFIED_PLIST_PATH

/usr/libexec/PlistBuddy -c "Add :items:0:assets:2 dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:2:kind string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:2:kind full-size-image" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:assets:2:url string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:assets:2:url $SERVERURL/img/$HOOKED_APP_BUNDLE_ID.png" $OTA_MODIFIED_PLIST_PATH

/usr/libexec/PlistBuddy -c "Add :items:0:metadata dict" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-identifier string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-identifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-version string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-version $HOOKED_APP_BUNDLE_VERSION" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:kind string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:kind software" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Add :items:0:metadata:title string" $OTA_MODIFIED_PLIST_PATH
/usr/libexec/PlistBuddy -c "Set :items:0:metadata:title $AppNewName$dupNUM" $OTA_MODIFIED_PLIST_PATH

echo "[   ] archive app"
cd $EXTRACTED_IPA_PATH
zip -qry "$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" Payload/ >/dev/null 2>&1
cd ../../

echo "$EXTRACTED_IPA_PATH/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa"
echo "$OUTPUT_PATH/ipa"
cp "$EXTRACTED_IPA_PATH/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" "$OUTPUT_PATH/ipa"

#/Users/administrator/.fastlane/bin/fastlane sigh resign "$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" --signing_identity "$CertNAME"  -p "$ProfilePATH"

echo "**************************External Sign**********"

/Library/Server/Web/Data/Sites/Default/files_store/scripts_shs/resign.sh "$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" "$CertNAME" -p "$ProfilePATH" "$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa"
echo "**************************Done**********"

#fastlane sigh resign /Library/Server/Web/Data/Sites/API/storage/baytapps/app.ipa --signing_identity "iPhone Developer: Ahmed AlNeaimy (6YGS8CPEKQ)" -p  /Library/Server/Web/Data/Sites/API/storage/profiles/ahmed.alneaimy88.2@gmail.com/FXD6FU8732/1496662150.mobileprovision
#fastlane sigh resign /Library/Server/Web/Data/Sites/API/storage/baytapps/app.ipa --signing_identity 'iPhone Developer: Ahmed AlNeaimy (6YGS8CPEKQ)' -p /Library/Server/Web/Data/Sites/API/storage/profiles/ahmed.alneaimy88.2@gmail.com/FXD6FU8732/1496662150.mobileprovision



rm -rf "$WORKING_PATH" || true
rm -rf "$TEMP_PATH" || true
rm -rf "$WORKING_DIR" || true
#echo "$dupNUM ***** dupNUM"
#echo "$DUPLINumber **** DUPLINumber"




if [ "$dupNUM" -eq "$DUPLINumber" ];then

echo "URL_TO_INSTALL_APP=itms-services://?action=download-manifest&url=$SERVERURL/Plist/$HOOKED_APP_BUNDLE_ID-$dupNUM.plist=LAST_PART_INSTALL_LINK^^^^$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa^^^^$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM"
rm $AppIPA
fi
done
