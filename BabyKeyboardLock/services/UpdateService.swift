//
//  UpdateService.swift
//  BabyKeyboardLock
//

import Foundation
import AppKit

public protocol UpdateServiceProtocol: AnyObject, Sendable {
    func fetchLatestRelease() async throws -> GitHubRelease
    func downloadAsset(
        _ asset: GitHubReleaseAsset,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
    func installUpdate(zipURL: URL, targetBundleURL: URL) throws
}

public final class UpdateService: NSObject, UpdateServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let apiURL: URL

    public static let defaultRepoLatestReleaseURL = URL(string: "https://api.github.com/repos/fffx/baby_keyboard/releases/latest")!

    public init(
        apiURL: URL = defaultRepoLatestReleaseURL,
        session: URLSession = .shared
    ) {
        self.apiURL = apiURL
        self.session = session
        super.init()
    }

    public func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let version = Bundle.main.appVersionLong.isEmpty ? "1.0.0" : Bundle.main.appVersionLong
        request.setValue("BabyKeyboardLock/\(version) (Macintosh)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.networkError("Invalid server response.")
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(GitHubRelease.self, from: data)
            } catch {
                throw UpdateError.networkError("Failed to parse release information: \(error.localizedDescription)")
            }
        case 403:
            throw UpdateError.rateLimited
        case 404:
            throw UpdateError.noReleasesFound
        default:
            throw UpdateError.networkError("Server returned HTTP \(httpResponse.statusCode).")
        }
    }

    public func downloadAsset(
        _ asset: GitHubReleaseAsset,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let downloader = AssetDownloader(url: asset.browserDownloadUrl, progressHandler: progress)
        return try await downloader.start()
    }

    public func installUpdate(zipURL: URL, targetBundleURL: URL) throws {
        let fileManager = FileManager.default
        let tempExtractDir = fileManager.temporaryDirectory.appendingPathComponent("UpdateExtract-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempExtractDir, withIntermediateDirectories: true)

        // 1. Unzip using /usr/bin/ditto
        let dittoProcess = Process()
        dittoProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        dittoProcess.arguments = ["-x", "-k", zipURL.path, tempExtractDir.path]

        let errorPipe = Pipe()
        dittoProcess.standardError = errorPipe
        try dittoProcess.run()
        dittoProcess.waitUntilExit()

        guard dittoProcess.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: errorData, encoding: .utf8) ?? "Extraction failed"
            throw UpdateError.invalidZipArchive(errorString)
        }

        // 2. Locate .app bundle
        let items = try fileManager.contentsOfDirectory(at: tempExtractDir, includingPropertiesForKeys: nil)
        guard let appBundle = items.first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.invalidZipArchive("No .app bundle found inside update package.")
        }

        // 3. Verify bundle identifier
        let infoPlistURL = appBundle.appendingPathComponent("Contents/Info.plist")
        guard let infoDict = NSDictionary(contentsOf: infoPlistURL),
              let bundleId = infoDict["CFBundleIdentifier"] as? String else {
            throw UpdateError.invalidAppBundle("Missing or unreadable Info.plist in update.")
        }

        let allowedIDs = ["com.fangxing.BabyKeyboardLock", "com.fangxing.BabyKeyboardLockDebug"]
        if let currentID = Bundle.main.bundleIdentifier {
            guard bundleId == currentID || allowedIDs.contains(bundleId) else {
                throw UpdateError.invalidAppBundle("Extracted bundle ID (\(bundleId)) does not match expected application bundle.")
            }
        }

        // 4. Check target writability
        let targetDir = targetBundleURL.deletingLastPathComponent()
        let isWritable = fileManager.isWritableFile(atPath: targetBundleURL.path) || fileManager.isWritableFile(atPath: targetDir.path)
        guard isWritable else {
            throw UpdateError.permissionDenied("Application directory '\(targetDir.path)' is not writable. Please check permissions.")
        }

        // Detect test environment so tests don't kill the runner
        #if DEBUG
        if isRunningTestsOrPreview {
            try? fileManager.removeItem(at: tempExtractDir)
            try? fileManager.removeItem(at: zipURL)
            return
        }
        #endif

        // 5. Write detached relaunch script
        let scriptURL = tempExtractDir.appendingPathComponent("update_and_relaunch.sh")
        let scriptContent = """
        #!/bin/sh
        PID="$1"
        SRC="$2"
        DST="$3"

        while kill -0 "$PID" 2>/dev/null; do
            sleep 0.1
        done

        sleep 0.2

        rm -rf "$DST"
        cp -R "$SRC" "$DST"
        xattr -dr com.apple.quarantine "$DST" 2>/dev/null || true
        open "$DST"

        rm -rf "$(dirname "$SRC")"
        rm -f "$0"
        """

        try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        // 6. Spawn updater script
        let relaunchProcess = Process()
        relaunchProcess.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunchProcess.arguments = [
            scriptURL.path,
            "\(ProcessInfo.processInfo.processIdentifier)",
            appBundle.path,
            targetBundleURL.path
        ]
        try relaunchProcess.run()

        // Clean up downloaded zip
        try? fileManager.removeItem(at: zipURL)

        // 7. Terminate current process gracefully
        DispatchQueue.main.async {
            NSApp.terminate(nil)
        }
    }

    private var isRunningTestsOrPreview: Bool {
        #if DEBUG
        let isTestBundle = Bundle.main.bundlePath.hasSuffix(".xctest") ||
                          Bundle.main.bundlePath.contains("XCTestProducts") ||
                          Bundle(for: UpdateService.self).bundlePath.contains("Tests")

        let isXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
                       NSClassFromString("XCTest") != nil

        let isSwiftTesting = NSClassFromString("Testing.Test") != nil ||
                            ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil ||
                            ProcessInfo.processInfo.arguments.contains { $0.contains("xctest") }

        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

        return isTestBundle || isXCTest || isSwiftTesting || isPreview
        #else
        return false
        #endif
    }
}

// MARK: - Asset Downloader Delegate

private final class AssetDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let url: URL
    private let progressHandler: @Sendable (Double) -> Void
    private var continuation: CheckedContinuation<URL, Error>?
    private var session: URLSession?

    init(url: URL, progressHandler: @escaping @Sendable (Double) -> Void) {
        self.url = url
        self.progressHandler = progressHandler
        super.init()
    }

    func start() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            self.session = session

            var request = URLRequest(url: url)
            let version = Bundle.main.appVersionLong.isEmpty ? "1.0.0" : Bundle.main.appVersionLong
            request.setValue("BabyKeyboardLock/\(version) (Macintosh)", forHTTPHeaderField: "User-Agent")

            let task = session.downloadTask(with: request)
            task.resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        if totalBytesExpectedToWrite > 0 {
            let progress = min(1.0, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
            progressHandler(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let destURL = tempDir.appendingPathComponent("BabyKeyboardLock-Update-\(UUID().uuidString).zip")
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.moveItem(at: location, to: destURL)
            session.finishTasksAndInvalidate()
            progressHandler(1.0)
            continuation?.resume(returning: destURL)
            continuation = nil
        } catch {
            session.finishTasksAndInvalidate()
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            session.finishTasksAndInvalidate()
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
