enum PlatformCapabilities {
    static let supportsFocusTimer = true
    static let supportsCharacterCollection = true
    static let supportsTouchSummoning = true

    #if os(macOS)
    static let supportsFloatingDesktopPet = true
    static let supportsMenuBarTimer = true
    static let supportsLaunchAtLogin = true
    #else
    static let supportsFloatingDesktopPet = false
    static let supportsMenuBarTimer = false
    static let supportsLaunchAtLogin = false
    #endif
}
