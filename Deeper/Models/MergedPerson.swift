//
//  MergedPerson.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

struct PlatformPresence: Identifiable, Sendable {
    let platform: Platform
    let accountID: String
    let userID: String
    var chatIDs: [String] = []
    var messageCount: Int = 0
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var lastActivity: Date?

    var id: String { "\(accountID)_\(userID)" }
}

struct MergedPerson: Identifiable, Hashable, Sendable {
    static func == (lhs: MergedPerson, rhs: MergedPerson) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: String // normalized fullName
    let displayName: String
    var avatarURL: String?
    var presences: [PlatformPresence] = []
    var totalMessageCount: Int = 0
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var lastActivity: Date?

    var platforms: [Platform] {
        Array(Set(presences.map(\.platform))).sorted { $0.displayName < $1.displayName }
    }

    var platformCount: Int {
        Set(presences.map(\.platform)).count
    }

    /// 0.0 = completely one-sided, 1.0 = perfectly balanced
    var reciprocityScore: Double {
        let s = Double(messagesSent)
        let r = Double(messagesReceived)
        guard s + r > 0 else { return 0 }
        return min(s, r) / max(s, r)
    }

    var connectionType: ConnectionType {
        guard totalMessageCount > 0 else { return .inactive }
        if messagesSent == 0 && messagesReceived > 0 { return .iGhost }
        if messagesReceived == 0 && messagesSent > 0 { return .theyGhost }
        if reciprocityScore >= 0.3 { return .twoWay }
        if messagesSent > messagesReceived { return .theyGhost }
        return .iGhost
    }
}

enum ConnectionType: String, CaseIterable, Identifiable, Sendable {
    case twoWay = "Two-Way"
    case theyGhost = "Ghosted By"
    case iGhost = "I Ghost"
    case inactive = "Inactive"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .twoWay: "arrow.left.arrow.right"
        case .theyGhost: "eye.slash.fill"
        case .iGhost: "moon.zzz.fill"
        case .inactive: "minus.circle"
        }
    }

    var label: String {
        switch self {
        case .twoWay: "Two-Way Connected"
        case .theyGhost: "They Ghost Me"
        case .iGhost: "I Ghost Them"
        case .inactive: "Inactive"
        }
    }
}

struct ReelShareEntry: Identifiable, Sendable {
    let id: String // chatID
    let personName: String
    let chatTitle: String
    let platform: Platform
    var reelsSent: Int = 0
    var reelsReceived: Int = 0
    var lastReelDate: Date?
    var totalReels: Int { reelsSent + reelsReceived }
}

struct PlatformStats: Identifiable, Sendable {
    let platform: Platform
    var chatCount: Int = 0
    var messageCount: Int = 0
    var groupCount: Int = 0
    var dmCount: Int = 0
    var unreadCount: Int = 0
    var topContacts: [MergedPerson] = []

    var id: String { platform.rawValue }
}
