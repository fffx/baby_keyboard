//
//  UpdateManager.swift
//  BabyKeyboardLock
//

import Foundation
import AppKit
import SwiftUI

@MainActor
public final class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()

    public static let updateWindowID = "UpdateWindow"

    @Published public private(set) var status: UpdateStatus = .idle
    @Published public private(set) var isChecking: Bool = false

    private let service: UpdateServiceProtocol
    private let currentVersionProvider: () -> String
    private let targetBundleURLProvider: () -> URL

    private var activeDownloadTask: Task<Void, Never>?

    public init(
        service: UpdateServiceProtocol = UpdateService(),
        currentVersionProvider: @escaping () -> String = { Bundle.main.appVersionLong },
        targetBundleURLProvider: @escaping () -> URL = { Bundle.main.bundleURL }
    ) {
        self.service = service
        self.currentVersionProvider = currentVersionProvider
        self.targetBundleURLProvider = targetBundleURLProvider
    }

    @discardableResult
    public func checkForUpdates(userInitiated: Bool = true) -> Task<Void, Never> {
        guard !isChecking else {
            if userInitiated {
                showUpdateWindow()
            }
            return Task {}
        }

        isChecking = true
        status = .checking

        if userInitiated {
            showUpdateWindow()
        }

        return Task { [weak self] in
            guard let self = self else { return }
            do {
                let release = try await self.service.fetchLatestRelease()
                let currentVersionStr = self.currentVersionProvider()

                let currentVer = SemanticVersion(currentVersionStr) ?? SemanticVersion("0.0.0")!
                let releaseVer = SemanticVersion(release.tagName)

                if let releaseVer = releaseVer, releaseVer > currentVer {
                    if let asset = release.findAppZipAsset() {
                        self.status = .updateAvailable(
                            currentVersion: currentVersionStr,
                            newVersion: release.tagName,
                            release: release,
                            asset: asset
                        )
                        self.showUpdateWindow()
                    } else {
                        self.status = .error("A new release (\(release.tagName)) is available, but no matching macOS archive was found.")
                    }
                } else {
                    self.status = .upToDate(currentVersion: currentVersionStr)
                }
            } catch let error as UpdateError {
                self.status = .error(error.localizedDescription)
            } catch {
                self.status = .error(error.localizedDescription)
            }
            self.isChecking = false
        }
    }

    @discardableResult
    public func downloadAndInstallUpdate() -> Task<Void, Never>? {
        guard case let .updateAvailable(_, _, _, asset) = status else { return nil }

        status = .downloading(progress: 0.0)

        activeDownloadTask?.cancel()
        let task = Task { [weak self] in
            guard let self = self else { return }
            do {
                let downloadedZipURL = try await self.service.downloadAsset(asset) { [weak self] progress in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if case .downloading = self.status {
                            self.status = .downloading(progress: progress)
                        }
                    }
                }

                self.status = .installing
                let targetURL = self.targetBundleURLProvider()
                try self.service.installUpdate(zipURL: downloadedZipURL, targetBundleURL: targetURL)
            } catch is CancellationError {
                self.status = .idle
            } catch let error as UpdateError {
                self.status = .error(error.localizedDescription)
            } catch {
                self.status = .error(error.localizedDescription)
            }
        }
        activeDownloadTask = task
        return task
    }

    public func cancelUpdate() {
        activeDownloadTask?.cancel()
        activeDownloadTask = nil
        status = .idle
        closeUpdateWindow()
    }

    public func showUpdateWindow() {
        if let existingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == Self.updateWindowID && $0.isVisible }) {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = UpdateView(updateManager: self)
            .openInWindow(title: "Software Update", id: Self.updateWindowID, sender: NSApp, focus: true)
        window.center()
    }

    public func closeUpdateWindow() {
        NSApp.windows.forEach { window in
            if window.identifier?.rawValue == Self.updateWindowID {
                window.close()
            }
        }
    }
}
