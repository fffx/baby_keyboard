//
//  UpdateServiceTests.swift
//  BabyKeyboardLockTests
//

import Foundation
import Testing
@testable import BabyKeyboardLock

struct UpdateServiceTests {

    // MARK: - SemanticVersion Tests

    @Test func testSemanticVersionParsing() throws {
        let v1 = SemanticVersion("1.0.0")
        #expect(v1 != nil)
        #expect(v1?.major == 1)
        #expect(v1?.minor == 0)
        #expect(v1?.patch == 0)
        #expect(v1?.prerelease == nil)

        let v2 = SemanticVersion("v0.3.1")
        #expect(v2 != nil)
        #expect(v2?.major == 0)
        #expect(v2?.minor == 3)
        #expect(v2?.patch == 1)

        let v3 = SemanticVersion("V2.5")
        #expect(v3 != nil)
        #expect(v3?.major == 2)
        #expect(v3?.minor == 5)
        #expect(v3?.patch == 0)

        let vPrerelease = SemanticVersion("1.2.3-beta.1")
        #expect(vPrerelease != nil)
        #expect(vPrerelease?.major == 1)
        #expect(vPrerelease?.minor == 2)
        #expect(vPrerelease?.patch == 3)
        #expect(vPrerelease?.prerelease == "beta.1")

        #expect(SemanticVersion("") == nil)
        #expect(SemanticVersion("invalid") == nil)
    }

    @Test func testSemanticVersionComparison() throws {
        let current = try #require(SemanticVersion("0.3.1"))
        let newerPatch = try #require(SemanticVersion("v0.3.2"))
        let newerMinor = try #require(SemanticVersion("v0.4.0"))
        let newerMajor = try #require(SemanticVersion("v1.0.0"))
        let sameVersion = try #require(SemanticVersion("0.3.1"))
        let older = try #require(SemanticVersion("v0.2.4"))

        #expect(newerPatch > current)
        #expect(newerMinor > current)
        #expect(newerMajor > current)
        #expect(current == sameVersion)
        #expect(!(current > sameVersion))
        #expect(older < current)

        // Prerelease comparison: final release is greater than prerelease
        let release = try #require(SemanticVersion("1.0.0"))
        let beta = try #require(SemanticVersion("1.0.0-beta"))
        #expect(release > beta)
    }

    // MARK: - GitHubRelease Decoding & Asset Selection Tests

