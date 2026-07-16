import XCTest
@testable import FocusArcana

final class PlatformCapabilitiesTests: XCTestCase {
    func testIOSKeepsCoreFocusFeaturesWithoutDesktopOnlySurfaces() {
        XCTAssertTrue(PlatformCapabilities.supportsFocusTimer)
        XCTAssertTrue(PlatformCapabilities.supportsCharacterCollection)
        XCTAssertTrue(PlatformCapabilities.supportsTouchSummoning)
        XCTAssertFalse(PlatformCapabilities.supportsFloatingDesktopPet)
        XCTAssertFalse(PlatformCapabilities.supportsMenuBarTimer)
        XCTAssertFalse(PlatformCapabilities.supportsLaunchAtLogin)
    }
}
