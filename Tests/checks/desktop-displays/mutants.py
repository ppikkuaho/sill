"""Mutants of Sources/SillHost/DesktopDisplays.swift and iOSClient/DesktopDisplayMemory.swift: each must
compile and fail the desktop-displays check (main.swift).
usage: mutants.py WORKTREE"""
import os, subprocess, sys, tempfile
WT = sys.argv[1]
HERE = os.path.dirname(os.path.abspath(__file__))
HOST = "Sources/SillHost/DesktopDisplays.swift"
DEVICE = "iOSClient/DesktopDisplayMemory.swift"
MUTANTS = [
    ("DD1 Sill's own display listed", HOST, "screens.filter { !$0.sills }.map {", "screens.map {"),
    ("DD2 every display marked main", HOST, "main: $0.id == main ? true : nil)", "main: true)"),
    ("DD3 main marked false, not left out", HOST, "main: $0.id == main ? true : nil)", "main: $0.id == main)"),
    ("DD4 the first listed before the main one", HOST, "(listed.first { $0.main == true } ?? listed.first)?.id", "listed.first?.id"),
    ("DD5 a pick that went is kept", HOST, "guard let picked, listed.contains(where: { $0.id == picked }) else { return nil }", "guard let picked else { return nil }"),
    ("DD6 the pick ignored", HOST, "kept(picked, listed: listed) ?? (listed.first", "nil ?? (listed.first"),
    ("DD7 width and height swapped", HOST, "width: $0.width, height: $0.height", "width: $0.height, height: $0.width"),
    ("DM1 the remembered display asked for though it is gone", DEVICE, "if let remembered, listed.contains(where: { $0.id == remembered }) { return remembered }", "if let remembered, !listed.isEmpty { return remembered }"),
    ("DM2 the first display instead of the main one", DEVICE, "return (listed.first { $0.main == true } ?? listed.first)?.id", "return listed.first?.id"),
    ("DM3 never remembered", DEVICE, "defaults.set(Int64(display), forKey: Self.key(for: mac))", "_ = display"),
    ("DM4 one memory for every Mac", DEVICE, '"Sill.desktopDisplay." + mac', '"Sill.desktopDisplay"'),
    ("DM5 the remembered display ignored", DEVICE, "Self.wanted(remembered: remembered(for: mac), listed: listed)", "Self.wanted(remembered: nil, listed: listed)"),
    ("DM6 the tap asks for the remembered display (the bug of 2026-10-16)", DEVICE, "if let other { pick(other, for: mac, showing: showing, listed: listed) }", "_ = other"),
    ("DM7 the display a pick replaces never kept", DEVICE, "defaults.set(Int64(was), forKey: Self.previousKey(for: mac))", "_ = was"),
    ("DM8 the tap over a window goes back too", DEVICE, "guard let showing else { return }", "let showing = showing ?? remembered(for: mac) ?? 0"),
    ("DM9 the display before asked for though it is gone", DEVICE, ".first { id in id != showing && listed.contains { $0.id == id } }", ".first { id in id != showing }"),
    ("DM10 a pick of the display on screen forgets the one before", DEVICE, "if let was = showing ?? wanted(for: mac, listed: listed), was != display {", "if let was = showing ?? wanted(for: mac, listed: listed) {"),
]
caught = 0
for name, rel, old, new in MUTANTS:
    with tempfile.TemporaryDirectory() as t:
        text = open(os.path.join(WT, rel)).read()
        if text.count(old) != 1:
            print(f"{name}: NOT APPLIED (pattern found {text.count(old)} times)"); continue
        mutant = os.path.join(t, os.path.basename(rel))
        open(mutant, "w").write(text.replace(old, new, 1))
        host = mutant if rel == HOST else os.path.join(WT, HOST)
        device = mutant if rel == DEVICE else os.path.join(WT, DEVICE)
        exe = os.path.join(t, "check")
        subprocess.run([os.path.join(HERE, "build.sh"), WT, exe, host, device], capture_output=True, text=True)
        if not os.path.exists(exe):
            print(f"{name}: DOES NOT COMPILE"); continue
        r = subprocess.run([exe, t], capture_output=True, text=True, timeout=120)
        failed = [l[5:] for l in r.stdout.splitlines() if l.startswith("FAIL")]
        ok = r.returncode != 0
        caught += ok
        print(f"{'caught' if ok else 'MISSED'} {name}: {len(failed)} failing, e.g. {failed[:1]}")
print(f"{caught} of {len(MUTANTS)} mutants caught")
sys.exit(0 if caught == len(MUTANTS) else 1)
