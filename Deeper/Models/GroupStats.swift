//
//  GroupStats.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

struct GroupInfo: Identifiable, Codable {
    let id: String
    let title: String
    let platform: Platform
    let memberCount: Int
    let unreadCount: Int
    let lastActivity: Date?
    let isMuted: Bool
    let isPinned: Bool
    var messageCount: Int = 0
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
}

struct PlatformGroupStats: Identifiable, Codable {
    let platform: Platform
    var groups: [GroupInfo] = []
    var totalGroups: Int { groups.count }
    var totalMembers: Int { groups.reduce(0) { $0 + $1.memberCount } }
    var totalUnread: Int { groups.reduce(0) { $0 + $1.unreadCount } }
    var mutedCount: Int { groups.filter(\.isMuted).count }
    var pinnedCount: Int { groups.filter(\.isPinned).count }

    var id: String { platform.rawValue }
}
