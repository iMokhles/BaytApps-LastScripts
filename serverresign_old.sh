# !/bin/bash

AppIPA="$1"
CertNAME="$2"
ProfilePATH="$3"
OutPATH="$4"
SERVERURL="$5"
DUPLINumber="$6"
AppFolder="$7"
AppNewName="$8"
AppNewIconURL="$9"

for (( dupNUM=1; dupNUM<=DUPLINumber; dupNUM++ ))
do

  	DEFAULT_ENTITLEMENTS="/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/app.entitlements"
	DECODER_PATH="/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/Tools/mpdecoder"
	LOG_FILE="/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/AppDistrubtion.log"

	OUTPUT_PATH="$OutPATH"
	WORKING_PATH="$OutPATH/WorkingPath"
	EXTRACTED_IPA_PATH="$WORKING_PATH/EXTRACTED_IPA"
	TEMP_PATH="$OutPATH/temp"
	ICONS_TEMP_PATH="$OutPATH/temp/icons"

	
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
	/usr/local/Cellar/wget/1.18/bin/wget $AppNewIconURL -O "$TEMP_PATH/appIcon.png"
/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/icon_generator.sh "$TEMP_PATH/appIcon.png" "$ICONS_TEMP_PATH"


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
	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH" "$APP_PATH/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :bundleDisplayName $AppNewName$dupNUM" "$EXTRACTED_IPA_PATH/iTunesMetadata.plist"
	

	# echo "[   ] Add the correct entitlements"
	# TEMP_PLIST="$TEMP_PATH/temp.plist"
	# REAL_CODE_SIGN_ENTITLEMENTS="$TEMP_PATH/app.entitlements"
	# # cp $DEFAULT_ENTITLEMENTS $REAL_CODE_SIGN_ENTITLEMENTS

	# echo "[   ] Gettings entitlements from profile"
	# $DECODER_PATH -f $ProfilePATH -o "/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/tempEnt.plist"
 #  echo "[   ] Setting entitlements to plist"
	# /usr/libexec/PlistBuddy -x -c "Print Entitlements" "/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/tempEnt.plist"  > "$DEFAULT_ENTITLEMENTS"
 #  cp $DEFAULT_ENTITLEMENTS $REAL_CODE_SIGN_ENTITLEMENTS

	# echo "[   ] sign all the executable binaries"
	# for DYLIB in "$APP_PATH/"*.dylib
	# do
	# 	FILENAME=$(basename $DYLIB)
	# 	echo "SIGNING: $FILENAME"
 #    	security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 	codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain --force --sign "$CertNAME" "$DYLIB"
	# done

	# echo "SIGNING: $FILENAME"
 #    security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain --force --sign "$CertNAME" "$APP_PATH/patch"

	# APP_PLUGINS_PATH="$APP_PATH/PlugIns"
	# # rm -rf APP_PLUGINS_PATH

	# if [ -d "$APP_PLUGINS_PATH" ]; then
	# 	for PLUGIN in "$APP_PLUGINS_PATH/"*.appex
	# 	do
	# 		#grab the plugin exe name
	# 		echo "PLUGIN: $PLUGIN"

	# 		#if we don't care about push we can install it as an additional app
	# 		PLUGIN_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN/Info.plist")
	# 		echo "PLUGIN_ID: $PLUGIN_ID"

	# 		PLUGIN_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$PLUGIN/Info.plist")
	# 		PLUGIN_EXE=$PLUGIN/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN/Info.plist")

	# 		# MinimumOSVersion

	# 		filenamePLUG=$(basename "$PLUGIN_EXE")
	# 		extensionPLUG="${filenamePLUG##*.}"
	# 		filenamePLUG="${filenamePLUG%.*}"

	# 		/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:0 integer 1" "$PLUGIN/Info.plist"
	# 		/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:1 integer 2" "$PLUGIN/Info.plist"
	# 		/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 8.0" "$PLUGIN/Info.plist"
	# 		/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $filenamePLUG-$dupNUM" "$PLUGIN/Info.plist"
	# 		/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH.$filenamePLUG" "$PLUGIN/Info.plist"

	# 		/usr/libexec/PlistBuddy -c "Set :NSExtension:NSExtensionAttributes:WKAppBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH.$filenamePLUG" "$PLUGIN/Info.plist"

	# 		cp $ProfilePATH "$PLUGIN/embedded.mobileprovision"

	# 		echo "PLUGIN_EXE: $PLUGIN_EXE"

	# 		#sign the extension
 #      		security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 		codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$PLUGIN_EXE"

	# 	done

	# 	for PLUGIN_APP in "$APP_PLUGINS_PATH/"*.app
	# 	do
	# 		#grab the plugin exe name
	# 		echo "PLUGIN_APP: $PLUGIN_APP"

	# 		#if we don't care about push we can install it as an additional app
	# 		PLUGIN_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$PLUGIN_APP/Info.plist")
	# 		echo "PLUGIN_ID: $PLUGIN_ID"

	# 		PLUGIN_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$PLUGIN_APP/Info.plist")
	# 		PLUGIN_EXE=$PLUGIN_APP/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$PLUGIN_APP/Info.plist")

	# 		filenamePLUG=$(basename "$PLUGIN_EXE")
	# 		extensionPLUG="${filenamePLUG##*.}"
	# 		filenamePLUG="${filenamePLUG%.*}"

	# 		/usr/libexec/PlistBuddy -c "Set :WKCompanionAppBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH.$filenamePLUG" "$PLUGIN_APP/Info.plist"

	# 		cp $ProfilePATH "$PLUGIN_APP/embedded.mobileprovision"

	# 		echo "PLUGIN_EXE: $PLUGIN_EXE"

	# 		#sign the extension
 #      		security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 		codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$PLUGIN_EXE"

	# 	done
	# fi

	# APP_WATCH_PATH="$APP_PATH/Watch"
	# if [ -d "$APP_WATCH_PATH" ]; then
	# 	for WATCH_APP in "$APP_WATCH_PATH/"*.app
	# 	do
	# 		#grab the plugin exe name
	# 		echo "WATCH_APP: $WATCH_APP"

	# 		#if we don't care about push we can install it as an additional app
	# 		WATCH_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$WATCH_APP/Info.plist")
	# 		echo "WATCH_ID: $WATCH_ID"

	# 		WATCH_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$WATCH_APP/Info.plist")
	# 		WATCH_EXE=$WATCH_APP/$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$WATCH_APP/Info.plist")

	# 		filenamePLUG=$(basename "$WATCH_EXE")
	# 		extensionPLUG="${filenamePLUG##*.}"
	# 		filenamePLUG="${filenamePLUG%.*}"

	# 		/usr/libexec/PlistBuddy -c "Set :WKCompanionAppBundleIdentifier $HOOKED_APP_BUNDLE_ID-$CURRENT_TIME_EPOCH.$filenamePLUG" "$WATCH_APP/Info.plist"

	# 		cp $ProfilePATH "$WATCH_APP/embedded.mobileprovision"

	# 		echo "WATCH_EXE: $WATCH_EXE"

	# 		#sign the extension
 #      		security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 		codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$WATCH_EXE"

	# 	done
	# fi
	# APP_FRAMEWORKS_PATH="$APP_PATH/Frameworks"
	# if [ -d "$APP_FRAMEWORKS_PATH" ]; then
	# 	for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
	# 	do
	# 		#grab the framework name
	# 		echo "FRAMEWORK: $FRAMEWORK"
	# 		#sign the FRAMEWORK

	# 		/usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 8.0" "$FRAMEWORK/Info.plist"
 #      security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 		codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" "$FRAMEWORK"
	# 	done
	# fi

	# APP_FRAMEWORKS_PATH="$APP_PATH/Toolchain/lib"
	# if [ -d "$APP_FRAMEWORKS_PATH" ]; then
	# 	for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
	# 	do
	# 		#grab the framework name
	# 		echo "FRAMEWORK: $FRAMEWORK"
	# 		# the FRAMEWORK
 #      security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# 		codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" "$FRAMEWORK"
	# 	done
	# fi

	# echo "[   ] sign app"
	# cp "$ProfilePATH" "$APP_PATH/embedded.mobileprovision"
 #  	security unlock-keychain -p TotoaTEAM2016 "/Users/TotoaTEAM/Library/Keychains/login.keychain"
	# codesign --keychain /Users/TotoaTEAM/Library/Keychains/login.keychain -fs "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$HOOKED_EXE_PATH"

	echo "[   ] Create distrubtion.plist"
	OTA_PLIST="/Library/Server/Web/Data/Sites/cloud.baytapps.me/files_store/accounts/scripts_shs/manifest.plist"
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


	/usr/libexec/PlistBuddy -c "Add :items array" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Delete :items: dict" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Add :items: dict" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Add :items:0:assets array" $OTA_MODIFIED_PLIST_PATH

	/usr/libexec/PlistBuddy -c "Add :items:0:assets:0 dict" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:kind string" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:kind software-package" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Add :items:0:assets:0:url string" $OTA_MODIFIED_PLIST_PATH
	/usr/libexec/PlistBuddy -c "Set :items:0:assets:0:url $SERVERURL/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" $OTA_MODIFIED_PLIST_PATH

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
	zip -9r "$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" Payload/ >/dev/null 2>&1
	cd ../../
	cp "$EXTRACTED_IPA_PATH/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa" "$OUTPUT_PATH/ipa"

	rm -rf "$WORKING_PATH" || true
	rm -rf "$TEMP_PATH" || true

	echo "$dupNUM ***** dupNUM"
	echo "$DUPLINumber **** DUPLINumber"

	if [ "$dupNUM" -eq "$DUPLINumber" ];then

		echo "URL_TO_INSTALL_APP=itms-services://?action=download-manifest&url=$SERVERURL/Plist/$HOOKED_APP_BUNDLE_ID-$dupNUM.plist=LAST_PART_INSTALL_LINK^^^^$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM.ipa^^^^$OUTPUT_PATH/ipa/$HOOKED_APP_BUNDLE_ID-$dupNUM"
		rm $AppIPA
	fi
done
