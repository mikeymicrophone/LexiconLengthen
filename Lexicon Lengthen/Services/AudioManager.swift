//
//  AudioManager.swift
//  Lexicon Lengthen
//
//  Created by Mike Schwab on 1/17/26.
//

import Foundation
import AVFoundation
import Combine

/// Manages audio playback and recording for pronunciations.
@MainActor
final class AudioManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var playbackProgress: Double = 0
    @Published var recordingDuration: TimeInterval = 0

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var progressTimer: Timer?

    // MARK: - Initialization

    nonisolated override init() {
        super.init()
    }

    // MARK: - Audio Session Configuration

    /// Configures the audio session for playback and recording
    func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    // MARK: - Playback

    /// Plays audio from data
    func play(data: Data) throws {
        stopPlayback()

        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()

        isPlaying = true
        startProgressTracking()
    }

    /// Plays audio from a URL
    func play(url: URL) throws {
        stopPlayback()

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()

        isPlaying = true
        startProgressTracking()
    }

    /// Plays a pronunciation, falling back to TTS if no audio data
    func play(pronunciation: Pronunciation) throws {
        if let audioData = pronunciation.audioData {
            try play(data: audioData)
        } else if let ttsText = pronunciation.ttsOptimizedText ?? pronunciation.word?.spellingText {
            let languageCode = pronunciation.accentDialect?.language?.code ?? "en"
            speakText(ttsText, languageCode: languageCode)
        }
    }

    /// Plays backwards audio for a pronunciation
    func playBackwards(pronunciation: Pronunciation) throws {
        guard let backwardsData = pronunciation.audioBackwardsData else {
            throw AudioManagerError.noBackwardsAudio
        }
        try play(data: backwardsData)
    }

    /// Stops current playback
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        speechSynthesizer?.stopSpeaking(at: .immediate)
        isPlaying = false
        playbackProgress = 0
        stopProgressTracking()
    }

    /// Pauses current playback
    func pausePlayback() {
        audioPlayer?.pause()
        speechSynthesizer?.pauseSpeaking(at: .immediate)
        isPlaying = false
        stopProgressTracking()
    }

    /// Resumes paused playback
    func resumePlayback() {
        audioPlayer?.play()
        speechSynthesizer?.continueSpeaking()
        isPlaying = true
        startProgressTracking()
    }

    // MARK: - Text-to-Speech

    /// Speaks text using system TTS
    func speakText(_ text: String, languageCode: String = "en", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        stopPlayback()

        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: voiceIdentifier(for: languageCode))

        speechSynthesizer?.speak(utterance)
        isPlaying = true
    }

    /// Maps language codes to voice identifiers
    private func voiceIdentifier(for languageCode: String) -> String {
        switch languageCode {
        case "en": return "en-US"
        case "es": return "es-ES"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        case "it": return "it-IT"
        case "pt": return "pt-BR"
        case "ja": return "ja-JP"
        case "zh": return "zh-CN"
        case "ko": return "ko-KR"
        default: return languageCode
        }
    }

    /// Returns available voices for a language
    func availableVoices(for languageCode: String) -> [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix(languageCode)
        }
    }

    // MARK: - Recording

    /// Starts recording audio
    func startRecording() throws -> URL {
        stopRecording()

        let url = temporaryRecordingURL()

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        try configureAudioSession()

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()

        isRecording = true
        startRecordingTimer()

        return url
    }

    /// Stops recording and returns the recorded data
    func stopRecording() -> Data? {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return nil
        }

        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
        stopRecordingTimer()

        return try? Data(contentsOf: url)
    }

    /// Generates a temporary URL for recording
    private func temporaryRecordingURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
        let filename = "recording_\(UUID().uuidString).m4a"
        return directory.appendingPathComponent(filename)
    }

    // MARK: - Progress Tracking

    private func startProgressTracking() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
                self.playbackProgress = player.currentTime / player.duration
            }
        }
    }

    private func stopProgressTracking() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func startRecordingTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.recordingDuration = recorder.currentTime
            }
        }
    }

    private func stopRecordingTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Audio Processing

    /// Reverses audio data for backwards playback feature
    static func reverseAudio(data: Data) throws -> Data {
        // Create a temporary file for the input
        let tempInputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("input_\(UUID().uuidString).m4a")
        let tempOutputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("output_\(UUID().uuidString).m4a")

        defer {
            try? FileManager.default.removeItem(at: tempInputURL)
            try? FileManager.default.removeItem(at: tempOutputURL)
        }

        try data.write(to: tempInputURL)

        // Use AVAsset to read and reverse the audio
        let asset = AVURLAsset(url: tempInputURL)

        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            throw AudioManagerError.noAudioTrack
        }

        // Read all samples
        guard let reader = try? AVAssetReader(asset: asset) else {
            throw AudioManagerError.cannotCreateReader
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(readerOutput)
        reader.startReading()

        var samples: [Data] = []
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                var length = 0
                var dataPointer: UnsafeMutablePointer<Int8>?
                CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
                if let pointer = dataPointer {
                    samples.append(Data(bytes: pointer, count: length))
                }
            }
        }

        // Reverse the samples
        samples.reverse()

        // Combine reversed samples
        var reversedData = Data()
        for sample in samples {
            reversedData.append(sample)
        }

        return reversedData
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            playbackProgress = 0
            stopProgressTracking()
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}

// MARK: - Errors

enum AudioManagerError: LocalizedError {
    case noBackwardsAudio
    case noAudioTrack
    case cannotCreateReader
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .noBackwardsAudio:
            return "No backwards audio available for this pronunciation"
        case .noAudioTrack:
            return "No audio track found in the audio file"
        case .cannotCreateReader:
            return "Cannot create audio reader"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}
