//
//  UpdateView.swift
//  BabyKeyboardLock
//

import SwiftUI

struct UpdateView: View {
    @ObservedObject var updateManager: UpdateManager

    init(updateManager: UpdateManager = .shared) {
        self.updateManager = updateManager
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                statusIcon
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 8) {
                    contentForStatus
                }
            }

            Spacer(minLength: 8)

            Divider()

            HStack {
                buttonsForStatus
            }
        }
        .padding(20)
        .frame(width: 460)
        .frame(minHeight: 200)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch updateManager.status {
        case .checking:
            ProgressView()
                .scaleEffect(1.2)
        case .upToDate:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .foregroundColor(.green)
        case .updateAvailable:
            Image(systemName: "arrow.down.circle.fill")
                .resizable()
                .foregroundColor(.accentColor)
        case .downloading, .readyToInstall, .installing:
            ProgressView()
                .scaleEffect(1.2)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .foregroundColor(.orange)
        case .idle:
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var contentForStatus: some View {
        switch updateManager.status {
        case .checking:
            Text("Checking for Updates…")
                .font(.headline)
            Text("Checking GitHub for the latest release of \(Bundle.applicationName)…")
                .font(.subheadline)
                .foregroundColor(.secondary)

        case .upToDate(let version):
            Text("You're up to date!")
                .font(.headline)
            Text("\(Bundle.applicationName) \(version) is currently the newest version available.")
                .font(.subheadline)
                .foregroundColor(.secondary)

        case .updateAvailable(let currentVer, let newVer, let release, _):
            Text("A new version of \(Bundle.applicationName) is available!")
                .font(.headline)
            Text("\(Bundle.applicationName) \(newVer) is available (you have \(currentVer)).")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let body = release.body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Release Notes:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(body)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(height: 110)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
            }

        case .downloading(let progress):
            Text("Downloading Update…")
                .font(.headline)
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)

        case .readyToInstall:
            Text("Update Ready")
                .font(.headline)
            Text("The update has been downloaded and is ready to install.")
                .font(.subheadline)
                .foregroundColor(.secondary)

        case .installing:
            Text("Installing Update…")
                .font(.headline)
            Text("\(Bundle.applicationName) will restart automatically once the update is installed.")
                .font(.subheadline)
                .foregroundColor(.secondary)

        case .error(let message):
            Text("Update Check Failed")
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

        case .idle:
            Text("Software Update")
                .font(.headline)
        }
    }

    @ViewBuilder
    private var buttonsForStatus: some View {
        switch updateManager.status {
        case .checking:
            Spacer()
            Button("Cancel") {
                updateManager.closeUpdateWindow()
            }

        case .upToDate:
            Spacer()
            Button("OK") {
                updateManager.closeUpdateWindow()
            }
            .keyboardShortcut(.defaultAction)

        case .updateAvailable(_, _, let release, _):
            if let htmlUrl = release.htmlUrl {
                Button("View on GitHub") {
                    NSWorkspace.shared.open(htmlUrl)
                }
            }
            Spacer()
            Button("Later") {
                updateManager.closeUpdateWindow()
            }
            Button("Update and Restart") {
                updateManager.downloadAndInstallUpdate()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

        case .downloading:
            Spacer()
            Button("Cancel") {
                updateManager.cancelUpdate()
            }

        case .readyToInstall, .installing:
            Spacer()

        case .error:
            Button("View Releases on GitHub") {
                if let url = URL(string: "https://github.com/fffx/baby_keyboard/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            Spacer()
            Button("Close") {
                updateManager.closeUpdateWindow()
            }
            Button("Try Again") {
                updateManager.checkForUpdates(userInitiated: true)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

        case .idle:
            Spacer()
            Button("Close") {
                updateManager.closeUpdateWindow()
            }
        }
    }
}

#Preview {
    UpdateView(updateManager: .shared)
}
