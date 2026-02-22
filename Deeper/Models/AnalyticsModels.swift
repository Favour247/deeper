//
//  AnalyticsModels.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 23.02.2026.
//

import Foundation

// MARK: - Phrase Analytics

struct WordFrequency: Identifiable, Codable {
    let word: String
    var count: Int
    var id: String { word }
}

struct PhraseStats: Codable {
    var topWords: [WordFrequency] = []
    var topBigrams: [WordFrequency] = []
    var totalWords: Int = 0
    var uniqueWords: Int = 0
    var averageMessageLength: Double = 0
}

// MARK: - Response Time

struct PersonResponseTime: Identifiable, Codable {
    let personName: String
    let platform: Platform
    var myAvgResponseSec: Double
    var theirAvgResponseSec: Double
    var myResponseCount: Int
    var theirResponseCount: Int

    var id: String { "\(personName)_\(platform.rawValue)" }

    var myAvgFormatted: String {
        Self.format(seconds: myAvgResponseSec)
    }

    var theirAvgFormatted: String {
        Self.format(seconds: theirAvgResponseSec)
    }

    static func format(seconds: Double) -> String {
        if seconds < 60 { return "\(Int(seconds))s" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86400 { return String(format: "%.1fh", seconds / 3600) }
        return String(format: "%.1fd", seconds / 86400)
    }
}

struct ResponseTimeStats: Codable {
    var perPerson: [PersonResponseTime] = []
    var overallMyAvgSec: Double = 0
    var overallTheirAvgSec: Double = 0
    var totalMyResponses: Int = 0
    var totalTheirResponses: Int = 0

    var myAvgFormatted: String {
        PersonResponseTime.format(seconds: overallMyAvgSec)
    }

    var theirAvgFormatted: String {
        PersonResponseTime.format(seconds: overallTheirAvgSec)
    }
}
