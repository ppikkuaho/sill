import Foundation
// In the app StreamProtocol is its own module; the desktop-displays check compiles this file together
// with Sources/StreamProtocol as one module, where there is nothing to import.
#if canImport(StreamProtocol)
import StreamProtocol
#endif

/// Which of the Mac's displays this device's Desktop shows (kind 40): the one last picked on this
/// device for that Mac (the Desktop button's long press, or a tap on the Desktop, which goes back to
/// the display before), kept across connections and launches, else the Mac's main display. Pure but for the defaults it is given; checked with swiftc
/// (Tests/checks/desktop-displays).
struct DesktopDisplayMemory {
    let defaults: UserDefaults

    /// The display a Desktop pick asks for: the one remembered for this Mac while it lists it, else
    /// its main display, else its first. Nil for a Mac that lists none (one from before kind 40),
    /// which is sent no kind 40.
    func wanted(for mac: String, listed: [DisplayInfo]) -> UInt32? {
        Self.wanted(remembered: remembered(for: mac), listed: listed)
    }

    static func wanted(remembered: UInt32?, listed: [DisplayInfo]) -> UInt32? {
        if let remembered, listed.contains(where: { $0.id == remembered }) { return remembered }
        return (listed.first { $0.main == true } ?? listed.first)?.id
    }

    /// The display last picked here for this Mac, gone from it or not: a display that comes back is
    /// asked for again.
    func remembered(for mac: String) -> UInt32? {
        (defaults.object(forKey: Self.key(for: mac)) as? NSNumber).map { UInt32(truncatingIfNeeded: $0.int64Value) }
    }

    func remember(_ display: UInt32, for mac: String) {
        defaults.set(Int64(display), forKey: Self.key(for: mac))
    }

    /// The Desktop button's long press: `display` from now on, and the display it replaces kept for
    /// the tap (`tapped`). `showing` is the display on screen while the Desktop is (nil over a
    /// window, where the one replaced is the one a pick asks for).
    func pick(_ display: UInt32, for mac: String, showing: UInt32?, listed: [DisplayInfo]) {
        if let was = showing ?? wanted(for: mac, listed: listed), was != display {
            defaults.set(Int64(was), forKey: Self.previousKey(for: mac))
        }
        remember(display, for: mac)
    }

    /// The Desktop button's tap: the last display shown here other than the one on screen, picked.
    /// Over a window that is the remembered one, unchanged; on the Desktop the one before it, so taps
    /// go back and forth between the last two. Nothing changes when no other is listed.
    func tapped(for mac: String, showing: UInt32?, listed: [DisplayInfo]) {
        guard let showing else { return }
        let other = [remembered(for: mac), previous(for: mac)].compactMap { $0 }
            .first { id in id != showing && listed.contains { $0.id == id } }
        if let other { pick(other, for: mac, showing: showing, listed: listed) }
    }

    /// The display the last pick here replaced, for the tap.
    func previous(for mac: String) -> UInt32? {
        (defaults.object(forKey: Self.previousKey(for: mac)) as? NSNumber).map { UInt32(truncatingIfNeeded: $0.int64Value) }
    }

    /// Per Mac by its name, as the bar's arrangement is (`Sill.windowOrder.`).
    static func key(for mac: String) -> String { "Sill.desktopDisplay." + mac }
    static func previousKey(for mac: String) -> String { "Sill.desktopDisplayBefore." + mac }
}
