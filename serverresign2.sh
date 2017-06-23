# !/bin/bash

AppIPA="$1"
CertNAME="$2"
ProfilePATH="$3"
OutPATH="$4"
SERVERURL="$5"
APPLICATION_ID="$6"

for (( dupNUM=1; dupNUM<=1; dupNUM++ ))
do

DEFAULT_ENTITLEMENTS="./app.entitlements"
DECODER_PATH="./Tools/mpdecoder"

OUTPUT_PATH="$OutPATH"
WORKING_PATH="$OutPATH/WorkingPath"
EXTRACTED_IPA_PATH="$WORKING_PATH/EXTRACTED_IPA"
TEMP_PATH="$OutPATH/temp"


echo ""
echo "[   ] App Distrubtion Generator v0.1"
echo "[   ] by Mokhlas Hussein / @iMokhles"
echo "[   ] GitHub: https://github.com/iMokhles"
echo ""
echo "[   ] Checking Working Paths"

	if [ -d "$TEMP_PATH" ];then
		sudo rm -Rf "$TEMP_PATH"
	fi
		sudo mkdir -p "$TEMP_PATH" || true

	if [ -d "$EXTRACTED_IPA_PATH" ];then
		sudo rm -Rf "$EXTRACTED_IPA_PATH"
	fi
		sudo mkdir -p "$EXTRACTED_IPA_PATH" || true

	if [ -d "$OUTPUT_PATH" ];then
		echo "Folder already exist"
	else
		sudo mkdir -p "$OUTPUT_PATH" || true
	fi

	echo "[   ] Extracting IPA"

	sudo unzip -oqq "$AppIPA" -d "$EXTRACTED_IPA_PATH"

	echo "[   ] Getting App Name and ID"
	APP_PATH=$(set -- "$EXTRACTED_IPA_PATH/Payload/"*.app; echo "$1")
	echo "FOUND APP PATH: $APP_PATH"

	HOOKED_APP_BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString"  "$APP_PATH/Info.plist")
	echo "FOUND HOOKED_APP_BUNDLE_VERSION: $HOOKED_APP_BUNDLE_VERSION"
	HOOKED_APP_BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName"  "$APP_PATH/Info.plist")
	echo "FOUND HOOKED_APP_BUNDLE_NAME: $HOOKED_APP_BUNDLE_NAME"
	HOOKED_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable"  "$APP_PATH/Info.plist")
	echo "FOUND HOOKED_EXECUTABLE: $HOOKED_EXECUTABLE"
	HOOKED_EXE_PATH="$APP_PATH/$HOOKED_EXECUTABLE"
	echo "FOUND HOOKED_EXE_PATH: $HOOKED_EXE_PATH"
	HOOKED_APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier"  "$APP_PATH/Info.plist")
	echo "FOUND HOOKED_APP_BUNDLE_ID: $HOOKED_APP_BUNDLE_ID"

	filename=$(basename "$HOOKED_EXE_PATH")
	extension="${filename##*.}"
	filename="${filename%.*}"

	val=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName"  "$APP_PATH/Info.plist" 2>/dev/null)
	exitCode=$?
	if (( exitCode == 0 )); then
	  HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName"  "$APP_PATH/Info.plist")
	else
	  /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string" "$APP_PATH/Info.plist"
	  HOOKED_APP_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName"  "$APP_PATH/Info.plist")
	fi

	HOOKED_APP_BUNDLE_NAME="$HOOKED_APP_BUNDLE_NAME"
	HOOKED_APP_BUNDLE_NAME=${HOOKED_APP_BUNDLE_NAME// /_}

	HOOKED_APP_NAME="$HOOKED_APP_NAME"
	HOOKED_APP_NAME=${HOOKED_APP_NAME// /_}
	echo "****** $HOOKED_APP_NAME"


	/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $HOOKED_APP_NAME" "$APP_PATH/Info.plist"
	echo "[   ] Make App Binary Executable"

	if ! [[ -x "$HOOKED_EXE_PATH" ]]; then
	  echo "EXE NOT EXECUTABLE SO CHANGING PERMISSIONS"
	    chmod +x "$HOOKED_EXE_PATH"
	else
	    echo "EXE IS EXECUTABLE"
	fi

	/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:0 integer 1" "$APP_PATH/Info.plist"
	/usr/libexec/PlistBuddy -c "Add ::UIDeviceFamily:1 integer 2" "$APP_PATH/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier net.baytapps.$HOOKED_APP_NAME" "$APP_PATH/Info.plist"

	echo "[   ] Add the correct entitlements"
	TEMP_PLIST="$TEMP_PATH/temp.plist"
	REAL_CODE_SIGN_ENTITLEMENTS="$TEMP_PATH/app.entitlements"
	# sudo cp $DEFAULT_ENTITLEMENTS $REAL_CODE_SIGN_ENTITLEMENTS

	echo "[   ] Gettings entitlements from profile"
	sudo $DECODER_PATH -f $ProfilePATH -o "./tempEnt.plist"
  	echo "[   ] Setting entitlements to plist"
	sudo /usr/libexec/PlistBuddy -x -c "Print Entitlements" "./tempEnt.plist"  > "$DEFAULT_ENTITLEMENTS"
  	sudo cp $DEFAULT_ENTITLEMENTS $REAL_CODE_SIGN_ENTITLEMENTS

  	echo "[   ] sign all the executable binaries"
	for DYLIB in "$APP_PATH/"*.dylib
	do
	  FILENAME=$(basename $DYLIB)
	  echo "SIGNING: $FILENAME"
	  codesign --force --sign "$CertNAME" "$DYLIB"
	done

  	APP_PLUGINS_PATH="$APP_PATH/PlugIns"
	rm -rf $APP_PLUGINS_PATH
	APP_WATCH_PATH="$APP_PATH/Watch"
	rm -rf $APP_WATCH_PATH

  	APP_FRAMEWORKS_PATH="$APP_PATH/Frameworks"
	if [ -d "$APP_FRAMEWORKS_PATH" ]; then
		for FRAMEWORK in "$APP_FRAMEWORKS_PATH/"*
		do
			#grab the framework name
			echo "FRAMEWORK: $FRAMEWORK"
			#sign the FRAMEWORK

			# sudo /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion 9.0" "$FRAMEWORK/Info.plist"
			sudo codesign -fs "$CertNAME" "$FRAMEWORK"
		done
	fi

	echo "[   ] sign app"
	sudo cp "$ProfilePATH" "$APP_PATH/embedded.mobileprovision"
	sudo codesign -fs "$CertNAME" --entitlements "$REAL_CODE_SIGN_ENTITLEMENTS" --timestamp=none "$APP_PATH"

	echo "[   ] Create distrubtion.plist"
	OTA_PLIST="./manifest.plist"
	OTA_PLIST_PATH="$OutPATH/plist/"
  	OTA_IPA_PATH="$OutPATH/ipa/"
  	OTA_IMG_PATH="$OutPATH/img/"

  	if [ -d "$OTA_PLIST_PATH" ];then
		echo "Plist path already exist"
	else
		sudo mkdir -p "$OTA_PLIST_PATH" || true
	fi

  if [ -d "$OTA_IPA_PATH" ];then
		echo "Plist path already exist"
	else
		sudo mkdir -p "$OTA_IPA_PATH" || true
	fi

  if [ -d "$OTA_IMG_PATH" ];then
		echo "Plist path already exist"
	else
		sudo mkdir -p "$OTA_IMG_PATH" || true
	fi

  if [ -f "$APP_PATH/AppIcon60x60@3x.png" ];then
	  echo "AppIcon60x60@3x file existe"
	    appIcon="$APP_PATH/AppIcon60x60@3x.png"
	else
	  if [ -f "$APP_PATH/AppIcon60x60@2x.png" ];then
	    echo "AppIcon60x60@2x file existe"
	      appIcon="$APP_PATH/AppIcon60x60@2x.png"
	  else
	    if [ -f "$APP_PATH/Icon-60@3x.png" ];then
	      echo "Icon-60@3x file existe"
	        appIcon="$APP_PATH/Icon-60@3x.png"
	    else
	      if [ -f "$APP_PATH/Icon-60@2x.png" ];then
	        echo "Icon-60@2x file existe"
	          appIcon="$APP_PATH/Icon-60@2x.png"
	      else
	        if [ -f "$APP_PATH/60x60_Icon@3x.png" ];then
	          echo "60x60_Icon@3x file existe"
	            appIcon="$APP_PATH/60x60_Icon@3x.png"
	          else
	            if [ -f "$APP_PATH/Icon-60-Prod@3x.png" ];then
	            echo "Icon-60-Prod@3x file existe"
	              appIcon="$APP_PATH/Icon-60-Prod@3x.png"
	            else
	              if [ -f "$APP_PATH/Icon-60-Prod@2x.png" ];then
	              echo "Icon-60-Prod@2x file existe"
	                appIcon="$APP_PATH/Icon-60-Prod@2x.png"
	              else
	                if [ -f "$APP_PATH/AppIcon-260x60@3x.png" ];then
	                echo "AppIcon-260x60@3x file existe"
	                  appIcon="$APP_PATH/AppIcon-260x60@3x.png"
	                else
	                  if [ -f "$APP_PATH/AppIcon-260x60@2x.png" ];then
	                  echo "AppIcon-260x60@2x file existe"
	                    appIcon="$APP_PATH/AppIcon-260x60@2x.png"
	                  else
	                    if [ -f "$APP_PATH/ProductionAppIcon60x60@3x.png" ];then
	                    echo "ProductionAppIcon60x60@3x file existe"
	                      appIcon="$APP_PATH/ProductionAppIcon60x60@3x.png"
	                    else
	                      if [ -f "$APP_PATH/ProductionAppIcon60x60@2x.png" ];then
	                      echo "ProductionAppIcon60x60@2x file existe"
	                        appIcon="$APP_PATH/ProductionAppIcon60x60@2x.png"
	                      else
	                        if [ -f "$APP_PATH/ReleaseIcon60x60@3x.png" ];then
	                        echo "ReleaseIcon60x60@3x file existe"
	                          appIcon="$APP_PATH/ReleaseIcon60x60@3x.png"
	                        else
	                          if [ -f "$APP_PATH/ReleaseIcon60x60@2x.png" ];then
	                          echo "ReleaseIcon60x60@2x file existe"
	                            appIcon="$APP_PATH/ReleaseIcon60x60@2x.png"
	                          else
	                            if [ -f "$APP_PATH/Icon-120.png" ];then
	                            echo "Icon-120 file existe"
	                              appIcon="$APP_PATH/Icon-120.png"
	                            else
	                              if [ -f "$APP_PATH/iPhone_icon_120x120.png" ];then
	                              echo "iPhone_icon_120x120 file existe"
	                                appIcon="$APP_PATH/iPhone_icon_120x120.png"
	                              else
	                                if [ -f "$APP_PATH/Icon-Production@2x.png" ];then
	                                echo "Icon-Production@2x file existe"
	                                  appIcon="$APP_PATH/Icon-Production@2x.png"
	                                else
	                                  if [ -f "$APP_PATH/AppIcon-Free60x60@3x.png" ];then
	                                  echo "AppIcon-Free60x60@3x file existe"
	                                    appIcon="$APP_PATH/AppIcon-Free60x60@3x.png"
	                                  else
	                                    if [ -f "$APP_PATH/Icon120x120.png" ];then
	                                    echo "Icon120x120 file existe"
	                                      appIcon="$APP_PATH/Icon120x120.png"
	                                    else
	                                      appIcon="./Icon-60@3x.png"
	                                    fi
	                                  fi
	                                fi
	                              fi
	                            fi
	                          fi
	                        fi
	                      fi
	                    fi
	                  fi
	                fi
	              fi
	            fi
	          fi
	      fi
	    fi
	  fi
	fi

  	sudo cp "$appIcon" "$OutPATH/img/$HOOKED_APP_NAME.png"
 	sudo chmod 777 "$OutPATH/img/$HOOKED_APP_NAME.png"

 	OTA_MODIFIED_PLIST_PATH="$OutPATH/Plist/$HOOKED_APP_BUNDLE_NAME.plist"
	sudo cp "$OTA_PLIST" "$OTA_MODIFIED_PLIST_PATH"
	sudo chmod 777 "$OTA_MODIFIED_PLIST_PATH"

	sudo /usr/libexec/PlistBuddy -c "Add :items array" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Delete :items: dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items: dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets array" "$OTA_MODIFIED_PLIST_PATH"

	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:0 dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:0:kind string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:0:kind software-package" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:0:url string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:0:url $SERVERURL/ipa/$HOOKED_APP_NAME.ipa" "$OTA_MODIFIED_PLIST_PATH"

	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:1 dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:1:kind string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:1:kind display-image" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:1:url string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:1:url $SERVERURL/img/$HOOKED_APP_NAME.png" "$OTA_MODIFIED_PLIST_PATH"

	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:2 dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:2:kind string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:2:kind full-size-image" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:assets:2:url string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:assets:2:url $SERVERURL/img/$HOOKED_APP_NAME.png" "$OTA_MODIFIED_PLIST_PATH"

	sudo /usr/libexec/PlistBuddy -c "Add :items:0:metadata dict" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-identifier string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-identifier $HOOKED_APP_BUNDLE_ID" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:metadata:bundle-version string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:metadata:bundle-version $HOOKED_APP_BUNDLE_VERSION" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:metadata:kind string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:metadata:kind software" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Add :items:0:metadata:title string" "$OTA_MODIFIED_PLIST_PATH"
	sudo /usr/libexec/PlistBuddy -c "Set :items:0:metadata:title $HOOKED_APP_NAME" "$OTA_MODIFIED_PLIST_PATH"

	echo "[   ] archive app"
	cd $EXTRACTED_IPA_PATH
	sudo zip -9r "$HOOKED_APP_NAME.ipa" Payload/ >/dev/null 2>&1
	cd ../../../
	sudo cp "$EXTRACTED_IPA_PATH/$HOOKED_APP_NAME.ipa" "$OUTPUT_PATH/ipa/$HOOKED_APP_NAME.ipa"
	sudo chmod 777 "$OUTPUT_PATH/ipa/$HOOKED_APP_NAME.ipa"

	sudo rm -rf "$EXTRACTED_IPA_PATH" || true
	sudo rm -rf "$WORKING_PATH" || true
	sudo rm -rf "$TEMP_PATH" || true


done