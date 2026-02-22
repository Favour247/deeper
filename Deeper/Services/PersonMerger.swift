//
//  PersonMerger.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

enum PersonMerger {
    static func merge(chats: [BeeperChat]) -> [MergedPerson] {
        var personMap: [String: MergedPerson] = [:]

        for chat in chats {
            let platform = Platform.from(accountID: chat.accountID)

            for participant in chat.participants.items {
                guard participant.isSelf != true else { continue }

                let name = participant.displayName
                let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if personMap[key] == nil {
                    personMap[key] = MergedPerson(
                        id: key,
                        displayName: name,
                        avatarURL: participant.imgURL
                    )
                }

                if let existingIdx = personMap[key]?.presences.firstIndex(where: {
                    $0.accountID == chat.accountID && $0.userID == participant.id
                }) {
                    personMap[key]?.presences[existingIdx].chatIDs.append(chat.id)
                    if let activity = chat.lastActivity,
                       (personMap[key]?.presences[existingIdx].lastActivity ?? .distantPast) < activity {
                        personMap[key]?.presences[existingIdx].lastActivity = activity
                    }
                } else {
                    let presence = PlatformPresence(
                        platform: platform,
                        accountID: chat.accountID,
                        userID: participant.id,
                        chatIDs: [chat.id],
                        lastActivity: chat.lastActivity
                    )
                    personMap[key]?.presences.append(presence)
                }

                if personMap[key]?.avatarURL == nil, let url = participant.imgURL {
                    personMap[key]?.avatarURL = url
                }

                if let activity = chat.lastActivity {
                    if (personMap[key]?.lastActivity ?? .distantPast) < activity {
                        personMap[key]?.lastActivity = activity
                    }
                }
            }
        }

        return personMap.values
            .sorted { ($0.lastActivity ?? .distantPast) > ($1.lastActivity ?? .distantPast) }
    }

    struct ChatMessageBreakdown {
        var sent: Int = 0
        var received: Int = 0
        var total: Int { sent + received }
    }

    static func updateMessageCounts(
        persons: inout [MergedPerson],
        chatBreakdowns: [String: ChatMessageBreakdown]
    ) {
        for i in persons.indices {
            var totalSent = 0
            var totalReceived = 0
            for j in persons[i].presences.indices {
                var presenceSent = 0
                var presenceReceived = 0
                for chatID in persons[i].presences[j].chatIDs {
                    if let bd = chatBreakdowns[chatID] {
                        presenceSent += bd.sent
                        presenceReceived += bd.received
                    }
                }
                persons[i].presences[j].messagesSent = presenceSent
                persons[i].presences[j].messagesReceived = presenceReceived
                persons[i].presences[j].messageCount = presenceSent + presenceReceived
                totalSent += presenceSent
                totalReceived += presenceReceived
            }
            persons[i].messagesSent = totalSent
            persons[i].messagesReceived = totalReceived
            persons[i].totalMessageCount = totalSent + totalReceived
        }
        persons.sort { $0.totalMessageCount > $1.totalMessageCount }
    }

    static func categorize(_ persons: [MergedPerson]) -> (twoWay: [MergedPerson], theyGhost: [MergedPerson], iGhost: [MergedPerson]) {
        let active = persons.filter { $0.totalMessageCount > 0 }
        let twoWay = active.filter { $0.connectionType == .twoWay }
            .sorted { $0.totalMessageCount > $1.totalMessageCount }
        let theyGhost = active.filter { $0.connectionType == .theyGhost }
            .sorted { $0.messagesSent > $1.messagesSent }
        let iGhost = active.filter { $0.connectionType == .iGhost }
            .sorted { $0.messagesReceived > $1.messagesReceived }
        return (twoWay, theyGhost, iGhost)
    }

    static func computePlatformStats(chats: [BeeperChat]) -> [PlatformStats] {
        var statsMap: [Platform: PlatformStats] = [:]

        for chat in chats {
            let platform = chat.platform
            if statsMap[platform] == nil {
                statsMap[platform] = PlatformStats(platform: platform)
            }
            statsMap[platform]?.chatCount += 1
            statsMap[platform]?.unreadCount += chat.unreadCount

            switch chat.type {
            case .group:
                statsMap[platform]?.groupCount += 1
            case .single:
                statsMap[platform]?.dmCount += 1
            }
        }

        return statsMap.values.sorted { $0.chatCount > $1.chatCount }
    }
}
