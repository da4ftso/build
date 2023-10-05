# universal build for .DMG downloads
 
This is an older Kandji script for downloading two .DMG versions of an .app and then building a Universal .PKG.

### Developer ID authority: /usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "Developer ID Application" | /usr/bin/cut -d ':' -f2 | /usr/bin/xargs
### Team Identifier: /usr/bin/codesign -dvv "/Applications/EXAMPLE.app" 2>&1 | /usr/bin/grep "TeamIdentifier" | /usr/bin/cut -d '=' -f2

Someday I'll figure out why it doesn't work anymore qwith .ZIP downloads.
