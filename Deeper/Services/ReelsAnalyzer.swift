//
//  ReelsAnalyzer.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

enum ReelsAnalyzer {
    static func analyzeReels(
        messages: [BeeperMessage],
        chats: [String: BeeperChat]
    ) -> [ReelShareEntry] {
        var entriesByChat: [String: ReelShareEntry] = [:]

        for message in messages {
            guard let attachments = message.attachments, !attachments.isEmpty else { continue }

            let hasVideo = attachments.contains { att in
                att.type == .video && att.isSticker != true && att.isGif != true
            }
            let hasImage = attachments.contains { att in
                att.type == .img && att.isSticker != true && att.isGif != true
            }

            guard hasVideo || hasImage else { continue }

            let chatID = message.chatID
            let chat = chats[chatID]
            let chatTitle = chat?.title ?? chatID
            let platform = Platform.from(accountID: message.accountID)
            let personName = chat?.participants.items.first(where: { $0.isSelf != true })?.displayName ?? chatTitle

            if entriesByChat[chatID] == nil {
                entriesByChat[chatID] = ReelShareEntry(
                    id: chatID,
                    personName: personName,
                    chatTitle: chatTitle,
                    platform: platform
                )
            }

            if message.isSender == true {
                entriesByChat[chatID]?.reelsSent += 1
            } else {
                entriesByChat[chatID]?.reelsReceived += 1
            }

            if let timestamp = entriesByChat[chatID]?.lastReelDate {
                if message.timestamp > timestamp {
                    entriesByChat[chatID]?.lastReelDate = message.timestamp
                }
            } else {
                entriesByChat[chatID]?.lastReelDate = message.timestamp
            }
        }

        return entriesByChat.values.sorted { $0.totalReels > $1.totalReels }
    }
}
