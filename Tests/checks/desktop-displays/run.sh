#!/bin/bash
# The Desktop's display (kind 40): which of the Mac's displays a device may pick and which the
# Desktop shows (Sources/SillHost/DesktopDisplays.swift: never Sill's own virtual display, the pick
# while it is listed, else the main display, a pick that went forgotten), and which one a device asks
# for (iOSClient/DesktopDisplayMemory.swift: the one last picked there for that Mac, kept across
# connections, else the main display; nothing for a Mac from before kind 40). Compiled with
# Sources/StreamProtocol as one module (DesktopDisplays.swift's `import StreamProtocol` stripped).
#   Tests/checks/desktop-displays/run.sh             compile and run the check
#   Tests/checks/desktop-displays/run.sh --mutants   one-line mutants of both files; each must fail it
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../common.sh"
if [ "${1:-}" = "--mutants" ]; then run_mutants python3 "$here/mutants.py" "$root"; exit; fi
"$here/build.sh" "$root" "$out/check"
[ -x "$out/check" ] || { echo "$name: did not compile" >&2; exit 1; }
"$out/check" "$out"
