//
//  HapticsEngine.swift
//  capyaccountability
//
//  Created by Hodan on 08.02.2026.
//

import CoreHaptics

class HapticEngine {
    static let shared = HapticEngine()
    
    private var engine: CHHapticEngine?
    
    init() {
        try? engine = CHHapticEngine()
        try? engine?.start()
    }
    
    func playCustomTexture() {
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
    
    func playPurr() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [sharpness, intensity],
            relativeTime: 0,
            duration: 1.5
        )
        
        do {
            try engine?.start()
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play purr: \(error)")
        }
    }
    
    func playDoubleThud() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        
        let eventA = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0
        )
        
        let eventB = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [sharpness, intensity],
            relativeTime: 0.15
        )
        
    
        do {
            try engine?.start()
            let pattern = try CHHapticPattern(events: [eventA, eventB], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play double thud: \(error)")
        }
    }
    
    func playCoinShower() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events: [CHHapticEvent] = []
        
        for i in 0..<10 {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float.random(in: 0.3...0.8))
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [sharpness, intensity],
                relativeTime: TimeInterval(i) * 0.04
            )
            events.append(event)
        }
        
        do {
            try engine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play coin shower: \(error)")
        }
    }
    
    func playSwell() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let continuousEvent = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            ],
            relativeTime: 0,
            duration: 1.0
        )
        
        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0.0, value: 0.1),
                .init(relativeTime: 0.5, value: 1.0),
                .init(relativeTime: 1.0, value: 0.0)
            ],
            relativeTime: 0
        )
        
        do {
            try engine?.start()
            let pattern = try CHHapticPattern(events: [continuousEvent], parameterCurves: [curve])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play swell: \(error)")
        }
    }
}
