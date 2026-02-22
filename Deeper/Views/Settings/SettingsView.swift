//
//  SettingsView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI

struct SettingsView: View {
    var onConnect: (BeeperAPIClient) -> Void

    @State private var token: String = ""
    @State private var isConnecting = false
    @State private var connectionInfo: ConnectInfoResponse?
    @State private var error: String?
    @State private var hasExistingToken = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Header
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    Text("Deeper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Messaging stats powered by Beeper Desktop API")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // MARK: - Token Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Beeper Access Token")
                        .font(.headline)
                    Text("Create a token in Beeper Desktop → Settings → API Access")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        SecureField("Paste your access token", text: $token)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { connect() }

                        Button(action: connect) {
                            if isConnecting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Text("Connect")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(token.isEmpty || isConnecting)
                    }

                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                .frame(maxWidth: 500)

                // MARK: - Connection Info
                if let info = connectionInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        Divider()

                        InfoRow(label: "App", value: "\(info.app.name) v\(info.app.version)")
                        InfoRow(label: "Platform", value: "\(info.platform.os) (\(info.platform.arch))")
                        InfoRow(label: "Server", value: info.server.base_url)
                        InfoRow(label: "Status", value: info.server.status)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    .frame(maxWidth: 500)
                }

                // MARK: - Disconnect
                if hasExistingToken {
                    Button(role: .destructive) {
                        disconnect()
                    } label: {
                        Label("Disconnect & Clear Token", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Settings")
        .onAppear {
            if let saved = KeychainHelper.loadToken() {
                token = saved
                hasExistingToken = true
                testConnection(token: saved)
            }
        }
    }

    private func connect() {
        guard !token.isEmpty else { return }
        isConnecting = true
        error = nil

        Task {
            do {
                let client = BeeperAPIClient(token: token)
                let info = try await client.getInfo()
                connectionInfo = info
                KeychainHelper.saveToken(token)
                hasExistingToken = true
                onConnect(client)
            } catch {
                self.error = error.localizedDescription
            }
            isConnecting = false
        }
    }

    private func testConnection(token: String) {
        Task {
            do {
                let client = BeeperAPIClient(token: token)
                let info = try await client.getInfo()
                connectionInfo = info
                onConnect(client)
            } catch {
                self.error = "Saved token invalid: \(error.localizedDescription)"
            }
        }
    }

    private func disconnect() {
        KeychainHelper.deleteToken()
        token = ""
        connectionInfo = nil
        hasExistingToken = false
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
    }
}
