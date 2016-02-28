## Version information. Sets two global variables: 
##
##   VERSION -- an array of Major, Minor, and Hotfix or build number.
##   VERSION_STRING -- a string formatted as Major.Minor.Hotfix (for release) or
##                     Major.Minor.Build (for developement)
##
## Some of the info below needs to be updated when going to production releases 
## -- namely, change the isRelease variable to true and update the major 
## version, minor version, and hotFixNo. Editing this file requires a server
## restart.

## Update these fields ##
isRelease = true
majorVersion =  "16" ## Year of release.
minorVersion =  "02" ## Month of release.
hotFixNo =      "0" ## Hot fix no. for release.


VERSION = [
  majorVersion, 
  minorVersion, ## Month of major release.
  isRelease ? hotFixNo : `git describe --always --tags`.strip
]

VERSION_STRING = VERSION.join(".")
