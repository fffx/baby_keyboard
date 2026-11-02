//
//  UpdateModels.swift
//  BabyKeyboardLock
//

import Foundation

// MARK: - Semantic Version

public struct SemanticVersion: Comparable, Equatable, CustomStringConvertible, Sendable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let rawString: String

    public var description: String { rawString }

    public init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var versionStr = trimmed
        if versionStr.lowercased().hasPrefix("v") {
            versionStr = String(versionStr.dropFirst())
        }

        let dashParts = versionStr.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        let corePart = String(dashParts[0])
        let prereleasePart = dashParts.count > 1 ? String(dashParts[1]) : nil

        let numbers = corePart.split(separator: ".").compactMap { Int($0) }
        guard !numbers.isEmpty else { return nil }

        self.major = numbers[0]
        self.minor = numbers.count > 1 ? numbers[1] : 0
        self.patch = numbers.count > 2 ? numbers[2] : 0
        self.prerelease = prereleasePart
        self.rawString = trimmed
    }

    public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch &&
               lhs.prerelease == rhs.prerelease
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        }
        if lhs.prerelease != rhs.prerelease {
            if lhs.prerelease == nil { return false }
            if rhs.prerelease == nil { return true }
            return (lhs.prerelease ?? "") < (rhs.prerelease ?? "")
        }
        return false
    }
}

// MARK: - GitHub Release Models

public struct GitHubRelease: Codable, Equatable, Sendable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: URL?
    public let publishedAt: Date?
    public let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }

    public init(
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlUrl: URL? = nil,
        publishedAt: Date? = nil,
        assets: [GitHubReleaseAsset] = []
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
        self.assets = assets
    }

    public func findAppZipAsset() -> GitHubReleaseAsset? {
        if let preferred = assets.first(where: {
            $0.name.lowercased().hasSuffix(".zip") && $0.name.lowercased().contains("babykeyboardlock")
        }) {
            return preferred
        }
        return assets.first(where: { $0.name.lowercased().hasSuffix(".zip") })
    }
}

public struct GitHubReleaseAsset: Codable, Equatable, Sendable {
    public let id: Int?
    public let name: String
    public let browserDownloadUrl: URL
    public let contentType: String?
    public let size: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadUrl = "browser_download_url"
        case contentType = "content_type"
        case size
    }

    public init(
        id: Int? = nil,
        name: String,
        browserDownloadUrl: URL,
        contentType: String? = nil,
        size: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.contentType = contentType
        self.size = size
    }
}

// MARK: - Update Error

public enum UpdateError: LocalizedError, Equatable {
    case invalidURL
    case rateLimited
    case noReleasesFound
    case noCompatibleAsset
    case networkError(String)
    case invalidZipArchive(String)
    case invalidAppBundle(String)
    case permissionDenied(String)
    case installFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid update URL."
        case .rateLimited:
            return "GitHub API rate limit exceeded. Please try again later."
        case .noReleasesFound:
            return "No releases found for BabyKeyboardLock."
        case .noCompatibleAsset:
            return "No compatible macOS app archive found in this release."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidZipArchive(let message):
            return "Failed to extract update: \(message)"
        case .invalidAppBundle(let message):
            return "Invalid application bundle: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .installFailed(let message):
            return "Installation failed: \(message)"
        case .cancelled:
            return "Update cancelled."
        }
    }
}

// MARK: - Update Status

public enum UpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String)
    case updateAvailable(currentVersion: String, newVersion: String, release: GitHubRelease, asset: GitHubReleaseAsset)
    case downloading(progress: Double)
    case readyToInstall(zipURL: URL)
    case installing
    case error(String)
}