    @Test func testGitHubReleaseDecoding() throws {
        let json = """
        {
            "tag_name": "v1.0.0",
            "name": "Version 1.0.0",
            "body": "Exciting new features and fixes.",
            "html_url": "https://github.com/fffx/baby_keyboard/releases/tag/v1.0.0",
            "published_at": "2026-01-25T19:05:11Z",
            "assets": [
                {
                    "id": 12345,
                    "name": "source.tar.gz",
                    "browser_download_url": "https://example.com/source.tar.gz",
                    "content_type": "application/gzip",
                    "size": 5000
                },
                {
                    "id": 67890,
                    "name": "BabyKeyboardLock-v1.0.0.zip",
                    "browser_download_url": "https://example.com/BabyKeyboardLock-v1.0.0.zip",
                    "content_type": "application/zip",
                    "size": 2048000
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let release = try decoder.decode(GitHubRelease.self, from: json)

        #expect(release.tagName == "v1.0.0")
        #expect(release.name == "Version 1.0.0")
        #expect(release.body == "Exciting new features and fixes.")
        #expect(release.assets.count == 2)

        let selectedAsset = release.findAppZipAsset()
        #expect(selectedAsset != nil)
        #expect(selectedAsset?.name == "BabyKeyboardLock-v1.0.0.zip")
        #expect(selectedAsset?.browserDownloadUrl == URL(string: "https://example.com/BabyKeyboardLock-v1.0.0.zip"))
    }

    @Test func testFindAppZipAssetFallback() {
        let genericZipAsset = GitHubReleaseAsset(
            name: "Archive.zip",
            browserDownloadUrl: URL(string: "https://example.com/Archive.zip")!
        )
        let release = GitHubRelease(
            tagName: "v1.0.0",
            assets: [genericZipAsset]
        )

        let found = release.findAppZipAsset()
        #expect(found?.name == "Archive.zip")

        let emptyRelease = GitHubRelease(tagName: "v1.0.0", assets: [])
        #expect(emptyRelease.findAppZipAsset() == nil)
    }

    // MARK: - UpdateManager Tests

    @Test @MainActor func testUpdateManagerDetectsNewerVersion() async {
        let mockService = MockUpdateService()
        mockService.mockRelease = GitHubRelease(
            tagName: "v1.0.0",
            name: "Version 1.0.0",
            body: "Big update",
            htmlUrl: URL(string: "https://github.com/fffx/baby_keyboard/releases/tag/v1.0.0"),
            assets: [
                GitHubReleaseAsset(
                    name: "BabyKeyboardLock-v1.0.0.zip",
                    browserDownloadUrl: URL(string: "https://example.com/BabyKeyboardLock-v1.0.0.zip")!
                )
            ]
        )

        let manager = UpdateManager(
            service: mockService,
            currentVersionProvider: { "0.3.1" },
            targetBundleURLProvider: { URL(fileURLWithPath: "/Applications/BabyKeyboardLock.app") }
        )

        await manager.checkForUpdates(userInitiated: false).value

        if case let .updateAvailable(currentVer, newVer, _, asset) = manager.status {
            #expect(currentVer == "0.3.1")
            #expect(newVer == "v1.0.0")
            #expect(asset.name == "BabyKeyboardLock-v1.0.0.zip")
        } else {
            Issue.record("Expected status to be updateAvailable, but got \(manager.status)")
        }
    }

    @Test @MainActor func testUpdateManagerDetectsUpToDate() async {
        let mockService = MockUpdateService()
        mockService.mockRelease = GitHubRelease(
            tagName: "v0.3.1",
            assets: [
                GitHubReleaseAsset(
                    name: "BabyKeyboardLock-v0.3.1.zip",
                    browserDownloadUrl: URL(string: "https://example.com/BabyKeyboardLock-v0.3.1.zip")!
                )
            ]
        )

        let manager = UpdateManager(
            service: mockService,
            currentVersionProvider: { "0.3.1" }
        )

        await manager.checkForUpdates(userInitiated: false).value

        if case let .upToDate(version) = manager.status {
            #expect(version == "0.3.1")
        } else {
            Issue.record("Expected status to be upToDate, but got \(manager.status)")
        }
    }

    @Test @MainActor func testUpdateManagerHandlesError() async {
        let mockService = MockUpdateService()
        mockService.shouldThrowError = UpdateError.rateLimited

        let manager = UpdateManager(
            service: mockService,
            currentVersionProvider: { "0.3.1" }
        )

        await manager.checkForUpdates(userInitiated: false).value

        if case let .error(message) = manager.status {
            #expect(message.contains("rate limit"))
        } else {
            Issue.record("Expected status to be error, but got \(manager.status)")
        }
    }

    @Test @MainActor func testDownloadAndInstallProgressFlow() async throws {
        let mockService = MockUpdateService()
        let asset = GitHubReleaseAsset(
            name: "BabyKeyboardLock-v1.0.0.zip",
            browserDownloadUrl: URL(string: "https://example.com/BabyKeyboardLock-v1.0.0.zip")!
        )
        mockService.mockRelease = GitHubRelease(
            tagName: "v1.0.0",
            assets: [asset]
        )

        let manager = UpdateManager(
            service: mockService,
            currentVersionProvider: { "0.3.1" }
        )

        await manager.checkForUpdates(userInitiated: false).value

        let installTask = manager.downloadAndInstallUpdate()
        await installTask?.value

        #expect(mockService.didCallInstallUpdate)
        #expect(manager.status == .installing)
    }

    @Test @MainActor func testCancelUpdateResetsStatus() async {
        let mockService = MockUpdateService()
        mockService.mockRelease = GitHubRelease(
            tagName: "v1.0.0",
            assets: [
                GitHubReleaseAsset(
                    name: "BabyKeyboardLock-v1.0.0.zip",
                    browserDownloadUrl: URL(string: "https://example.com/BabyKeyboardLock-v1.0.0.zip")!
                )
            ]
        )

        let manager = UpdateManager(
            service: mockService,
            currentVersionProvider: { "0.3.1" }
        )

        await manager.checkForUpdates(userInitiated: false).value
        #expect(manager.status != .idle)

        manager.cancelUpdate()
        #expect(manager.status == .idle)
    }
}

// MARK: - Mock Update Service

final class MockUpdateService: UpdateServiceProtocol, @unchecked Sendable {
    var mockRelease: GitHubRelease?
    var shouldThrowError: Error?
    var downloadedAssetURL: URL = URL(fileURLWithPath: "/tmp/mock.zip")
    var didCallInstallUpdate: Bool = false

    func fetchLatestRelease() async throws -> GitHubRelease {
        if let error = shouldThrowError {
            throw error
        }
        guard let release = mockRelease else {
            throw UpdateError.noReleasesFound
        }
        return release
    }

    func downloadAsset(
        _ asset: GitHubReleaseAsset,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        if let error = shouldThrowError {
            throw error
        }
        progress(0.5)
        progress(1.0)
        return downloadedAssetURL
    }

    func installUpdate(zipURL: URL, targetBundleURL: URL) throws {
        if let error = shouldThrowError {
            throw error
        }
        didCallInstallUpdate = true
    }
}
