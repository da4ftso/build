#!/usr/bin/env bash

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

function setVariables() {
    FILE_NAME="$(printf "$(basename "${f}")" | sed 's/\.[^.]*$//')"
    APP_VERSION=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleShortVersionString)
    APP_ARCH=$(/usr/bin/lipo -archs "${f}"/Contents/MacOS/* | sed -e 's/x86_64 arm64/Universal/' -e 's/x86_64/x86/' )
    SHORT_VERSION=$(echo ${APP_VERSION} | cut -d. -f-3)
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

for f in "$@"; do
    setVariables
    makeContainers
    gatherICNS
    generatePKG
done

open "${WORKING_DIRECTORY}"

/usr/bin/osascript -e 'tell application "Jamf Admin" to open'

exit 0
