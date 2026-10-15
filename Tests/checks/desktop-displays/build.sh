#!/bin/bash
# usage: build.sh WT OUT [DesktopDisplays.swift override] [DesktopDisplayMemory.swift override]
# Compiles DesktopDisplays.swift and DesktopDisplayMemory.swift with StreamProtocol's sources as one
# module (DesktopDisplays.swift's `import StreamProtocol` stripped).
WT=$1; OUT=$2; T=$(mktemp -d)
cp "$WT"/Sources/StreamProtocol/*.swift "$T"/
sed '/^import StreamProtocol$/d' "${3:-$WT/Sources/SillHost/DesktopDisplays.swift}" > "$T/DesktopDisplays.swift"
cp "${4:-$WT/iOSClient/DesktopDisplayMemory.swift}" "$T/DesktopDisplayMemory.swift"
cp "$(dirname "$0")/main.swift" "$T/main.swift"
rm -f "$OUT"
swiftc -O "$T"/*.swift -o "$OUT" 2>&1 | grep -E "error" ; rm -rf "$T"
