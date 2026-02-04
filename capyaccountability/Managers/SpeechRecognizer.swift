//
//  SpeechRecognizer.swift
//  capyaccountability
//
//  Created by Hodan on 03.02.2026.
//

import Speech
import Combine
import AVFoundation

class SpeechRecognizer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var soundLevel: Float = 0.0
    
    private var silenceTimer: Timer?
    
    func startTranscribing() {
        guard !isRecording else { return }
        
        transcript = ""
        isRecording = true
        soundLevel = 0.0
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            stopTranscribing()
            return
        }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                self.resetSilenceTimer()
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscribing()
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { [weak self] buffer, _ in
            self?.request?.append(buffer)
            self?.calculateLevel(buffer: buffer)
        })
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func stopTranscribing() {
        silenceTimer?.invalidate()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.soundLevel = 0.0
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            print("Silence detected")
            self?.stopTranscribing()
        }
    }
    
    private func calculateLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = UInt(buffer.frameLength)
        
        var totalSq: Float = 0.0
        for i in 0..<Int(frameLength) {
            totalSq += channelData[i] * channelData[i]
        }
        
        let rms = sqrt(totalSq / Float(frameLength))
        let visualLevel = min(max(rms * 5, 0), 1.0)
        
        DispatchQueue.main.async {
            self.soundLevel = visualLevel
        }
    }
}
