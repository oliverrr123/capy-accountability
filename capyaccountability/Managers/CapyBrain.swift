//
//  CapyBrain.swift
//  capyaccountability
//
//  Created by Hodan on 03.02.2026.
//

import Foundation
import SwiftUI
import Combine

struct UserGoals: Codable {
    let longTerm: [String]
    let decade: [String]
    let yearly: [String]
    let monthly: [String]
    let weekly: [String]
    let daily: [String]
    
    enum CodingKeys: String, CodingKey {
        case longTerm = "long_term"
        case decade, yearly, monthly, weekly, daily
    }
}

enum CapyResult {
    case reply(String)
    case finished(UserGoals)
}

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
    
    func talkToCapy(messages: [[String: String]]) async throws -> CapyResult {
        guard !apiKey.isEmpty else { return .reply("No API Key >.<") }
        
        let url = URL(string: "https://ai.hackclub.com/proxy/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemMessage = [
            "role": "system",
            "content": """
            You are a friendly, chill Capybara named Capy. You speak in short sentences. You love hot springs and yuzu. You are an accountability partner.
            
            You are an accountability partner guiding the user through an onboarding process.
            Your goal is to collect their goals in this specific order:
            1. Long-term / Life goals
            2. Decade goals (10 years)
            3. Yearly goals
            4. Monthly goals
            5. Weekly goals
            6. Daily habits/goals
            
            Ask one question at a time. Be helpful.
            IMPORTANT: When you have collected ALL 6 levels of goals, do not reply with text. Instead, call the 'submit_goals' function immediately.
            """
        ]
        
        let tools: [[String: Any]] = [
            [
                "type": "function",
                "function": [
                    "name": "submit_goals",
                    "description": "Call this when you have collected all goal levels. Split distinct goals into separate items in the list.",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "long_term": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of life/long-term goals"
                            ],
                            "decade": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of 10-year goals"
                            ],
                            "yearly": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of 1-year goals"
                            ],
                            "monthly": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of monthly goals"
                            ],
                            "weekly": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of weekly goals"
                            ],
                            "daily": [
                                "type": "array",
                                "item": ["type", "string"],
                                "description": "List of daily habits"
                            ]
                        ],
                        "required": ["long_term", "decade", "yearly", "monthly", "weekly", "daily"]
                    ]
                ]
            ]
        ]
        
        let parameters: [String: Any] = [
            "model": "x-ai/grok-4.1-fast",
            "messages": [systemMessage] + messages,
            "tools": tools,
            "tool_choice": "auto"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let choice = response.choices.first
        
        if let toolCalls = choice?.message.tool_calls, let firstTool = toolCalls.first {
            if firstTool.function.name == "submit_goals" {
                let argsString = firstTool.function.arguments
                if let argsData = argsString.data(using: .utf8) {
                    let goals = try JSONDecoder().decode(UserGoals.self, from: argsData)
                    return .finished(goals)
                }
            }
        }
        
        return .reply(choice?.message.content ?? "Thinking...")
    }
}

struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String?
    let tool_calls: [ToolCall]?
}

struct ToolCall: Decodable {
    let function: FunctionCall
}

struct FunctionCall: Decodable {
    let name: String
    let arguments: String
}
