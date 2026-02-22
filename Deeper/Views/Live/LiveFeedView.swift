//
//  LiveFeedView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI

struct LiveFeedView: View {
    @State var wsManager: WebSocketManager

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Connection Bar
            HStack(spacing: 12) {
                Circle()
                    .fill(wsManager.isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
                Text(wsManager.isConnected ? "Connected" : "Disconnected")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: 16) {
                    Label("\(wsManager.messageCount)", systemImage: "message.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label("\(wsManager.chatUpdateCount)", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Button(wsManager.isConnected ? "Disconnect" : "Connect") {
                    if wsManager.isConnected {
                        wsManager.disconnect()
                    } else {
                        wsManager.connect()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // MARK: - Events List
            if wsManager.events.isEmpty {
                ContentUnavailableView(
                    "No Events Yet",
                    systemImage: "bolt.slash.fill",
                    description: Text(wsManager.isConnected ? "Waiting for events..." : "Connect to see real-time events")
                )
            } else {
                List(Array(wsManager.events.enumerated()), id: \.offset) { _, event in
                    EventRow(event: event)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Live Feed")
        .onAppear {
            if !wsManager.isConnected {
                wsManager.connect()
            }
        }
    }
}

struct EventRow: View {
    let event: WSEvent

    var icon: String {
        switch event.type {
        case "message.upserted": "message.fill"
        case "message.deleted": "trash.fill"
        case "chat.upserted": "bubble.left.fill"
        case "chat.deleted": "xmark.circle.fill"
        default: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch event.type {
        case "message.upserted": .blue
        case "message.deleted": .red
        case "chat.upserted": .green
        case "chat.deleted": .orange
        default: .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)

                if let chat = event.chat {
                    Text(chat.title)
                        .font(.body)
                        .lineLimit(1)
                } else if let message = event.message {
                    Text(message.text ?? "[\(message.type?.rawValue ?? "message")]")
                        .font(.body)
                        .lineLimit(1)
                } else if let chatID = event.chatID {
                    Text(chatID)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let message = event.message {
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
