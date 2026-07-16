#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum AssetLookup {
    static func exists(_ name: String) -> Bool {
        #if os(macOS)
        NSImage(named: name) != nil
        #else
        UIImage(named: name) != nil
        #endif
    }
}
