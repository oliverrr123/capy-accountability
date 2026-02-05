//
//  CapyBrain.swift
//  capyaccountability
//
//  Created by Hodan on 03.02.2026.
//

import Foundation
import SwiftUI
import Combine

enum CapyResult {
    case reply(String)
    case finished(UserGoals)
}

class CapyBrain: ObservableObject {
    private let endpoint = URL(string: "https://ai.hackclub.com/proxy/v1/chat/completions")!

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
                                "items": ["type": "string"],
                                "description": "List of life/long-term goals"
                            ],
                            "decade": [
                                "type": "array",
                                "items": ["type": "string"],
                                "description": "List of 10-year goals"
                            ],
                            "yearly": [
                                "type": "array",
                                "items": ["type": "string"],
                                "description": "List of 1-year goals"
                            ],
                            "monthly": [
                                "type": "array",
                                "items": ["type": "string"],
                                "description": "List of monthly goals"
                            ],
                            "weekly": [
                                "type": "array",
                                "items": ["type": "string"],
                                "description": "List of weekly goals"
                            ],
                            "daily": [
                                "type": "array",
                                "items": ["type": "string"],
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

        let response = try await requestChatCompletion(parameters: parameters)
        let choice = response.choices.first
        
        if let toolCalls = choice?.message.tool_calls, let firstTool = toolCalls.first {
            if firstTool.function.name == "submit_goals" {
                let argsString = firstTool.function.arguments
                
                print("---")
                print(argsString)
                print("---")
                
                if let argsData = argsString.data(using: .utf8) {
                    let goals = try JSONDecoder().decode(UserGoals.self, from: argsData)
                    return .finished(goals)
                }
            }
        }
        
        return .reply(choice?.message.content ?? "Thinking...")
    }

    func coachReply(userMessage: String, goals: [String], completedCount: Int, pendingCount: Int) async -> String {
        let fallback = fallbackCoachReply(userMessage: userMessage, goals: goals, pendingCount: pendingCount)
        guard !apiKey.isEmpty else { return fallback }

        let goalsContext = goals.prefix(4).joined(separator: ", ")
        let contextSummary = goalsContext.isEmpty ? "No active goals provided yet." : goalsContext

        let systemMessage = [
            "role": "system",
            "content": """
            You are Capy, an AI accountability capybara.
            Keep replies very short (1-3 sentences), practical, and warm.
            Ask a direct follow-up question often.
            Refer to one concrete goal when possible.
            """
        ]

        let userPayload = """
        User message: \(userMessage)
        Active goals: \(contextSummary)
        Completed tasks: \(completedCount)
        Pending tasks: \(pendingCount)
        """

        let userContext = [
            "role": "user",
            "content": userPayload
        ]

        let parameters: [String: Any] = [
            "model": "x-ai/grok-4.1-fast",
            "messages": [systemMessage, userContext]
        ]

        do {
            let response = try await requestChatCompletion(parameters: parameters)
            let text = response.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return text.isEmpty ? fallback : text
        } catch {
            print("Coach reply error: \(error)")
            return fallback
        }
    }

    private func requestChatCompletion(parameters: [String: Any]) async throws -> ChatCompletionResponse {
        var request = URLRequest(url: endpoint, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let bodyText = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(
                domain: "CapyBrain",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "AI request failed (\(httpResponse.statusCode)): \(bodyText)"]
            )
        }

        return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
    }

    private func fallbackCoachReply(userMessage: String, goals: [String], pendingCount: Int) -> String {
        let lowercased = userMessage.lowercased()
        if lowercased.contains("done") || lowercased.contains("finished") {
            if let nextGoal = goals.first {
                return "Huge win. Want to roll straight into \"\(nextGoal)\" next?"
            }
            return "Huge win. Want to lock in another small task right now?"
        }
        if lowercased.contains("stuck") || lowercased.contains("hard") {
            let focus = goals.first ?? "your top task"
            return "Let's shrink it. What's the smallest 10-minute step for \"\(focus)\"?"
        }
        if pendingCount == 0 {
            return "You cleared everything. Want to add one stretch goal for today?"
        }
        let focus = goals.randomElement() ?? "your next goal"
        return "Quick check-in: what's one concrete step you can do now for \"\(focus)\"?"
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
