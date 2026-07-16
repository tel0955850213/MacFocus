# Focus Arcana Maintenance Notes

## Product Targets

- `MacFocus`: macOS 14+ app, including the floating desktop companion, menu-bar timer, Dock visibility, and launch-at-login.
- `FocusArcanaIOS`: iOS/iPadOS 17+ app using the same bundle ID (`com.donaldlin.macfocus`) for a universal App Store listing.
- Shared gameplay, persistence, localization, screens, assets, sounds, and timer logic live under `MacFocus/`.
- iOS-only app lifecycle and adaptive navigation live under `MacFocusIOS/`.

## Platform Boundaries

- Keep AppKit, `NSPanel`, status-item, Dock, and `SMAppService` code out of the iOS target.
- Use `AssetLookup` instead of calling `NSImage` or `UIImage` directly from shared views.
- Pointer cursor changes in `GachaScreen` are macOS-only; the drag-to-summon gesture must remain available on touch.
- The iOS app does not create a system-wide desktop pet. Its character companion remains inside the app.
- Never use four-point star/sparkle glyphs or artwork. The mascot frames intentionally contain no sparkle decoration.

## XcodeGen and Tests

Run `xcodegen generate` once before builds. Do not run concurrent `xcodegen generate` commands against the same worktree; they race while replacing `MacFocus.xcodeproj`.

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild test -scheme FocusArcanaIOS \
  -destination 'platform=iOS Simulator,id=BEC75524-089B-43FF-B842-04A34FB56FEC' \
  CODE_SIGNING_ALLOWED=NO

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild -scheme MacFocus -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

The required QA device is `Import QA iOS 27`. iPhone and iPad layouts must both be checked before release.

## Apple Release

- This Mac runs beta macOS/Xcode. Never upload its local archive to App Store Connect.
- Use local builds and simulators for QA, then one manual Xcode Cloud Release archive for the official iOS build.
- Disable branch-change, pull-request, and scheduled Cloud triggers. Keep only one Release archive action.
- Confirm App Privacy is published, run `asc validate` and `asc review doctor`, and verify the build is `VALID` before submission.
- Final Submit for Review requires explicit action-time confirmation.
