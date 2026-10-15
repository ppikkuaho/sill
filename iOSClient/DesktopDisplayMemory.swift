import Foundation
// In the app StreamProtocol is its own module; the desktop-displays check compiles this file together
// with Sources/StreamProtocol as one module, where there is nothing to import.
#if canImport(StreamProtocol)
import StreamProtocol
#endif

/// Which of the Mac's displays this device's Desktop shows (kind 40): the one last picked on this
/// device for that Mac (the Desktop button's long press), kept across connections and launches,
/// else the Mac's main display. Pure but for the defaults it is given; checked with swiftc
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

    /// Per Mac by its name, as the bar's arrangement is (`Sill.windowOrder.`).
    static func key(for mac: String) -> String { "Sill.desktopDisplay." + mac }
}
