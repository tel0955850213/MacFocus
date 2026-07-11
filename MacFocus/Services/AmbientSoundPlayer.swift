import AVFoundation
import Combine
import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case none
    case rain
    case whitenoise
    case cafe
    case lofiPad = "lofi_pad"

    var id: String { rawValue }
    var labelKey: String { "sound.\(rawValue)" }
}

/// A low-power looping ambience player. It only keeps the audio engine alive
/// while an active focus session is running, and uses WAV loops to avoid AAC
/// priming gaps at the loop boundary.
@MainActor
final class AmbientSoundPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var lastError: String?

    private let audioEngine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var subscriptions = Set<AnyCancellable>()
    private weak var timerEngine: TimerEngine?
    private weak var settings: SettingsStore?
    private var currentSound: AmbientSound?
    private var fadeTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?

    init() {
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode,
                            format: audioEngine.mainMixerNode.outputFormat(forBus: 0))
    }

    deinit {
        fadeTask?.cancel()
        previewTask?.cancel()
        audioEngine.stop()
    }

    func attach(to timerEngine: TimerEngine, settings: SettingsStore) {
        guard self.timerEngine !== timerEngine || self.settings !== settings else { return }
        self.timerEngine = timerEngine
        self.settings = settings
        subscriptions.removeAll()

        timerEngine.$phase
            .combineLatest(timerEngine.$isRunning)
            .sink { [weak self] _, _ in
                Task { @MainActor in self?.syncToFocusState() }
            }
            .store(in: &subscriptions)

        settings.$ambientSound
            .combineLatest(settings.$ambientVolume)
            .sink { [weak self] _, _ in
                Task { @MainActor in self?.syncToFocusState() }
            }
            .store(in: &subscriptions)

        syncToFocusState()
    }

    func preview(_ sound: AmbientSound) {
        guard sound != .none else { stop() ; return }
        previewTask?.cancel()
        play(sound, volume: settings?.ambientVolume ?? 0.6)
        previewTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.syncToFocusState() }
        }
    }

    private func syncToFocusState() {
        guard let timerEngine, let settings,
              timerEngine.phase == .focus, timerEngine.isRunning,
              let sound = AmbientSound(rawValue: settings.ambientSound), sound != .none
        else { stop(); return }
        play(sound, volume: settings.ambientVolume)
    }

    private func play(_ sound: AmbientSound, volume: Double) {
        if currentSound == sound, player.isPlaying {
            fade(to: Float(volume), duration: 0.25)
            return
        }

        fadeTask?.cancel()
        player.stop()
        audioEngine.stop()
        currentSound = sound

        guard let url = Bundle.main.url(forResource: sound.rawValue,
                                        withExtension: "wav",
                                        subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav")
        else {
            lastError = "Missing ambient sound: \(sound.rawValue)"
            return
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                                 frameCapacity: AVAudioFrameCount(file.length))
            else { return }
            try file.read(into: buffer)
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            audioEngine.mainMixerNode.outputVolume = 0
            try audioEngine.start()
            player.play()
            isPlaying = true
            fade(to: Float(volume), duration: 0.8)
        } catch {
            lastError = error.localizedDescription
            player.stop()
            audioEngine.stop()
            isPlaying = false
        }
    }

    private func stop() {
        previewTask?.cancel()
        guard player.isPlaying || audioEngine.isRunning else {
            isPlaying = false
            currentSound = nil
            return
        }
        fade(to: 0, duration: 0.8) { [weak self] in
            guard let self else { return }
            self.player.stop()
            self.audioEngine.stop()
            self.currentSound = nil
            self.isPlaying = false
        }
    }

    private func fade(to target: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeTask?.cancel()
        let start = audioEngine.mainMixerNode.outputVolume
        let steps = max(1, Int(duration / 0.05))
        fadeTask = Task { [weak self] in
            for step in 1...steps {
                guard !Task.isCancelled else { return }
                let progress = Float(step) / Float(steps)
                await MainActor.run {
                    self?.audioEngine.mainMixerNode.outputVolume = start + (target - start) * progress
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { completion?() }
        }
    }
}
