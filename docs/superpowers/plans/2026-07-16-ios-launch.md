# Focus Arcana iOS Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a polished iPhone and iPad version of Focus Arcana under the existing App Store Connect record and submit it for App Review.

**Architecture:** Keep the existing macOS target intact, add a separate iOS target that compiles shared models, services, components, screens, resources, and localization, and isolate platform-only app shells and services. Use adaptive SwiftUI navigation (`TabView` on compact width, `NavigationSplitView` on regular width) and replace AppKit-only interactions with touch, haptics, UserNotifications, and in-app companion presentation.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Charts, AVFoundation, UserNotifications, XcodeGen, XCTest, iOS 17+, iOS 27 Simulator, App Store Connect CLI, Xcode Cloud.

---

### Task 1: Establish targets and platform contract

**Files:**
- Modify: `project.yml`
- Create: `MacFocus/Platform/PlatformCapabilities.swift`
- Create: `MacFocusTests/PlatformCapabilitiesTests.swift`
- Create: `MacFocusIOS/FocusArcanaIOSApp.swift`
- Create: `MacFocusIOS/Info.plist`
- Create: `MacFocusIOS/MacFocusIOS.entitlements`

- [ ] Write a failing iOS unit test that requires the platform capability contract.
- [ ] Run the test and verify it fails because the capability type is missing.
- [ ] Add the iOS app/test targets and minimal platform capability implementation.
- [ ] Regenerate the project and verify the test passes on `Import QA iOS 27`.
- [ ] Verify the unchanged macOS target still builds.

### Task 2: Make shared source compile on iOS

**Files:**
- Create: `MacFocus/Utils/AssetLookup.swift`
- Modify: `MacFocus/Components/CharacterCard.swift`
- Modify: `MacFocus/Components/MascotView.swift`
- Modify: `MacFocus/Services/CharacterCatalog.swift`
- Modify: `MacFocus/Screens/Collection/CollectionScreen.swift`
- Modify: `MacFocus/Screens/Gacha/GachaScreen.swift`
- Modify: `MacFocus/Services/Notifier.swift`
- Modify: `MacFocus/Services/AmbientSoundPlayer.swift`
- Modify: `MacFocus/Screens/Settings/SettingsScreen.swift`

- [ ] Add asset lookup tests for present and absent catalog resources.
- [ ] Replace `NSImage` checks with cross-platform asset lookup.
- [ ] Guard cursor/hover behavior while retaining drag-to-summon on touch.
- [ ] Use iOS notification authorization and haptic feedback.
- [ ] Hide macOS-only settings on iOS without removing shared settings.
- [ ] Build both targets and run tests.

### Task 3: Build adaptive iPhone/iPad app shell

**Files:**
- Create: `MacFocusIOS/IOSContentView.swift`
- Create: `MacFocusIOS/IOSCompanionView.swift`
- Modify: `MacFocus/Screens/Timer/TimerScreen.swift`
- Modify: `MacFocus/Components/CircularTimer.swift`
- Modify: `MacFocus/Screens/Collection/CollectionScreen.swift`
- Modify: `MacFocus/Screens/Stats/StatsScreen.swift`
- Modify: `MacFocus/Screens/Onboarding/OnboardingView.swift`
- Modify: `MacFocus/Components/GachaRevealView.swift`

- [ ] Add compact-layout behavior tests where logic can be extracted.
- [ ] Implement bottom tabs for compact width and split navigation for iPad.
- [ ] Add an in-app companion tab with timer controls and dialogue.
- [ ] Make timer, collection, reveal, stats, onboarding, and sheets fit compact and regular widths.
- [ ] Add accessibility labels, Dynamic Type tolerance, and safe-area handling.
- [ ] Build and test on iPhone and iPad iOS 27 simulators.

### Task 4: iOS resources, icons, and runtime QA

**Files:**
- Modify: `MacFocus/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Add: iOS 1024x1024 icon asset without alpha
- Add: `MacFocusUITests/FocusArcanaIOSUITests.swift`
- Modify: `project.yml`

- [ ] Add the iOS App Store icon slot and verify asset compilation.
- [ ] Add launch/navigation/timer/gacha/collection UI smoke tests.
- [ ] Run tests on `Import QA iOS 27` only.
- [ ] Use Computer Use to inspect every primary screen on iPhone and iPad.
- [ ] Fix clipping, overlap, touch-target, contrast, and navigation issues.

### Task 5: Store assets and metadata

**Files:**
- Create: `AppStoreMetadata/iOS-en-US.md`
- Create: `AppStoreShots/iOS/`
- Modify: `docs/APP_STORE_SUBMISSION.md`
- Modify: `AGENTS.md`

- [ ] Capture polished required iPhone and iPad screenshots from iOS 27 Simulator.
- [ ] Validate screenshot dimensions, color, and absence of debug UI.
- [ ] Prepare iOS-specific English description, keywords, review notes, and privacy confirmation.
- [ ] Document shared bundle ID, platform version, and release procedure.

### Task 6: Release candidate and submission

**Files:**
- Modify: `project.yml` version/build settings
- Generated: `MacFocus.xcodeproj` shared schemes

- [ ] Run all unit/UI tests and Debug/Release simulator builds locally.
- [ ] Confirm no secrets, paid features, forbidden icons, or untracked required resources.
- [ ] Commit with the next `build(N): ...` message, create tag `vN`, and push the release branch/commit after authorization.
- [ ] Add iOS to App Store Connect under app ID `6789488362` and apply iOS metadata/screenshots.
- [ ] Verify Xcode Cloud next build number and one manual Release Archive action.
- [ ] Obtain action-time authorization, trigger exactly one iOS Xcode Cloud release run, wait for `VALID`, and attach it.
- [ ] Run `asc validate` and `asc review doctor`, verify App Privacy is published, obtain final Submit for Review confirmation, submit, and verify `WAITING_FOR_REVIEW`.
