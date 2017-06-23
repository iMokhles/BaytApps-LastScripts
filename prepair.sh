# !/bin/bash

AppIPA="$1"
CertNAME="$2"
ProfilePATH="$3"

chmod 777  "$AppIPA"
echo "/Users/TotoaTEAM/.fastlane/bin/fastlane sigh resign $AppIPA --signing_identity $CertNAME -p $ProfilePATH"
/Users/TotoaTEAM/.fastlane/bin/fastlane sigh resign "$AppIPA" --signing_identity "$CertNAME" -p "$ProfilePATH"
