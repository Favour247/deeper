//
//  BeeperModels.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

// MARK: - User

struct BeeperUser: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var username: String?
    var phoneNumber: String?
    var email: String?
    var fullName: String?
    var imgURL: String?
    var cannotMessage: Bool?
    var isSelf: Bool?

    var displayName: String {
        fullName ?? username ?? phoneNumber ?? email ?? id
    }
}

// MARK: - Account

struct BeeperAccount: Codable, Identifiable, Sendable {
    let accountID: String
    let user: BeeperUser

    var id: String { accountID }

    var platform: Platform {
        Platform.from(accountID: accountID)
    }
}

// MARK: - Chat

struct BeeperChat: Codable, Identifiable, Sendable {
    let id: String
    var localChatID: String?
    let accountID: String
    let title: String
    let type: ChatType
    let participants: ChatParticipants
    let unreadCount: Int
    var lastActivity: Date?
    var lastReadMessageSortKey: String?
    var isArchived: Bool?
    var isMuted: Bool?
    var isPinned: Bool?
    var preview: BeeperMessage?

    enum ChatType: String, Codable, Sendable {
        case single
        case group
    }

    var platform: Platform {
        Platform.from(accountID: accountID)
    }
}

struct ChatParticipants: Codable, Sendable {
    let items: [BeeperUser]
    let hasMore: Bool
    let total: Int
}

// MARK: - Message

struct BeeperMessage: Codable, Identifiable, Sendable {
    let id: String
    let chatID: String
    let accountID: String
    let senderID: String
    var senderName: String?
    let timestamp: Date
    let sortKey: String
    var type: MessageType?
    var text: String?
    var isSender: Bool?
    var attachments: [BeeperAttachment]?
    var isUnread: Bool?
    var linkedMessageID: String?
    var reactions: [BeeperReaction]?

    enum MessageType: String, Codable, Sendable {
        case TEXT, NOTICE, IMAGE, VIDEO, VOICE, AUDIO, FILE, STICKER, LOCATION, REACTION
    }
}

// MARK: - Attachment

struct BeeperAttachment: Codable, Sendable {
    var id: String?
    let type: AttachmentType
    var srcURL: String?
    var mimeType: String?
    var fileName: String?
    var fileSize: Double?
    var isGif: Bool?
    var isSticker: Bool?
    var isVoiceNote: Bool?
    var duration: Double?
    var posterImg: String?
    var size: AttachmentSize?

    enum AttachmentType: String, Codable, Sendable {
        case unknown, img, video, audio
    }

    struct AttachmentSize: Codable, Sendable {
        var width: Double?
        var height: Double?
    }
}

// MARK: - Reaction

struct BeeperReaction: Codable, Sendable {
    let id: String
    let reactionKey: String
    let participantID: String
    var imgURL: String?
    var emoji: Bool?
}

// MARK: - API Responses

struct ListChatsResponse: Codable, Sendable {
    let items: [BeeperChat]
    let hasMore: Bool
    let oldestCursor: String?
    let newestCursor: String?
}

struct ListMessagesResponse: Codable, Sendable {
    let items: [BeeperMessage]
    let hasMore: Bool
}

struct SearchMessagesResponse: Codable, Sendable {
    let items: [BeeperMessage]
    let chats: [String: BeeperChat]?
    let hasMore: Bool
    let oldestCursor: String?
    let newestCursor: String?
}

struct SearchChatsResponse: Codable, Sendable {
    let items: [BeeperChat]
    let hasMore: Bool
    let oldestCursor: String?
    let newestCursor: String?
}

struct ConnectInfoResponse: Codable, Sendable {
    let app: AppInfo
    let platform: PlatformInfo
    let server: ServerInfo
    let endpoints: EndpointsInfo

    struct AppInfo: Codable, Sendable {
        let name: String
        let version: String
        let bundle_id: String
    }

    struct PlatformInfo: Codable, Sendable {
        let os: String
        let arch: String
        var release: String?
    }

    struct ServerInfo: Codable, Sendable {
        let status: String
        let base_url: String
        let port: Int
        let hostname: String
        let remote_access: Bool
        let mcp_enabled: Bool
    }

    struct EndpointsInfo: Codable, Sendable {
        let oauth: OAuthEndpoints
        let spec: String
        let mcp: String
        let ws_events: String

        struct OAuthEndpoints: Codable, Sendable {
            let authorization_endpoint: String
            let token_endpoint: String
            let introspection_endpoint: String
            let userinfo_endpoint: String
            let revocation_endpoint: String
            let registration_endpoint: String
        }
    }
}

// MARK: - WebSocket Events

struct WSEvent: Codable, Sendable {
    let type: String
    var chat: BeeperChat?
    var message: BeeperMessage?
    var chatID: String?
    var messageID: String?
}
