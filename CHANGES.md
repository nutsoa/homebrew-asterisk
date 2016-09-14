# homebrew-asterisk

## 2016-09-13 - adilinden

 * Now build works on OS X 10.11.6.
 * Asterisk 13.11.2
   - Incorporated fix from leedm777: https://github.com/leedm777/homebrew-asterisk/issues/22
   - homebrew updated to srtp2, changed dependencies to srtp15. 
 * Removed devel and HEAD.
 * Removed ikseml
 * Removed gmime, unixodbc and ncurses dependency

## 2015-11-23 - adilinden

 * Added extra-sounds option.  As far as I know homebrew does not like formulas that download content.  Maybe there is a better way to do this?

## 2015-11-22 - adilinden

 * Updated the launchd plist as original would refuse to load asterisk when dedicated asterisk user was added.

## 2015-11-21 - adilinden

 * Changed installation directory for sample configuration.  This protects any customized configuration installed in `/usr/local/etc/asterisk` from being oeverwritten by the asterisk installation step.
 * Added patches to allow installation of basic-pbx configuration.  The basic-pbx configuartion is installed along side samples configuration.

## 2015-11-19 - leedm777

 * Added separate optimize and dev-mode options (although dev-mode still implies
   dont-optimize)

## 2015-10-29 - leedm777

 * Use GitHub instead of Gerrit for HEAD and devel builds, so we're cloning
   from a repo instead of a code review tool

## 2015-10-13 - leedm777

 * Added changelog
 * Upgrade to Asterisk 13.6.0
 * Upgrade to PJSIP 2.4.5
 * Travis: Refine brew upgrade to only upgrade dependencies
