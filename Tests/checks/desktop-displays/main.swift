// The Desktop's display (kind 40), host and device, with Sources/StreamProtocol as one module:
//
//   Tests/checks/desktop-displays/build.sh . .build/checks/desktop-displays/check && .build/checks/desktop-displays/check
//
// What it checks: the displays a device may pick (never Sill's own virtual display, the system's
// order, the main one marked); the display the Desktop shows (the pick while it is listed, else the
// main display, else the first; none with none listed) and a pick that went being forgotten; which
// display a device asks for (the one last picked there for that Mac, across connections and per
// Mac, else the Mac's main display; a display that comes back asked for again; nothing for a Mac
// from before kind 40), against this Mac's own three displays and Sill's virtual one.
import Foundation

setvbuf(stdout, nil, _IOLBF, 0)
var failures = 0
func check(_ ok: Bool, _ what: String) {
    print("\(ok ? "ok" : "FAIL") \(what)")
    if !ok { failures += 1 }
}
func eq<T: Equatable>(_ a: T, _ b: T, _ what: String) { check(a == b, "\(what): \(a)" + (a == b ? "" : " (want \(b))")) }

// The displays of the Mac this was written on (2026-10-15), with Sill's virtual display while a
// window is staged there. CGDirectDisplayIDs as macOS gave them.
let dell = DesktopDisplays.Screen(id: 3, name: "DELL U4025QW", width: 3360, height: 1418, sills: false)
let builtIn = DesktopDisplays.Screen(id: 1, name: "Built-in Retina Display", width: 1728, height: 1117, sills: false)
let phone = DesktopDisplays.Screen(id: 7, name: "OpenDisplay — iPhone", width: 440, height: 956, sills: false)
let sills = DesktopDisplays.Screen(id: 9, name: "Display 9", width: 1194, height: 834, sills: true)
let screens = [builtIn, sills, dell, phone]

// MARK: The displays a device may pick

let listed = DesktopDisplays.listed(screens, main: 3)
eq(listed.map(\.id), [1, 3, 7], "listed: Sill's own virtual display left out, the system's order kept")
eq(listed.map(\.name), ["Built-in Retina Display", "DELL U4025QW", "OpenDisplay — iPhone"], "listed: NSScreen's names")
eq(listed.map(\.main), [nil, true, nil], "listed: only the main display marked")
eq(listed.first { $0.id == 3 }.map { [$0.width, $0.height] }, [3360, 1418], "listed: the size in points")
eq(DesktopDisplays.listed([sills], main: 9), [], "listed: Sill's display alone lists nothing, even as the main one")
eq(DesktopDisplays.listed([], main: 1), [], "listed: no displays")

// MARK: The display the Desktop shows

eq(DesktopDisplays.shown(picked: nil, listed: listed), 3, "shown: nothing picked, the main display")
eq(DesktopDisplays.shown(picked: 7, listed: listed), 7, "shown: the pick")
eq(DesktopDisplays.shown(picked: 1, listed: listed), 1, "shown: the built-in display picked")
eq(DesktopDisplays.shown(picked: 9, listed: listed), 3, "shown: Sill's display picked: the main display")
eq(DesktopDisplays.shown(picked: 42, listed: listed), 3, "shown: a display that is not listed (gone): the main display")
let phoneGone = DesktopDisplays.listed([builtIn, dell], main: 3)
eq(DesktopDisplays.shown(picked: 7, listed: phoneGone), 3, "shown: the picked display went: the main display")
eq(DesktopDisplays.kept(7, listed: phoneGone), nil, "kept: a pick that went is forgotten")
eq(DesktopDisplays.kept(7, listed: listed), 7, "kept: a listed pick stays")
eq(DesktopDisplays.kept(nil, listed: listed), nil, "kept: nothing picked")
// Forgotten, so the Desktop stays on the main display when the display comes back.
let forgotten = DesktopDisplays.kept(7, listed: phoneGone)
eq(DesktopDisplays.shown(picked: forgotten, listed: listed), 3, "shown: the display back, the forgotten pick stays on the main display")
let mainIsSills = DesktopDisplays.listed([sills, builtIn, dell], main: 9)
eq(DesktopDisplays.shown(picked: nil, listed: mainIsSills), 1, "shown: the main display is Sill's own: the first listed")
eq(DesktopDisplays.shown(picked: nil, listed: []), nil, "shown: none listed: none")
eq(DesktopDisplays.shown(picked: 3, listed: DesktopDisplays.listed([dell], main: 3)), 3, "shown: one display")

// MARK: Which display a device asks for

// A defaults file of the check's own (an absolute path names one), never the user's domains.
// Per run: cfprefsd may still hold an earlier run's values for a file that was removed.
let suite = (CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : NSTemporaryDirectory()) + "/defaults-\(getpid())"
let defaults = UserDefaults(suiteName: suite)!
let memory = DesktopDisplayMemory(defaults: defaults)
eq(memory.wanted(for: "Mac mini", listed: listed), 3, "wanted: nothing picked on this device: the main display")
eq(memory.remembered(for: "Mac mini"), nil, "remembered: nothing")
eq(memory.wanted(for: "Mac mini", listed: []), nil, "wanted: a Mac that lists no displays (before kind 40) is sent none")
memory.remember(7, for: "Mac mini")
eq(memory.wanted(for: "Mac mini", listed: listed), 7, "wanted: the display picked here")
eq(memory.wanted(for: "Mac mini", listed: []), nil, "wanted: a Mac before kind 40 is sent none, whatever was picked")
// The next connection, or the next launch: a new reader of the same defaults.
let again = DesktopDisplayMemory(defaults: UserDefaults(suiteName: suite)!)
eq(again.wanted(for: "Mac mini", listed: listed), 7, "wanted: across connections")
eq(again.wanted(for: "MacBook Pro", listed: listed), 3, "wanted: another Mac keeps its own (the main display)")
again.remember(1, for: "MacBook Pro")
eq(memory.wanted(for: "MacBook Pro", listed: listed), 1, "wanted: per Mac (MacBook Pro)")
eq(memory.wanted(for: "Mac mini", listed: listed), 7, "wanted: per Mac (Mac mini unchanged)")
eq(memory.wanted(for: "Mac mini", listed: phoneGone), 3, "wanted: the picked display gone: the main display")
eq(memory.remembered(for: "Mac mini"), 7, "remembered: kept while it is gone")
eq(memory.wanted(for: "Mac mini", listed: listed), 7, "wanted: the display back: asked for again")
memory.remember(3, for: "Mac mini")
eq(memory.wanted(for: "Mac mini", listed: listed), 3, "wanted: a later pick replaces the earlier")
eq(DesktopDisplayMemory.wanted(remembered: nil, listed: mainIsSills), 1, "wanted: no main display listed: the first")
eq(DesktopDisplayMemory.wanted(remembered: 0xFFFF_FFFF, listed: [DisplayInfo(id: 0xFFFF_FFFF, name: "x", width: 1, height: 1)]), 0xFFFF_FFFF,
   "wanted: the largest display ID round-trips")
memory.remember(0xFFFF_FFFF, for: "Edge")
eq(memory.remembered(for: "Edge"), 0xFFFF_FFFF, "remembered: the largest display ID kept whole")
eq(DesktopDisplayMemory.key(for: "Mac mini"), "Sill.desktopDisplay.Mac mini", "the defaults key, per Mac by name")

try? FileManager.default.removeItem(atPath: suite + ".plist")
print(failures == 0 ? "desktop-displays: every check passed" : "desktop-displays: \(failures) FAILED")
exit(failures == 0 ? 0 : 1)
