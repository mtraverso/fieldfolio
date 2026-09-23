#!/bin/bash
# Intentionally a no-op.
#
# On the iOS Simulator, ProcessProductPackaging already embeds App Groups into
# *-Simulated.xcent (Mach-O __entitlements). That is enough for
# group.com.fieldfolio.app to work.
#
# Copying those entitlements into the codesign .xcent (or ad-hoc re-signing)
# makes SpringBoard refuse to launch the app (POSIX 163 / Launchd spawn failed).
# Keep CODE_SIGN_ENTITLEMENTS pointed at the .entitlements files instead.
set -euo pipefail
exit 0
