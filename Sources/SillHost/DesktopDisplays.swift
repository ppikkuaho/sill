import StreamProtocol

/// Which of the Mac's displays the Desktop shows, and which a device may pick (kind 40). The catalog
/// reads the displays (ScreenCaptureKit, NSScreen) and asks here; the coordinator keeps each
/// connection's pick. Pure (StreamProtocol's Switcher.swift), checked with swiftc
/// (Tests/checks/desktop-displays).
enum DesktopDisplays {
    /// One display as the catalog read it.
    struct Screen: Equatable {
        var id: UInt32
        var name: String
        var width: Double
        var height: Double
        /// One of Sill's own virtual displays (VirtualStage's vendor): never listed, never the Desktop.
        var sills: Bool
    }

    /// The displays a device may pick, in the system's order, the main one marked; never Sill's own.
    static func listed(_ screens: [Screen], main: UInt32) -> [DisplayInfo] {
        screens.filter { !$0.sills }.map {
            DisplayInfo(id: $0.id, name: $0.name, width: $0.width, height: $0.height, main: $0.id == main ? true : nil)
        }
    }

    /// The display the Desktop shows: the pick while it is listed, else the main display, else the
    /// first listed (a main display that is Sill's own); nil when none is listed.
    static func shown(picked: UInt32?, listed: [DisplayInfo]) -> UInt32? {
        kept(picked, listed: listed) ?? (listed.first { $0.main == true } ?? listed.first)?.id
    }

    /// The pick while it is listed. One that went is forgotten, so the Desktop that fell back to the
    /// main display stays there when the display comes back; the device asks for it again with its
    /// next Desktop pick.
    static func kept(_ picked: UInt32?, listed: [DisplayInfo]) -> UInt32? {
        guard let picked, listed.contains(where: { $0.id == picked }) else { return nil }
        return picked
    }
}
