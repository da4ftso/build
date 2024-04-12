#!/usr/bin/env bash

# 1.4 - mv existing files to .bak
# 1.3 - print some more relevant details about the app
# 1.2 - loop through $1/Contents/MacOS and find the executable that will return a value for arch type
#       ie iTerm2.app contains 3 executables, each one is universal.
#  so a previous thought was this little gem:
#       /usr/bin/lipo -archs $(ls "${f}"/Contents/MacOS/*|head -n 1)
#  some apps may contain a .bundle in .app/Contents/MacOS though, and if that gets listed first we don't
#       get a value for arch type.
#  so instead, we're going to loop through that dir inside the app bundle until we get a value returned
#  but this is obviously incomplete and prone to errors.

###############################################################################
#   Copyright 2017 Benjamin Moralez                                           #
#                                                                             #
#   Licensed under the Apache License, Version 2.0 (the "License");           #
#   you may not use this file except in compliance with the License.          #
#   You may obtain a copy of the License at                                   #
#                                                                             #
#       http://www.apache.org/licenses/LICENSE-2.0                            #
#                                                                             #
#   Unless required by applicable law or agreed to in writing, software       #
#   distributed under the License is distributed on an "AS IS" BASIS,         #
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  #
#   See the License for the specific language governing permissions and       #
#   limitations under the License.                                            #
###############################################################################

currentUser=$( /usr/bin/stat -f%Su "/dev/console" )
currentUserHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk ' { print $NF } ')

function setVariables() {
    FILE_NAME="$(printf "$(basename "${f}")" | sed 's/\.[^.]*$//')"
    APP_VERSION=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleShortVersionString)
    APP_ARCH=$(/usr/bin/lipo -archs "${f}"/Contents/MacOS/* | sed -e 's/x86_64 arm64/Universal/' -e 's/x86_64/x86/' )
    SHORT_VERSION=$(echo "${APP_VERSION}" | cut -d. -f-3)
    PKG_NAME="${FILE_NAME}-${SHORT_VERSION}-${APP_ARCH}.pkg"
    WORKING_DIRECTORY="$HOME/Documents/AppToPKG/${FILE_NAME} (${SHORT_VERSION})"
    ICON_NAME=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleIconFile | sed -e 's/\.icns$//')
    APP_ICON="${f}/Contents/Resources/${ICON_NAME}.icns"
}

function makeContainers() {
    /bin/mkdir -p "${WORKING_DIRECTORY}"
}

function gatherICNS() {
    /usr/bin/sips -s format png "${APP_ICON}" --out "${WORKING_DIRECTORY}/${ICON_NAME}.png"
#    /bin/cp "${APP_ICON}" "${WORKING_DIRECTORY}"
}

function generatePKG() {
    /usr/bin/productbuild --component "${f}" /Applications "${WORKING_DIRECTORY}/${PKG_NAME}"
}

function info() {
echo "Short version:  " "${APP_VERSION}"
echo "Long version:   " "$( defaults read "${f}/Contents/Info.plist" CFBundleVersion )"
echo "Bundle ID:      " "$( defaults read "${f}/Contents/Info.plist" CFBundleIdentifier )"
echo "Developer ID:   " "$( /usr/bin/codesign -dvv "${f}" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs )"
echo "Team ID:        " "$( /usr/bin/codesign -dvv "${f}" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2 )"
}

# the [d]elete action isn't handling files in working dor correctly, do we really need this?
# read -p "Existing files found: [r]ename [d]elete e[x]it: " action
# 	if [ "$action" == "d" ] || [ "$action" == "D" ] || [ "$action" == "delete" ]; then
# 		for file in "${WORKING_DIRECTORY}"/* ; do
# 			mv "${file}" "S{currentUserHome}"/.Trash
# 			done
# 		echo "Previous files trashed.."
# 	elif [ "$action" == "r" ] || [ "$action" == "R" ] || [ "$action" == "rename" ]; then
# 		for file in "${WORKING_DIRECTORY}"/* ; do
# 			mv "${file}" "${file}".bak
# 			done
# 		echo "Previous files renamed, continuing.."
# 	elif [ "$action" == "x" ] || [ "$action" == "X" ] || [ "$action" == "exit" ]; then
# 		echo "Exiting.."
# 		exit 0
# fi		

function prev_files() {
	for file in "${WORKING_DIRECTORY}"/* ; do
		mv "${file}" "${file}".bak
	done
}
for f in "$@"; do
    setVariables
    prev_files
    makeContainers
    gatherICNS
    info
    generatePKG
done

open "${WORKING_DIRECTORY}"

# ping the JSS, open Jamf Admin if available
# add a sanity check about the plist and a value from the plist

# host=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url | sed -e 's/https:\/\///' -e 's/\/.*//' -e 's/:.*//')
# ping -c 1 "${host}" > /dev/null
#
# if [ $? -eq 0 ]; then
#	/usr/bin/osascript -e 'tell application "Jamf Admin" to open'
# fi

exit 0
