//
//  DataStore.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

@Observable
final class DataStore {
    // MARK: - Raw data
    var accounts: [BeeperAccount] = []
    var allChats: [BeeperChat] = []
    var chatBreakdowns: [String: PersonMerger.ChatMessageBreakdown] = [:]

    // MARK: - Computed / derived
    var mergedPeople: [MergedPerson] = []
    var twoWayPeople: [MergedPerson] = []
    var theyGhostPeople: [MergedPerson] = []
    var iGhostPeople: [MergedPerson] = []
    var platformStats: [PlatformStats] = []
    var hourlyActivity: [HourlyActivityPoint] = []

    // MARK: - Groups
    var groupStats: [PlatformGroupStats] = []

    // MARK: - Reels
    var reelEntries: [ReelShareEntry] = []
    var totalReelsSent: Int = 0
    var totalReelsReceived: Int = 0
    var hasInstagram = false

    // MARK: - Summary
    var totalChats: Int = 0
    var totalUnread: Int = 0
    var messagesSentToday: Int = 0
    var messagesReceivedToday: Int = 0

    // MARK: - State
    var isLoading = false
    var loadingProgress: String?
    var error: String?
    var lastSyncDate: Date?
    var isCached: Bool { lastSyncDate != nil }

    private let api: BeeperAPIClient

    init(api: BeeperAPIClient) {
        self.api = api
    }

    // MARK: - Full sync

    func loadIfNeeded() async {
        guard !isCached && !isLoading else { return }
        await sync()
    }

    func sync() async {
        isLoading = true
        error = nil
        loadingProgress = "Fetching accounts..."

        do {
            // 1. Accounts
            let fetchedAccounts = try await api.getAccounts()
            accounts = fetchedAccounts

            // 2. All chats
            loadingProgress = "Fetching all chats..."
            let fetchedChats = try await api.fetchAllChats { count in
                self.loadingProgress = "Fetching chats (\(count))..."
            }
            allChats = fetchedChats
            totalChats = fetchedChats.count
            totalUnread = fetchedChats.reduce(0) { $0 + $1.unreadCount }

            // 3. Platform stats
            loadingProgress = "Computing platform stats..."
            platformStats = PersonMerger.computePlatformStats(chats: fetchedChats)

            // 4. Group stats
            loadingProgress = "Computing group stats..."
            var groupMap: [Platform: [GroupInfo]] = [:]
            for chat in fetchedChats where chat.type == .group {
                let platform = chat.platform
                let info = GroupInfo(
                    id: chat.id,
                    title: chat.title,
                    platform: platform,
                    memberCount: chat.participants.total,
                    unreadCount: chat.unreadCount,
                    lastActivity: chat.lastActivity,
                    isMuted: chat.isMuted ?? false,
                    isPinned: chat.isPinned ?? false
                )
                groupMap[platform, default: []].append(info)
            }
            groupStats = groupMap.map { platform, groups in
                PlatformGroupStats(
                    platform: platform,
                    groups: groups.sorted { ($0.lastActivity ?? .distantPast) > ($1.lastActivity ?? .distantPast) }
                )
            }.sorted { $0.totalGroups > $1.totalGroups }

            // 5. Merge people
            loadingProgress = "Merging people..."
            var merged = PersonMerger.merge(chats: fetchedChats)

            // 5. Analyze DMs: sent/received + hourly
            let dmChats = fetchedChats.filter { $0.type == .single }
            var breakdowns: [String: PersonMerger.ChatMessageBreakdown] = [:]
            let calendar = Calendar.current
            var hourlyMap: [Platform: [Int: Int]] = [:]

            for (index, chat) in dmChats.enumerated() {
                loadingProgress = "Analyzing conversations (\(index + 1)/\(dmChats.count))..."
                let platform = Platform.from(accountID: chat.accountID)
                do {
                    let response = try await api.listMessages(chatID: chat.id)
                    var bd = PersonMerger.ChatMessageBreakdown()
                    for msg in response.items {
                        if msg.isSender == true {
                            bd.sent += 1
                        } else {
                            bd.received += 1
                        }
                        let hour = calendar.component(.hour, from: msg.timestamp)
                        hourlyMap[platform, default: [:]][hour, default: 0] += 1
                    }
                    breakdowns[chat.id] = bd
                } catch {
                    breakdowns[chat.id] = PersonMerger.ChatMessageBreakdown()
                }
            }

            chatBreakdowns = breakdowns

            // 6. Hourly activity
            var points: [HourlyActivityPoint] = []
            for (platform, hours) in hourlyMap {
                for hour in 0..<24 {
                    points.append(HourlyActivityPoint(
                        hour: hour,
                        platform: platform,
                        count: hours[hour] ?? 0
                    ))
                }
            }
            hourlyActivity = points

            // 7. People categories
            PersonMerger.updateMessageCounts(persons: &merged, chatBreakdowns: breakdowns)
            mergedPeople = merged

            let categorized = PersonMerger.categorize(merged)
            twoWayPeople = categorized.twoWay
            theyGhostPeople = categorized.theyGhost
            iGhostPeople = categorized.iGhost

            // 8. Platform top contacts
            for i in platformStats.indices {
                let platform = platformStats[i].platform
                let contactsOnPlatform = merged.filter { person in
                    person.presences.contains { $0.platform == platform }
                }
                platformStats[i].topContacts = Array(contactsOnPlatform.prefix(10))
            }

            // 9. Today's messages
            loadingProgress = "Counting today's messages..."
            let startOfDay = calendar.startOfDay(for: Date())

            async let sentTask = api.searchMessages(
                sender: "me",
                dateAfter: startOfDay,
                limit: 1
            )
            async let receivedTask = api.searchMessages(
                sender: "others",
                dateAfter: startOfDay,
                limit: 1
            )

            let (sentResponse, receivedResponse) = try await (sentTask, receivedTask)
            messagesSentToday = sentResponse.items.count > 0 ? max(sentResponse.items.count, 1) : 0
            messagesReceivedToday = receivedResponse.items.count > 0 ? max(receivedResponse.items.count, 1) : 0

            // 10. Reels
            loadingProgress = "Analyzing Reels..."
            let instagramAccounts = fetchedAccounts.filter { $0.platform == .instagram }
            if !instagramAccounts.isEmpty {
                hasInstagram = true
                let instagramIDs = instagramAccounts.map(\.accountID)

                let igChats = fetchedChats.filter { instagramIDs.contains($0.accountID) }
                let chatMap = Dictionary(uniqueKeysWithValues: igChats.map { ($0.id, $0) })

                var allMessages: [BeeperMessage] = []
                var cursor: String? = nil

                while true {
                    loadingProgress = "Searching for Reels (\(allMessages.count) found)..."
                    let response = try await api.searchMessages(
                        accountIDs: instagramIDs,
                        mediaTypes: ["video", "image"],
                        limit: 20,
                        cursor: cursor,
                        direction: cursor != nil ? "before" : nil,
                        includeMuted: true
                    )
                    allMessages.append(contentsOf: response.items)
                    guard response.hasMore, let next = response.oldestCursor else { break }
                    cursor = next
                }

                reelEntries = ReelsAnalyzer.analyzeReels(messages: allMessages, chats: chatMap)
                totalReelsSent = reelEntries.reduce(0) { $0 + $1.reelsSent }
                totalReelsReceived = reelEntries.reduce(0) { $0 + $1.reelsReceived }
            } else {
                hasInstagram = false
            }

            lastSyncDate = Date()

        } catch {
            self.error = error.localizedDescription
        }

        loadingProgress = nil
        isLoading = false
    }
}
