import AppIntents
import Foundation

// Runs inside the foreground host, not the widget. No new login or remote credentials.
@available(iOS 16.0, *)
struct SGDuoPlayLikedSongsIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Liked Songs"
    static let description = IntentDescription("Play your Liked Songs in Spoti Duo.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult {
        try await SGDuoPlayback.start("spotify:collection:tracks")
        return .result()
    }
}

@available(iOS 16.0, *)
struct SGDuoPlayPlaylistIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Playlist by Link"
    static let description = IntentDescription("Play a Spotify playlist using its shared link or spotify:playlist URI.")
    static let openAppWhenRun = true
    @Parameter(title: "Playlist Link") var playlist: String
    static var parameterSummary: some ParameterSummary { Summary("Play \(\.$playlist)") }
    func perform() async throws -> some IntentResult {
        guard let uri = SGDuoPlaylistURI(playlist) else { throw SGDuoPlaybackError.invalidPlaylist }
        try await SGDuoPlayback.start(uri)
        return .result()
    }
}

func SGDuoPlaylistURI(_ input: String) -> String? {
    let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    var identifier: String?
    if value.hasPrefix("spotify:playlist:") {
        identifier = String(value.dropFirst("spotify:playlist:".count))
    } else if let url = URLComponents(string: value), url.scheme == "https", url.host == "open.spotify.com" {
        let parts = url.path.split(separator: "/")
        if parts.count == 2, parts[0] == "playlist" { identifier = String(parts[1]) }
        else if parts.count == 3, parts[0].hasPrefix("intl-"), parts[1] == "playlist" { identifier = String(parts[2]) }
    }
    guard let identifier, identifier.count == 22,
          identifier.unicodeScalars.allSatisfy({ (48...57).contains($0.value) || (65...90).contains($0.value) || (97...122).contains($0.value) }) else { return nil }
    return "spotify:playlist:" + identifier
}

enum SGDuoPlaybackError: LocalizedError {
    case invalidPlaylist, failed(String)
    var errorDescription: String? {
        switch self {
        case .invalidPlaylist: return "Use a Spotify playlist share link or spotify:playlist URI."
        case .failed(let message): return message
        }
    }
}

enum SGDuoPlayback {
    @MainActor static func start(_ uri: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion: @convention(block) (NSString?) -> Void = { error in
                if let error { continuation.resume(throwing: SGDuoPlaybackError.failed(error as String)) }
                else { continuation.resume() }
            }
            NotificationCenter.default.post(name: Notification.Name("SGDuoShortcutPlay"), object: uri,
                                            userInfo: ["completion": completion])
        }
    }
}
