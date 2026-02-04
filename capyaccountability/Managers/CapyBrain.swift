//
//  CapyBrain.swift
//  capyaccountability
//
//  Created by Hodan on 03.02.2026.
//

import Foundation
import SwiftUI
import Combine

class CapyBrain: ObservableObject {
    private var apiKey: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "AIApiKey") as? String else {
            print("No API Key")
            return ""
        }
        if value.hasPrefix("\"") && value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
    
    func talkToCapy(messages: [[String: String]]) async throws -> String {
        guard !apiKey.isEmpty else { return "No API Key >.<" }
        
        let url = URL(string: "https://ai.hackclub.com/proxy/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = [
            "role": "system",
            "content": "You are a friendly, chill Capybara named Capy. You speak in short sentences. You love hot springs and yuzu. You are an accountability partner."
        ]
        
        
        let parameters: [String: Any] = [
            "model": "x-ai/grok-4.1-fast",
            "messages": [systemMessage] + messages
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? "Error >.<"
    }
}

struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String
}
