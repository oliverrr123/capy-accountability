//
//  Untitled.swift
//  capyaccountability
//
//  Created by Hodan on 03.02.2026.
//

import AVFoundation
import Combine
import SwiftUI

final class MicLevelMeter: ObservableObject {
    @Published var level: CGFloat = 0
    @Published var isRunning: Bool = false
    
    private let engine = AVAudioEngine()
    private var session = AVAudioSession.sharedInstance()
    
    private var smoothed: CGFloat = 0
    private let smoothing: CGFloat = 0.2
    
    func start() {
        guard !isRunning else { return }
        
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setActive(true)
            
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                let rms = self.rms(from: buffer)
                let normalized = self.normalize(rms: rms)
                
                self.smoothed = self.smoothed + (normalized - self.smoothed) * self.smoothing
                DispatchQueue.main.async {
                    self.level = self.smoothed
                }
            }
            
            engine.prepare()
            try engine.start()
            
            DispatchQueue.main.async { self.isRunning = true }
        } catch {
            print("Mic start error: ", error)
            stop()
        }
    }
    
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? session.setActive(false)
        DispatchQueue.main.async {
            self.isRunning = false
            self.level = 0
        }
    }
    
    private func rms(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            let x = channelData[i]
            sum += x * x
        }
        return sqrt(sum / Float(frameLength))
    }
    
    private func normalize(rms: Float) -> CGFloat {
        let db = 20 * log10(max(rms, 0.000_01))
        let minDb: Float = -50
        let maxDb: Float = -5
        let clamped = min(max(db, minDb), maxDb)
        let normalized = (clamped - minDb) / (maxDb - minDb)
        return CGFloat(normalized)
    }
}

struct SoundBars: View {
    var level: CGFloat
    
    private let weights: [CGFloat] = [0.15, 0.65, 1.0, 0.75, 0.95, 0.5]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(weights.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .frame(width: 14, height: barHeight(weights[i]))
            }
        }
        .animation(.easeIn(duration: 0.02), value: level)
    }
    
    private func barHeight(_ w: CGFloat) -> CGFloat {
        let base: CGFloat = 20
        let maxExtra: CGFloat = 170
        return base + (level * maxExtra * w)
    }
}
