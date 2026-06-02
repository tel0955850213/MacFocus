import SwiftUI

@main
struct MacFocusApp: App {
    @StateObject private var progress = ProgressStore()
    @StateObject private var pet = PetController()
    @StateObject private var engine = TimerEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progress)
                .environmentObject(pet)
                .environmentObject(engine)
                .frame(minWidth: 920, minHeight: 640)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
