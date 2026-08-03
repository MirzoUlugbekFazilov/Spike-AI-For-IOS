//
//  SupabaseManager.swift
//  Spike AI
//

import Foundation
import Supabase
import Observation
import SwiftUI
import UserNotifications

// MARK: - Client

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://ekcpocbwhcfwbsmgxovr.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrY3BvY2J3aGNmd2JzbWd4b3ZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNjI4MDMsImV4cCI6MjA5MjYzODgwM30.RSOU3j7o0Pe-PNjaXq1wMMxHfL0aiTWDLu40Uo5cTEs",
    options: .init(auth: .init(
        flowType: .pkce,
        autoRefreshToken: true,
        emitLocalSessionAsInitialSession: true
    ))
)

// MARK: - Offline Sync

/// Queues failed Supabase operations and retries them when connectivity returns.
@MainActor @Observable
final class OfflineSyncManager {
    static let shared = OfflineSyncManager()

    private let queueKey = "spike_offline_sync_queue"
    private(set) var pendingCount = 0
    private(set) var isSyncing = false

    struct PendingOp: Codable, Identifiable {
        let id: String  // UUID
        let table: String
        let action: String  // "insert", "update", "delete", "upsert"
        let payload: Data   // JSON-encoded payload
        let filter: [String: String]?  // e.g. ["id": "xxx"]
        let createdAt: Double
    }

    init() { pendingCount = loadQueue().count }

    func enqueue(table: String, action: String, payload: any Encodable, filter: [String: String]? = nil) {
        guard let data = try? JSONEncoder().encode(SpikeEncodable(payload)) else { return }
        var queue = loadQueue()
        // Deduplicate: remove existing op for same table+filter+action
        if let filter {
            queue.removeAll { $0.table == table && $0.action == action && $0.filter == filter }
        }
        queue.append(PendingOp(
            id: UUID().uuidString, table: table, action: action,
            payload: data, filter: filter, createdAt: Date().timeIntervalSince1970
        ))
        saveQueue(queue)
        pendingCount = queue.count
    }

    /// Attempt to flush all pending operations. Call on foreground / connectivity change.
    func syncPendingOperations() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let queue = loadQueue()
        guard !queue.isEmpty else { return }

        var remaining: [PendingOp] = []
        for op in queue {
            let success = await execute(op)
            if !success { remaining.append(op) }
        }
        saveQueue(remaining)
        pendingCount = remaining.count
    }

    private func execute(_ op: PendingOp) async -> Bool {
        do {
            switch op.action {
            case "insert":
                try await supabase.from(op.table).insert(PassthroughJSON(op.payload)).execute()
            case "update":
                guard let filter = op.filter else { return true }
                var query = try supabase.from(op.table).update(PassthroughJSON(op.payload))
                for (key, value) in filter { query = query.eq(key, value: value) }
                try await query.execute()
            case "upsert":
                try await supabase.from(op.table).upsert(PassthroughJSON(op.payload)).execute()
            case "delete":
                guard let filter = op.filter else { return true }
                var query = supabase.from(op.table).delete()
                for (key, value) in filter { query = query.eq(key, value: value) }
                try await query.execute()
            default:
                return true // unknown action, drop it
            }
            return true
        } catch {
            return false
        }
    }

    private func loadQueue() -> [PendingOp] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let ops = try? JSONDecoder().decode([PendingOp].self, from: data) else { return [] }
        // Prune operations older than 7 days
        let cutoff = Date().timeIntervalSince1970 - 7 * 86400
        return ops.filter { $0.createdAt > cutoff }
    }

    private func saveQueue(_ queue: [PendingOp]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}

/// Passes pre-serialized JSON data through the encoder as-is.
/// Used to replay queued Supabase operations from their stored JSON.
struct PassthroughJSON: Encodable {
    let data: Data
    init(_ data: Data) { self.data = data }

    func encode(to encoder: Encoder) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        if let dict = json as? [String: Any] {
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in dict {
                let ck = DynamicCodingKey(stringValue: key)
                if let s = value as? String { try container.encode(s, forKey: ck) }
                else if let b = value as? Bool { try container.encode(b, forKey: ck) }
                else if let i = value as? Int { try container.encode(i, forKey: ck) }
                else if let d = value as? Double { try container.encode(d, forKey: ck) }
                else if value is NSNull { try container.encodeNil(forKey: ck) }
                else {
                    let nested = try JSONSerialization.data(withJSONObject: value)
                    let str = String(data: nested, encoding: .utf8) ?? "null"
                    try container.encode(str, forKey: ck)
                }
            }
        }
    }

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}

// MARK: - Helpers

func todayString() -> String {
    struct Cache {
        static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }
    return Cache.formatter.string(from: Date())
}

func nowISO() -> String {
    struct Cache {
        static let formatter = ISO8601DateFormatter()
    }
    return Cache.formatter.string(from: Date())
}


// MARK: - Auth

@MainActor @Observable
final class AuthManager {
    /// Optimistic: if user was logged in before, skip the loading screen.
    var isLoggedIn = UserDefaults.standard.bool(forKey: "spike_session_active")
    var userEmail = ""
    var userId: UUID?
    var userCreatedAt: Date?
    var needsNameSetup = false
    /// Start resolved if we have a cached session flag, so no loading screen for returning users.
    var hasResolvedSession = UserDefaults.standard.bool(forKey: "spike_session_active")

    /// Temporarily stores the name provided by Apple Sign-In so it can be
    /// persisted in the profile during `upsertCurrentProfile`.
    var pendingProfileFirstName: String?
    var pendingProfileLastName: String?

    private let redirectURL = URL(string: "spikeai://login-callback")!
    private let nameSetupDoneKeyPrefix = "linear_name_setup_done_"
    private let pendingProfileNameStoragePrefix = "linear_pending_profile_name_"
    private let pendingDeletionKey = "spike_pending_account_deletion"

    func checkSession() async {
        // ── Process any pending account deletion from a previous offline session ──
        if let pendingUID = UserDefaults.standard.string(forKey: pendingDeletionKey),
           let uid = UUID(uuidString: pendingUID) {
            await processPendingDeletion(uid: uid)
            return
        }

        // Detect fresh install: UserDefaults are wiped on uninstall, but
        // Keychain (where Supabase stores the session) survives. If our
        // sentinel key is missing, this is a reinstall — clear the stale
        // Keychain session so the user sees the login page.
        let hasLaunchedKey = "spike_has_launched_before"
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
            try? await supabase.auth.signOut()
            clearLocalSession()
            return
        }

        let hadCachedSession = UserDefaults.standard.bool(forKey: "spike_session_active")

        guard let session = try? await supabase.auth.session else {
            // If we had a cached session but can't reach the server,
            // keep the user logged in (offline mode).
            if hadCachedSession {
                preserveOfflineSession()
                return
            }
            clearLocalSession()
            return
        }

        // Check token expiry — but if offline, the SDK can't refresh it.
        // Only sign out for expired tokens when we can actually verify online.
        if Date().timeIntervalSince1970 > session.expiresAt {
            // Try refreshing — if offline this will fail gracefully
            if let refreshed = try? await supabase.auth.refreshSession() {
                applyVerifiedSession(user: refreshed.user)
                return
            }
            // Offline with expired token: keep user in-app with cached data
            if hadCachedSession {
                preserveOfflineSession()
                return
            }
            clearLocalSession()
            return
        }

        // Verify user with server. This is a network call.
        if let verifiedUser = try? await supabase.auth.user() {
            applyVerifiedSession(user: verifiedUser, fallbackEmail: session.user.email)
        } else if hadCachedSession {
            // Network failed but we have a cached session — stay logged in
            preserveOfflineSession()
        } else {
            await resetInvalidSession()
        }
    }

    /// Apply a fully verified session from the server.
    private func applyVerifiedSession(user: User, fallbackEmail: String? = nil) {
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "spike_session_active")
        hasResolvedSession = true
        userEmail = user.email ?? fallbackEmail ?? ""
        userId = user.id
        userCreatedAt = user.createdAt
        // Cache identity for offline restore
        UserDefaults.standard.set(user.id.uuidString, forKey: "spike_cached_user_id")
        UserDefaults.standard.set(userEmail, forKey: "spike_cached_user_email")
        // Capture a provider-supplied name (e.g. Google's user_metadata) in case
        // it wasn't persisted on the original sign-in.
        resolveIncomingName(from: user)
        if hasPersistedNameSetup(for: user.id) {
            needsNameSetup = false
        }
        Task { await upsertCurrentProfile() }
    }

    /// Keep the user logged in when offline, using cached identity.
    private func preserveOfflineSession() {
        isLoggedIn = true
        hasResolvedSession = true
        // Restore userId from cached value if needed
        if userId == nil, let cached = UserDefaults.standard.string(forKey: "spike_cached_user_id"),
           let uuid = UUID(uuidString: cached) {
            userId = uuid
        }
        if userEmail.isEmpty, let cached = UserDefaults.standard.string(forKey: "spike_cached_user_email") {
            userEmail = cached
        }
    }

    func sendMagicLink(email: String) async throws {
        try await supabase.auth.signInWithOTP(email: email, redirectTo: redirectURL)
    }

    func handleMagicLink(url: URL) async {
        guard url.scheme == "spikeai" else { return }

        // Try exchanging the code or parsing the session from the URL
        do {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                let session = try await supabase.auth.exchangeCodeForSession(authCode: code)
                apply(session: session)
                return
            } else {
                let session = try await supabase.auth.session(from: url)
                apply(session: session)
                return
            }
        } catch {
            #if DEBUG
            print("[Spike AI] Magic link primary auth error: \(error)")
            #endif
        }

        // Fallback: the code exchange may fail if the app was killed and the
        // PKCE code verifier was lost, but Supabase may still have verified
        // the email and created a valid session. Check for it.
        try? await Task.sleep(nanoseconds: 500_000_000) // brief wait for server
        await checkSession()
    }

    func signInWithGoogle() async throws {
        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "spikeai://login-callback")!
        )
        // OAuth browser flow is complete — SDK has the session, apply it to update UI
        let session = try await supabase.auth.session
        apply(session: session)
    }

    func signInWithApple(idToken: String, nonce: String? = nil, fullName: PersonNameComponents? = nil) async throws {
        // Apple only provides the name on first sign-in — stash it before
        // apply(session:) triggers upsertCurrentProfile so the profile
        // is created with the correct name.
        if let name = fullName {
            let first = name.givenName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let last = name.familyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !first.isEmpty || !last.isEmpty {
                pendingProfileFirstName = first.isEmpty ? nil : first
                pendingProfileLastName = last.isEmpty ? nil : last
            }
        }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        apply(session: session)
    }

    /// Capture a name handed to us by the identity provider so the profile can
    /// be created without showing the name-setup screen.
    ///
    /// - Apple delivers the name only on the very first sign-in, via
    ///   `signInWithApple`, which sets `pendingProfileFirstName` /
    ///   `pendingProfileLastName`.
    /// - Google (and other OAuth providers) deliver it inside the session
    ///   user's `user_metadata`.
    ///
    /// The resolved name is persisted to UserDefaults so `upsertCurrentProfile()`
    /// finds it through `hasPendingProfileName` and skips the prompt. If no name
    /// is available (e.g. Apple hidden-name, or a Google account with no name),
    /// nothing is stored and the user is asked on the name-setup screen.
    private func resolveIncomingName(from user: User) {
        // Setup already finished previously — nothing to capture.
        guard !hasPersistedNameSetup(for: user.id) else { return }
        // A name was already captured for this user this session — don't clobber it.
        guard !hasPendingProfileName(for: user.id) else { return }

        // 1. Name supplied by Apple Sign In (held in memory for this session).
        let appleFirst = pendingProfileFirstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let appleLast = pendingProfileLastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !appleFirst.isEmpty || !appleLast.isEmpty {
            persistPendingProfileName(first: appleFirst, last: appleLast, for: user.id)
            return
        }

        // 2. Name supplied by an OAuth provider (Google) via user_metadata.
        if let resolved = Self.nameComponents(fromMetadata: user.userMetadata) {
            pendingProfileFirstName = resolved.first.isEmpty ? nil : resolved.first
            pendingProfileLastName = resolved.last.isEmpty ? nil : resolved.last
            persistPendingProfileName(first: resolved.first, last: resolved.last, for: user.id)
        }
    }

    /// Derive a first/last name from an OAuth provider's `user_metadata`.
    /// Google populates `given_name` / `family_name`, and also `name` /
    /// `full_name`; we prefer the structured fields and fall back to splitting
    /// a single full-name string on the first space.
    static func nameComponents(fromMetadata metadata: [String: AnyJSON]) -> (first: String, last: String)? {
        func value(_ key: String) -> String {
            metadata[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }

        var first = value("given_name")
        var last = value("family_name")

        // Fall back to a single full-name field: first token is the first name,
        // the remainder is the last name (e.g. "Mary Jane Watson" -> "Mary",
        // "Jane Watson").
        if first.isEmpty && last.isEmpty {
            let full = !value("full_name").isEmpty ? value("full_name") : value("name")
            let parts = full.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            if parts.count == 1 {
                first = parts[0]
            } else if parts.count >= 2 {
                first = parts[0]
                last = parts.dropFirst().joined(separator: " ")
            }
        }

        guard !first.isEmpty || !last.isEmpty else { return nil }
        return (first, last)
    }

    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            clearLocalSession()
        } catch {
            clearLocalSession()
            throw error
        }
    }

    func deleteAccount() async throws {
        guard let uid = userId else {
            clearLocalSession()
            return
        }

        // Try online deletion first
        var networkFailed = false
        var errors: [Error] = []

        // Delete all user data (tables with user_id FK)
        for table in ["tasks", "goals", "focus_days", "progress_summaries"] {
            do {
                try await supabase.from(table).delete().eq("user_id", value: uid.uuidString).execute()
            } catch {
                errors.append(error)
                networkFailed = true
            }
        }
        // Profile uses `id` as PK (not user_id)
        do {
            try await supabase.from("profiles").delete().eq("id", value: uid.uuidString).execute()
        } catch {
            errors.append(error)
            networkFailed = true
        }

        // Edge function deletes the auth user itself
        do {
            try await supabase.functions.invoke("delete-account")
        } catch {
            errors.append(error)
            networkFailed = true
        }

        if networkFailed {
            // Offline: queue deletion for when internet returns.
            // Keep the Keychain session alive so we can authenticate later.
            UserDefaults.standard.set(uid.uuidString, forKey: pendingDeletionKey)
            clearLocalSession()
            return
        }

        try? await supabase.auth.signOut()
        clearLocalSession()
    }

    /// Process a pending account deletion that was queued during an offline session.
    private func processPendingDeletion(uid: UUID) async {
        // Try to get a valid session from Keychain (kept alive from the offline delete)
        guard let session = try? await supabase.auth.session else {
            // Still offline or session expired — stay on login page, try again next launch
            clearLocalSession()
            return
        }

        // Safety: only proceed if the Keychain session belongs to the same user
        // who requested deletion. If a different user has since logged in, drop
        // the pending flag to avoid deleting the wrong account.
        guard session.user.id == uid else {
            UserDefaults.standard.removeObject(forKey: pendingDeletionKey)
            // Let checkSession continue normally for the new user
            clearLocalSession()
            return
        }

        // We have the correct session — execute the full deletion
        for table in ["tasks", "goals", "focus_days", "progress_summaries"] {
            _ = try? await supabase.from(table).delete().eq("user_id", value: uid.uuidString).execute()
        }
        _ = try? await supabase.from("profiles").delete().eq("id", value: uid.uuidString).execute()
        _ = try? await supabase.functions.invoke("delete-account")

        // Clean up: remove pending flag, sign out fully, clear session
        UserDefaults.standard.removeObject(forKey: pendingDeletionKey)
        try? await supabase.auth.signOut()
        clearLocalSession()
    }

    func resetInvalidSession() async {
        try? await supabase.auth.signOut()
        clearLocalSession()
    }

    private func apply(session: Session) {
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "spike_session_active")
        userEmail = session.user.email ?? ""
        userId = session.user.id
        userCreatedAt = session.user.createdAt
        // Cache identity for offline restore
        UserDefaults.standard.set(session.user.id.uuidString, forKey: "spike_cached_user_id")
        UserDefaults.standard.set(userEmail, forKey: "spike_cached_user_email")
        // Capture any name supplied by the identity provider (Apple on first
        // sign-in, or Google via user_metadata) so the profile is created
        // without prompting the user.
        resolveIncomingName(from: session.user)
        if hasPersistedNameSetup(for: session.user.id) {
            needsNameSetup = false
        }
        Task { await upsertCurrentProfile() }
    }

    private func clearLocalSession() {
        if let userId {
            clearPersistedNameSetupState(for: userId)
        }
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "spike_session_active")
        UserDefaults.standard.removeObject(forKey: "spike_cached_user_id")
        UserDefaults.standard.removeObject(forKey: "spike_cached_user_email")
        userEmail = ""
        userId = nil
        userCreatedAt = nil
        needsNameSetup = false
        pendingProfileFirstName = nil
        pendingProfileLastName = nil
        hasResolvedSession = true
    }

    func upsertCurrentProfile() async {
        guard let userId else { return }

        if hasPersistedNameSetup(for: userId) {
            needsNameSetup = false
            await syncPendingProfileNameIfNeeded(for: userId)
            return
        }

        // If Apple Sign-In provided a name, save it to the profile immediately
        if hasPendingProfileName(for: userId) {
            needsNameSetup = false
            await syncPendingProfileNameIfNeeded(for: userId)
            return
        }
        pendingProfileFirstName = nil
        pendingProfileLastName = nil

        do {
            let existingProfiles: [ProfileNameCheck] = try await supabase
                .from("profiles")
                .select("first_name,last_name,name_setup_done")
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            guard let existing = existingProfiles.first else {
                // No profile row at all — new user, ask for name
                needsNameSetup = true
                return
            }

            // If name_setup_done flag is set in Supabase, never ask again
            if existing.nameSetupDone == true {
                needsNameSetup = false
                persistNameSetupComplete(for: userId)
                return
            }

            // First-time user with profile row but no setup done yet
            needsNameSetup = true
        } catch {
            #if DEBUG
            print("[Spike AI] Profile name check failed: \(error)")
            #endif
            // Do not turn a transient Supabase/RLS/schema read failure into
            // another name-setup prompt for users who already completed it.
        }
    }

    func completeNameSetup() {
        needsNameSetup = false
        if let userId {
            persistNameSetupComplete(for: userId)
        }
    }

    func submitNameSetup(firstName: String, lastName: String) async {
        guard let userId else { return }

        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Cache profile locally so it's available offline immediately
        let cachedProfile = UserProfile(
            id: userId,
            firstName: first.isEmpty ? nil : first,
            lastName: last.isEmpty ? nil : last,
            avatarColor: "green"
        )
        ProfileStore.persistProfileToCache(cachedProfile)

        // Save profile with name_setup_done = true (even if names are empty)
        let payload: [String: SpikeEncodable] = [
            "id": SpikeEncodable(userId),
            "first_name": SpikeEncodable(first),
            "last_name": SpikeEncodable(last),
            "name_setup_done": SpikeEncodable(true),
            "updated_at": SpikeEncodable(nowISO()),
        ]
        do {
            _ = try await supabase
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
        } catch {
            // Offline — queue for sync when connectivity returns
            OfflineSyncManager.shared.enqueue(table: "profiles", action: "upsert", payload: payload)
        }

        completeNameSetup()
    }

    private func nameSetupKey(for userId: UUID) -> String {
        "\(nameSetupDoneKeyPrefix)\(userId.uuidString)"
    }

    private func pendingProfileNameNamespace(for userId: UUID) -> String {
        "\(pendingProfileNameStoragePrefix)\(userId.uuidString)"
    }

    private func hasPersistedNameSetup(for userId: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: nameSetupKey(for: userId))
    }

    private func persistNameSetupComplete(for userId: UUID) {
        UserDefaults.standard.set(true, forKey: nameSetupKey(for: userId))
    }

    private func clearPersistedNameSetupState(for userId: UUID) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: nameSetupKey(for: userId))
        defaults.removeObject(forKey: pendingProfileNameKey(for: userId, field: "first"))
        defaults.removeObject(forKey: pendingProfileNameKey(for: userId, field: "last"))
    }

    private func pendingProfileNameKey(for userId: UUID, field: String) -> String {
        "\(pendingProfileNameNamespace(for: userId))_\(field)"
    }

    private func persistPendingProfileName(first: String, last: String, for userId: UUID) {
        let defaults = UserDefaults.standard
        defaults.set(first, forKey: pendingProfileNameKey(for: userId, field: "first"))
        defaults.set(last, forKey: pendingProfileNameKey(for: userId, field: "last"))
    }

    private func loadPendingProfileName(for userId: UUID) -> (first: String, last: String)? {
        let defaults = UserDefaults.standard
        let first = defaults.string(forKey: pendingProfileNameKey(for: userId, field: "first")) ?? ""
        let last = defaults.string(forKey: pendingProfileNameKey(for: userId, field: "last")) ?? ""
        let trimmedFirst = first.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = last.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty || !trimmedLast.isEmpty else { return nil }
        return (trimmedFirst, trimmedLast)
    }

    private func clearPendingProfileName(for userId: UUID) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: pendingProfileNameKey(for: userId, field: "first"))
        defaults.removeObject(forKey: pendingProfileNameKey(for: userId, field: "last"))
    }

    private func hasPendingProfileName(for userId: UUID) -> Bool {
        loadPendingProfileName(for: userId) != nil
    }

    func syncPendingProfileNameIfNeeded(for userId: UUID? = nil) async {
        guard let userId = userId ?? self.userId else { return }
        guard let pending = loadPendingProfileName(for: userId) else { return }

        // Cache locally so name is available offline immediately
        let cachedProfile = UserProfile(
            id: userId,
            firstName: pending.first.isEmpty ? nil : pending.first,
            lastName: pending.last.isEmpty ? nil : pending.last,
            avatarColor: "green"
        )
        ProfileStore.persistProfileToCache(cachedProfile)

        let payload = ProfileUpsert(
            id: userId,
            firstName: pending.first,
            lastName: pending.last,
            avatarColor: "green",
            updatedAt: nowISO()
        )

        do {
            _ = try await supabase
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
            clearPendingProfileName(for: userId)
            persistNameSetupComplete(for: userId)
            pendingProfileFirstName = nil
            pendingProfileLastName = nil
            needsNameSetup = false
        } catch {
            // Offline — queue for sync when connectivity returns
            OfflineSyncManager.shared.enqueue(table: "profiles", action: "upsert", payload: payload)
            clearPendingProfileName(for: userId)
            persistNameSetupComplete(for: userId)
            pendingProfileFirstName = nil
            pendingProfileLastName = nil
            needsNameSetup = false
            #if DEBUG
            print("[Spike AI] Pending profile sync failed: \(error)")
            #endif
        }
    }

}

// MARK: - Quote Tracking (Supabase-backed)

struct QuoteTrackingRecord: Codable {
    let userId: UUID
    var usedIndices: [Int]
    var lastQuoteIndex: Int?
    var lastQuoteDate: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case usedIndices = "used_indices"
        case lastQuoteIndex = "last_quote_index"
        case lastQuoteDate = "last_quote_date"
    }
}

@MainActor @Observable
final class QuoteTrackingStore {
    private var usedIndices: Set<Int> = []
    private var lastQuoteIndex: Int?
    private var lastQuoteDate: String?
    private var hasFetched = false

    /// Translated quote for the current day (nil = use English original).
    var translatedText: String?
    var translatedAuthor: String?
    var isTranslating = false
    private var translatedForIndex: Int?
    private var translatedForLanguage: String?

    // Local cache keys
    private static func cacheKey(_ userId: UUID) -> String { "spike_quote_cloud_\(userId.uuidString)" }
    private static func dateKey(_ userId: UUID) -> String { "spike_quote_cloud_date_\(userId.uuidString)" }
    private static func idxKey(_ userId: UUID) -> String { "spike_quote_cloud_idx_\(userId.uuidString)" }

    func resetForSignedOutUser() {
        usedIndices = []
        lastQuoteIndex = nil
        lastQuoteDate = nil
        hasFetched = false
        translatedText = nil
        translatedAuthor = nil
        isTranslating = false
        translatedForIndex = nil
        translatedForLanguage = nil
    }

    /// Fetch tracking data from Supabase, merging with any local-only data.
    func fetch(userId: UUID) async {
        // Load local cache immediately
        loadLocalCache(userId: userId)

        do {
            let records: [QuoteTrackingRecord] = try await supabase
                .from("quote_tracking")
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let remote = records.first {
                let remoteSet = Set(remote.usedIndices)
                // Merge: union of local + remote so no quote is repeated
                usedIndices = usedIndices.union(remoteSet)
                if let rd = remote.lastQuoteDate, let ri = remote.lastQuoteIndex {
                    // Use remote date/index if it's the same or newer day
                    if lastQuoteDate == nil || rd >= (lastQuoteDate ?? "") {
                        lastQuoteDate = rd
                        lastQuoteIndex = ri
                    }
                }
                saveLocalCache(userId: userId)
            }
        } catch {
            #if DEBUG
            print("[Spike AI] Quote tracking fetch failed: \(error)")
            #endif
            // Local cache is still usable
        }
        hasFetched = true
    }

    /// Pick a unique quote for today. Returns the index.
    func pickQuote(userId: UUID) -> Int {
        let today = Self.quoteDay()
        let total = QuotesData.all.count

        // Already picked today
        if lastQuoteDate == today, let idx = lastQuoteIndex, idx >= 0, idx < total {
            return idx
        }

        // Reset if all exhausted
        if usedIndices.count >= total {
            usedIndices = []
        }

        let available = Set(0..<total).subtracting(usedIndices)
        let chosen = available.randomElement() ?? Int.random(in: 0..<total)

        usedIndices.insert(chosen)
        lastQuoteIndex = chosen
        lastQuoteDate = today

        // Save locally first (instant)
        saveLocalCache(userId: userId)

        // Sync to Supabase in background
        Task {
            await syncToSupabase(userId: userId)
        }

        return chosen
    }

    /// Pick a quote for notifications (may differ from today's in-app quote).
    func pickNotificationQuote(userId: UUID) -> Int {
        let total = QuotesData.all.count

        if usedIndices.count >= total {
            usedIndices = []
        }

        let available = Set(0..<total).subtracting(usedIndices)
        let chosen = available.randomElement() ?? Int.random(in: 0..<total)

        usedIndices.insert(chosen)
        saveLocalCache(userId: userId)

        Task { await syncToSupabase(userId: userId) }

        return chosen
    }

    // MARK: - Supabase Sync

    private func syncToSupabase(userId: UUID) async {
        let payload: [String: SpikeEncodable] = [
            "user_id": SpikeEncodable(userId),
            "used_indices": SpikeEncodable(Array(usedIndices)),
            "last_quote_index": SpikeEncodable(lastQuoteIndex),
            "last_quote_date": SpikeEncodable(lastQuoteDate),
            "updated_at": SpikeEncodable(nowISO()),
        ]
        _ = try? await supabase
            .from("quote_tracking")
            .upsert(payload, onConflict: "user_id")
            .execute()
    }

    // MARK: - Local Cache

    private func loadLocalCache(userId: UUID) {
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey(userId)),
           let indices = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            usedIndices = indices
        }
        lastQuoteDate = UserDefaults.standard.string(forKey: Self.dateKey(userId))
        let idx = UserDefaults.standard.integer(forKey: Self.idxKey(userId))
        if idx > 0 { lastQuoteIndex = idx }
    }

    private func saveLocalCache(userId: UUID) {
        if let data = try? JSONEncoder().encode(usedIndices) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey(userId))
        }
        UserDefaults.standard.set(lastQuoteDate, forKey: Self.dateKey(userId))
        if let idx = lastQuoteIndex {
            UserDefaults.standard.set(idx, forKey: Self.idxKey(userId))
        }
    }

    /// Quote day boundary: 5 AM (same as the rest of the feature).
    static func quoteDay(for date: Date = Date()) -> String {
        let adjusted = Calendar.current.date(byAdding: .hour, value: -5, to: date) ?? date
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: adjusted)
    }

    // MARK: - Translation

    /// Synchronous translation lookup (bundled + local cache only).
    func loadTranslation(quoteIndex: Int, language: String) {
        guard language != "en" else {
            translatedText = nil
            isTranslating = false
            return
        }

        if translatedForIndex == quoteIndex, translatedForLanguage == language,
           translatedText != nil {
            return
        }

        let safeIdx = max(0, min(quoteIndex, QuotesData.all.count - 1))

        if let langArray = QuotesTranslations.all[language],
           safeIdx < langArray.count,
           !langArray[safeIdx].isEmpty {
            translatedText = langArray[safeIdx]
            translatedForIndex = quoteIndex
            translatedForLanguage = language
            return
        }

        let cacheKey = "spike_quote_trans_\(language)_\(safeIdx)"
        if let cached = UserDefaults.standard.string(forKey: cacheKey), !cached.isEmpty {
            translatedText = cached
            translatedForIndex = quoteIndex
            translatedForLanguage = language
            return
        }

        translatedText = nil
    }

    /// Async translation: bundled → local cache → edge function (with caching).
    func loadTranslationAsync(quoteIndex: Int, language: String) async {
        guard language != "en" else {
            translatedText = nil
            isTranslating = false
            return
        }

        if translatedForIndex == quoteIndex, translatedForLanguage == language,
           translatedText != nil {
            return
        }

        let safeIdx = max(0, min(quoteIndex, QuotesData.all.count - 1))

        // 1. Try bundled translations
        if let langArray = QuotesTranslations.all[language],
           safeIdx < langArray.count,
           !langArray[safeIdx].isEmpty {
            translatedText = langArray[safeIdx]
            translatedForIndex = quoteIndex
            translatedForLanguage = language
            return
        }

        // 2. Try local cache (skip if it matches English original — bad cache)
        let quote = QuotesData.all[safeIdx]
        let cacheKey = "spike_quote_trans_\(language)_\(safeIdx)"
        if let cached = UserDefaults.standard.string(forKey: cacheKey), !cached.isEmpty, cached != quote.text {
            translatedText = cached
            translatedForIndex = quoteIndex
            translatedForLanguage = language
            return
        }

        // 3. Fetch from edge function
        isTranslating = true
        await fetchTranslation(quoteIndex: safeIdx, text: quote.text, author: quote.author, language: language)
    }

    /// Calls the translate-quote edge function and caches the result.
    private func fetchTranslation(quoteIndex: Int, text: String, author: String, language: String) async {
        struct TranslateRequest: Encodable {
            let quote_index: Int
            let text: String
            let author: String
            let language: String
        }
        struct TranslateResponse: Decodable {
            let translated_text: String
            let translated_author: String?
            let untranslated: Bool?
        }

        do {
            let response: TranslateResponse = try await supabase.functions
                .invoke("translate-quote", options: FunctionInvokeOptions(body: TranslateRequest(
                    quote_index: quoteIndex,
                    text: text,
                    author: author,
                    language: language
                )))

            // If the server says translation failed, don't cache English text
            if response.untranslated == true {
                #if DEBUG
                print("[Spike AI] Quote translation unavailable — HF_TOKEN may not be set")
                #endif
                isTranslating = false
                return
            }

            let translated = response.translated_text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !translated.isEmpty, translated != text else {
                isTranslating = false
                return
            }

            translatedText = translated
            translatedForIndex = quoteIndex
            translatedForLanguage = language

            // Cache locally for offline use
            let cacheKey = "spike_quote_trans_\(language)_\(quoteIndex)"
            UserDefaults.standard.set(translated, forKey: cacheKey)
        } catch {
            #if DEBUG
            print("[Spike AI] Quote translation failed: \(error)")
            #endif
        }
        isTranslating = false
    }

    /// Returns the translated quote text or the English original.
    func displayText(for quote: DailyQuote) -> String {
        translatedText ?? quote.text
    }

    /// Always returns the original author name — never translated.
    func displayAuthor(for quote: DailyQuote) -> String {
        quote.author
    }
}

/// Type-erased Encodable wrapper for dictionary payloads.
private struct SpikeEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) {
        _encode = { try value.encode(to: $0) }
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

// MARK: - Tasks

struct TaskRecord: Codable, Identifiable {
    let id: String
    var title: String
    var category: String?
    var priority: String?
    var completed: Bool
    var createdAt: String?
    var scheduledDate: String?

    enum CodingKeys: String, CodingKey {
        case id, title, category, priority, completed
        case createdAt = "created_at"
        case scheduledDate = "scheduled_date"
    }

    var priorityEnum: TaskPriority? {
        guard let priority else { return nil }
        return TaskPriority(rawValue: priority)
    }
}

struct NewTask: Encodable {
    let id: String
    let title: String
    let category: String
    let priority: String?
    let createdAt: String
    let userId: UUID
    let completed: Bool
    let scheduledDate: String

    enum CodingKeys: String, CodingKey {
        case id, title, category, priority, completed
        case userId = "user_id"
        case createdAt = "created_at"
        case scheduledDate = "scheduled_date"
    }
}

struct TaskUpdate: Encodable {
    let completed: Bool
}

struct TaskTitleUpdate: Encodable {
    let title: String
}

struct TaskFieldsUpdate: Encodable {
    let title: String
    let priority: String?
    let scheduledDate: String

    enum CodingKeys: String, CodingKey {
        case title, priority
        case scheduledDate = "scheduled_date"
    }
}

enum TaskCategory: String, CaseIterable, Identifiable {
    case general, work, health, personal, learning

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum TaskPriority: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .low: "arrow.down"
        case .medium: "minus"
        case .high: "arrow.up"
        }
    }
    var color: Color {
        switch self {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }
}

@MainActor @Observable
final class TaskStore {
    var tasks: [TaskRecord] = []
    var isLoading = false
    var error: String?
    var selectedPriority: TaskPriority?
    private var pendingTaskIDs: Set<String> = []
    private let localCacheKey = "spike_tasks_local_cache"

    var filteredTasks: [TaskRecord] {
        guard let selectedPriority else { return tasks }
        return tasks.filter { $0.priority == selectedPriority.rawValue }
    }

    // Convenience: tasks for a given "yyyy-MM-dd" key
    func tasksFor(date: String) -> [TaskRecord] {
        tasks.filter { ($0.scheduledDate ?? "") == date }
    }
    var todayTasks: [TaskRecord] { tasksFor(date: todayString()) }

    var completedCount: Int { todayTasks.filter(\.completed).count }
    var pendingCount: Int { todayTasks.count - completedCount }
    var completionRate: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(todayTasks.count)
    }

    /// Writes current goal counts to the shared app group so the
    /// Shield extension can show context-aware messages.
    func syncGoalCountsToAppGroup() {
        let today = todayTasks
        let defaults = UserDefaults(suiteName: FocusConstants.appGroupID)
        defaults?.set(today.filter(\.completed).count, forKey: "linear_goals_completed")
        defaults?.set(today.count, forKey: "linear_goals_total")
    }

    func resetForSignedOutUser() {
        tasks = []
        isLoading = false
        error = nil
        selectedPriority = nil
        pendingTaskIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: localCacheKey)

        let defaults = UserDefaults(suiteName: FocusConstants.appGroupID)
        defaults?.set(0, forKey: "linear_goals_completed")
        defaults?.set(0, forKey: "linear_goals_total")
    }

    private func persistLocal() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: localCacheKey)
        }
    }

    private func loadLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: localCacheKey),
              let cached = try? JSONDecoder().decode([TaskRecord].self, from: data) else { return }
        if tasks.isEmpty { tasks = cached }
    }

    func fetch(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        // Load local cache first so UI is never empty
        loadLocalCache()
        syncGoalCountsToAppGroup()

        do {
            tasks = try await supabase
                .from("tasks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("scheduled_date", ascending: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            persistLocal()
            syncGoalCountsToAppGroup()
        } catch {
            // Offline — keep using local cache, don't set error
        }
    }

    func add(id: String = UUID().uuidString, title: String, priority: TaskPriority, scheduledDate: String, userId: UUID) async {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            error = AppLocalization.string("task_title_empty")
            return
        }

        let new = NewTask(
            id: id,
            title: String(cleanTitle.prefix(160)),
            category: TaskCategory.general.rawValue,
            priority: priority.rawValue,
            createdAt: nowISO(),
            userId: userId,
            completed: false,
            scheduledDate: scheduledDate
        )

        // Add locally first
        let localRecord = TaskRecord(
            id: id, title: String(cleanTitle.prefix(160)),
            category: TaskCategory.general.rawValue,
            priority: priority.rawValue,
            completed: false, createdAt: nowISO(),
            scheduledDate: scheduledDate
        )
        tasks.insert(localRecord, at: 0)
        persistLocal()
        syncGoalCountsToAppGroup()

        // Try to sync to Supabase
        do {
            let saved: TaskRecord = try await supabase
                .from("tasks")
                .insert(new)
                .select()
                .single()
                .execute()
                .value
            // Replace local record with server record (may have server-set fields)
            if let i = tasks.firstIndex(where: { $0.id == id }) { tasks[i] = saved }
            persistLocal()
        } catch {
            // Queue for later sync
            OfflineSyncManager.shared.enqueue(table: "tasks", action: "insert", payload: new)
        }
    }

    func toggle(_ task: TaskRecord) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard !pendingTaskIDs.contains(task.id) else { return }
        pendingTaskIDs.insert(task.id)
        defer { pendingTaskIDs.remove(task.id) }

        let next = !task.completed
        tasks[index].completed = next
        persistLocal()
        syncGoalCountsToAppGroup()

        do {
            try await supabase
                .from("tasks")
                .update(TaskUpdate(completed: next))
                .eq("id", value: task.id)
                .execute()
        } catch {
            // Keep local state, queue for sync
            OfflineSyncManager.shared.enqueue(
                table: "tasks", action: "update",
                payload: TaskUpdate(completed: next),
                filter: ["id": task.id]
            )
        }
    }

    func delete(_ task: TaskRecord) async {
        guard !pendingTaskIDs.contains(task.id) else { return }
        pendingTaskIDs.insert(task.id)
        defer { pendingTaskIDs.remove(task.id) }

        tasks.removeAll { $0.id == task.id }
        persistLocal()
        syncGoalCountsToAppGroup()

        do {
            try await supabase
                .from("tasks")
                .delete()
                .eq("id", value: task.id)
                .execute()
        } catch {
            // Keep deleted locally, queue for sync
            OfflineSyncManager.shared.enqueue(
                table: "tasks", action: "delete",
                payload: ["id": task.id],
                filter: ["id": task.id]
            )
        }
    }

    func updateTitle(_ task: TaskRecord, newTitle: String) async {
        let cleanTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard !pendingTaskIDs.contains(task.id) else { return }
        pendingTaskIDs.insert(task.id)
        defer { pendingTaskIDs.remove(task.id) }

        tasks[index].title = String(cleanTitle.prefix(160))
        persistLocal()

        do {
            try await supabase
                .from("tasks")
                .update(TaskTitleUpdate(title: String(cleanTitle.prefix(160))))
                .eq("id", value: task.id)
                .execute()
        } catch {
            OfflineSyncManager.shared.enqueue(
                table: "tasks", action: "update",
                payload: TaskTitleUpdate(title: String(cleanTitle.prefix(160))),
                filter: ["id": task.id]
            )
        }
    }

    func updateTask(_ task: TaskRecord, title: String, priority: TaskPriority, scheduledDate: String) async {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard !pendingTaskIDs.contains(task.id) else { return }
        pendingTaskIDs.insert(task.id)
        defer { pendingTaskIDs.remove(task.id) }

        tasks[index].title = String(cleanTitle.prefix(160))
        tasks[index].priority = priority.rawValue
        tasks[index].scheduledDate = scheduledDate
        persistLocal()
        syncGoalCountsToAppGroup()

        let payload = TaskFieldsUpdate(
            title: String(cleanTitle.prefix(160)),
            priority: priority.rawValue,
            scheduledDate: scheduledDate
        )
        do {
            try await supabase
                .from("tasks")
                .update(payload)
                .eq("id", value: task.id)
                .execute()
        } catch {
            OfflineSyncManager.shared.enqueue(
                table: "tasks", action: "update",
                payload: payload, filter: ["id": task.id]
            )
        }
    }
}

// MARK: - Profile

struct ProfileNameCheck: Codable {
    var firstName: String?
    var lastName: String?
    var nameSetupDone: Bool?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case nameSetupDone = "name_setup_done"
    }

    var hasCompleteName: Bool {
        let first = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !first.isEmpty && !last.isEmpty
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var firstName: String?
    var lastName: String?
    var avatarColor: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarColor = "avatar_color"
    }
}

struct ProfileUpsert: Encodable {
    let id: UUID
    let firstName: String
    let lastName: String
    let avatarColor: String
    let updatedAt: String
    /// A profile written through this type always carries a resolved name
    /// (typed by the user, or provided by Apple / Google), so the name-setup
    /// step is complete and must never be shown again — even after a reinstall.
    var nameSetupDone: Bool = true

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarColor = "avatar_color"
        case updatedAt = "updated_at"
        case nameSetupDone = "name_setup_done"
    }
}

@MainActor @Observable
final class ProfileStore {
    var profile: UserProfile?
    var error: String?
    private let localCacheKey = "spike_profile_local_cache"

    init() {
        // Eagerly load cached profile so data is available from the first render
        if let data = UserDefaults.standard.data(forKey: localCacheKey),
           let cached = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = cached
        }
    }

    func resetForSignedOutUser() {
        profile = nil
        error = nil
        UserDefaults.standard.removeObject(forKey: localCacheKey)
    }

    private func persistLocal() {
        guard let profile else { return }
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: localCacheKey)
        }
    }

    private func loadLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: localCacheKey),
              let cached = try? JSONDecoder().decode(UserProfile.self, from: data) else { return }
        if profile == nil { profile = cached }
    }

    /// Load cached profile synchronously (no network). Call this to populate UI immediately.
    func loadCachedProfile() {
        loadLocalCache()
    }

    /// Update the local profile cache directly (e.g. after name setup).
    func updateLocalProfile(_ newProfile: UserProfile) {
        self.profile = newProfile
        persistLocal()
    }

    /// Persist a profile to the local cache without needing a ProfileStore instance.
    /// Use this from code paths that don't have access to the store (e.g. AuthManager).
    static func persistProfileToCache(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "spike_profile_local_cache")
        }
    }

    func fetch(userId: UUID) async {
        loadLocalCache()

        do {
            let remote: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            profile = remote
            persistLocal()
        } catch {
            // Offline — keep local cache
        }
    }

    @discardableResult
    func save(profile: UserProfile, fallbackEmail: String) async -> Bool {
        error = nil
        let firstName = profile.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = profile.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Save locally first
        self.profile = profile
        persistLocal()

        let payload = ProfileUpsert(
            id: profile.id,
            firstName: firstName,
            lastName: lastName,
            avatarColor: profile.avatarColor ?? "green",
            updatedAt: nowISO()
        )
        do {
            let saved: UserProfile = try await supabase
                .from("profiles")
                .upsert(payload, onConflict: "id")
                .select()
                .single()
                .execute()
                .value
            self.profile = saved
            persistLocal()
            return true
        } catch {
            // Keep local state, queue for sync
            OfflineSyncManager.shared.enqueue(table: "profiles", action: "upsert", payload: payload)
            return true  // Return true since local save succeeded
        }
    }

}

// MARK: - Goals

enum GoalStatus: String, CaseIterable, Identifiable, Codable {
    case active, completed, abandoned

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct GoalRecord: Codable, Identifiable {
    let id: String
    var title: String
    var description: String?
    var targetDate: String?
    var isLongTerm: Bool
    var isPublic: Bool
    var status: String
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case targetDate = "target_date"
        case isLongTerm = "is_long_term"
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
}

struct NewGoal: Encodable {
    let id: String
    let userId: UUID
    let title: String
    let description: String
    let targetDate: String?
    let isLongTerm: Bool
    let isPublic: Bool
    let status: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case userId = "user_id"
        case targetDate = "target_date"
        case isLongTerm = "is_long_term"
        case isPublic = "is_public"
        case createdAt = "created_at"
    }
}

struct GoalStatusUpdate: Encodable {
    let status: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case completedAt = "completed_at"
    }
}

@MainActor @Observable
final class GoalStore {
    var goals: [GoalRecord] = []
    var selectedStatus: GoalStatus = .active
    var error: String?
    private var pendingGoalIDs: Set<String> = []
    private let localCacheKey = "spike_goals_local_cache"

    var filteredGoals: [GoalRecord] {
        goals.filter { $0.status == selectedStatus.rawValue }
    }

    func resetForSignedOutUser() {
        goals = []
        selectedStatus = .active
        error = nil
        pendingGoalIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: localCacheKey)
    }

    private func persistLocal() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: localCacheKey)
        }
    }

    private func loadLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: localCacheKey),
              let cached = try? JSONDecoder().decode([GoalRecord].self, from: data) else { return }
        if goals.isEmpty { goals = cached }
    }

    func fetch(userId: UUID) async {
        // Load local cache first
        loadLocalCache()

        do {
            goals = try await supabase
                .from("goals")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            persistLocal()
        } catch {
            // Offline — keep using local cache
        }
    }

    func add(title: String, description: String, targetDate: Date?, isLongTerm: Bool, isPublic: Bool, userId: UUID) async {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            error = AppLocalization.string("goal_title_empty")
            return
        }
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let goalId = UUID().uuidString
        let goal = NewGoal(
            id: goalId,
            userId: userId,
            title: String(cleanTitle.prefix(160)),
            description: String(cleanDescription.prefix(500)),
            targetDate: targetDate.map { formatter.string(from: $0) },
            isLongTerm: isLongTerm,
            isPublic: isPublic,
            status: GoalStatus.active.rawValue,
            createdAt: nowISO()
        )

        // Add locally first
        let localRecord = GoalRecord(
            id: goalId, title: String(cleanTitle.prefix(160)),
            description: String(cleanDescription.prefix(500)),
            targetDate: targetDate.map { formatter.string(from: $0) },
            isLongTerm: isLongTerm, isPublic: isPublic,
            status: GoalStatus.active.rawValue, createdAt: nowISO()
        )
        goals.insert(localRecord, at: 0)
        persistLocal()

        // Schedule notification regardless of online status
        if let td = targetDate {
            scheduleGoalNotification(goalId: goalId, title: cleanTitle, targetDate: td)
        }

        // Try to sync to Supabase
        do {
            let saved: GoalRecord = try await supabase
                .from("goals")
                .insert(goal)
                .select()
                .single()
                .execute()
                .value
            if let i = goals.firstIndex(where: { $0.id == goalId }) { goals[i] = saved }
            persistLocal()
        } catch {
            // Queue for later sync
            OfflineSyncManager.shared.enqueue(table: "goals", action: "insert", payload: goal)
        }
    }

    func updateStatus(_ goal: GoalRecord, status: GoalStatus) async {
        guard goal.status != status.rawValue else { return }
        guard !pendingGoalIDs.contains(goal.id) else { return }
        pendingGoalIDs.insert(goal.id)
        defer { pendingGoalIDs.remove(goal.id) }

        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index].status = status.rawValue
        }
        persistLocal()

        let payload = GoalStatusUpdate(
            status: status.rawValue,
            completedAt: status == .completed ? nowISO() : nil
        )
        do {
            try await supabase
                .from("goals")
                .update(payload)
                .eq("id", value: goal.id)
                .execute()
        } catch {
            // Keep local state, queue for sync
            OfflineSyncManager.shared.enqueue(
                table: "goals", action: "update",
                payload: payload, filter: ["id": goal.id]
            )
        }
    }

    func delete(_ goal: GoalRecord) async {
        guard !pendingGoalIDs.contains(goal.id) else { return }
        pendingGoalIDs.insert(goal.id)
        defer { pendingGoalIDs.remove(goal.id) }

        goals.removeAll { $0.id == goal.id }
        persistLocal()
        cancelGoalNotification(goalId: goal.id)

        do {
            try await supabase
                .from("goals")
                .delete()
                .eq("id", value: goal.id)
                .execute()
        } catch {
            OfflineSyncManager.shared.enqueue(
                table: "goals", action: "delete",
                payload: ["id": goal.id],
                filter: ["id": goal.id]
            )
        }
    }

    // MARK: - Goal Notifications

    private func scheduleGoalNotification(goalId: String, title: String, targetDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("goal_reminder")
        content.body = "\(AppLocalization.string("dont_forget")): \(title)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var dc = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        dc.hour = 9
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
        let req = UNNotificationRequest(identifier: "spike-goal-\(goalId)", content: content, trigger: trigger)
        Task { try? await UNUserNotificationCenter.current().add(req) }
    }

    private func cancelGoalNotification(goalId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["spike-goal-\(goalId)"])
    }
}

// MARK: - AI Progress Summary

struct ProgressSummaryRecord: Codable, Identifiable {
    let id: String
    let userId: UUID
    let periodStart: String
    let periodEnd: String
    let title: String
    let summary: String
    let wins: [String]
    let nextAction: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, summary, wins
        case userId = "user_id"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case nextAction = "next_action"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProgressSummaryRequest: Encodable {
    let periodStart: String
    let periodEnd: String
    let currentStreak: Int
    let bestStreak: Int
    let monthlyConsistencyPercent: Int
    let monthlyFocusDays: Int
    let monthlyMissedDays: Int
    let completedTasks: [String]
    let missedTasks: [String]
    let screenTimeTrend: String
    let averageScreenTimeMinutes: Int
    let goals: [String]
    let forceRefresh: Bool
    let language: String

    enum CodingKeys: String, CodingKey {
        case goals, language
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case monthlyConsistencyPercent = "monthly_consistency_percent"
        case monthlyFocusDays = "monthly_focus_days"
        case monthlyMissedDays = "monthly_missed_days"
        case completedTasks = "completed_tasks"
        case missedTasks = "missed_tasks"
        case screenTimeTrend = "screen_time_trend"
        case averageScreenTimeMinutes = "average_screen_time_minutes"
        case forceRefresh = "force_refresh"
    }
}

@MainActor @Observable
final class ProgressSummaryStore {
    var summary: ProgressSummaryRecord?
    var isLoading = false
    var error: String?
    private var lastGeneratedAt: Date?
    private let generateCooldownSeconds: TimeInterval = 60

    func resetForSignedOutUser() {
        summary = nil
        isLoading = false
        error = nil
        lastGeneratedAt = nil
    }

    func fetchCached(userId: UUID, periodStart: String, periodEnd: String) async {
        do {
            let records: [ProgressSummaryRecord] = try await supabase
                .from("progress_summaries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("period_start", value: periodStart)
                .eq("period_end", value: periodEnd)
                .limit(1)
                .execute()
                .value
            summary = records.first
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Fetches the most recent summary for this user regardless of period.
    /// Used as a fallback so the user always sees their latest summary
    /// even when the current week's summary hasn't been generated yet.
    func fetchLatest(userId: UUID) async {
        do {
            let records: [ProgressSummaryRecord] = try await supabase
                .from("progress_summaries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("period_end", ascending: false)
                .limit(1)
                .execute()
                .value
            if let latest = records.first {
                summary = latest
            }
        } catch {
            // Don't overwrite existing error
        }
    }

    func generate(request: ProgressSummaryRequest) async {
        guard !isLoading else { return }

        // Enforce a cooldown to avoid excessive AI summary generation
        if let last = lastGeneratedAt, Date().timeIntervalSince(last) < generateCooldownSeconds {
            let remaining = Int(generateCooldownSeconds - Date().timeIntervalSince(last))
            error = String(format: AppLocalization.string("rate_limit_wait"), remaining)
            return
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let generated: ProgressSummaryRecord = try await supabase.functions
                .invoke(
                    "generate-progress-summary",
                    options: FunctionInvokeOptions(body: request)
                )
            summary = generated
            lastGeneratedAt = Date()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Usage Analytics

@MainActor @Observable
final class UsageStore {
    private let key = "linear_usage_seconds_by_day"
    private var activeStartedAt: Date?
    var secondsByDay: [String: TimeInterval] = [:]

    init() { load() }

    func resetForSignedOutUser(clearPersisted: Bool = true) {
        activeStartedAt = nil
        secondsByDay = [:]
        if clearPersisted {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func appBecameActive() {
        activeStartedAt = Date()
    }

    func appBecameInactive() {
        guard let activeStartedAt else { return }
        secondsByDay[todayString(), default: 0] += Date().timeIntervalSince(activeStartedAt)
        self.activeStartedAt = nil
        persist()
    }

    var todayUsage: TimeInterval { secondsByDay[todayString(), default: 0] }

    func lastSevenUsage() -> [(String, TimeInterval)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let label = DateFormatter()
        label.dateFormat = "E"
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return (label.string(from: date), secondsByDay[formatter.string(from: date), default: 0])
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([String: TimeInterval].self, from: data) else { return }
        secondsByDay = saved
        pruneOldEntries()
    }

    /// Remove entries older than 365 days to prevent unbounded growth.
    private func pruneOldEntries() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date()) else { return }
        let cutoffString = formatter.string(from: cutoff)

        let before = secondsByDay.count
        secondsByDay = secondsByDay.filter { $0.key >= cutoffString }
        if secondsByDay.count < before {
            persist()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(secondsByDay) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Daily Focus Status

struct FocusDayRecord: Codable, Identifiable {
    let id: UUID?
    let userId: UUID?
    let day: String
    let wasSuccessful: Bool

    enum CodingKeys: String, CodingKey {
        case id, day
        case userId = "user_id"
        case wasSuccessful = "was_successful"
    }
}

struct NewFocusDay: Encodable {
    let userId: UUID
    let day: String
    let wasSuccessful: Bool

    enum CodingKeys: String, CodingKey {
        case day
        case userId = "user_id"
        case wasSuccessful = "was_successful"
    }
}

@MainActor @Observable
final class DailyFocusStore {
    private let localKey = "linear_focus_success_days"
    private let bestStreakKey = "linear_focus_best_streak"

    var successDays: Set<String> = []
    private var persistedBestStreak = 0
    private var pendingDays: Set<String> = []
    var error: String?

    init() {
        if let data = UserDefaults.standard.data(forKey: localKey),
           let days = try? JSONDecoder().decode(Set<String>.self, from: data) {
            successDays = days
        }
        persistedBestStreak = UserDefaults.standard.integer(forKey: bestStreakKey)
    }

    func resetForSignedOutUser(clearPersisted: Bool = true) {
        successDays = []
        persistedBestStreak = 0
        pendingDays.removeAll()
        error = nil
        if clearPersisted {
            UserDefaults.standard.removeObject(forKey: localKey)
            UserDefaults.standard.removeObject(forKey: bestStreakKey)
        }
    }

    var todayIsWin: Bool {
        successDays.contains(todayString())
    }

    var totalFocusDays: Int {
        successDays.count
    }

    var currentStreak: Int {
        streak(endingAtToday: true)
    }

    var bestStreak: Int {
        max(persistedBestStreak, calculatedBestStreak)
    }

    private var calculatedBestStreak: Int {
        let sorted = successDays.sorted()
        guard !sorted.isEmpty else { return 0 }

        let formatter = dayFormatter()
        let calendar = Calendar.current
        var best = 1
        var current = 1

        for index in 1..<sorted.count {
            guard let previous = formatter.date(from: sorted[index - 1]),
                  let currentDate = formatter.date(from: sorted[index]),
                  let diff = calendar.dateComponents([.day], from: previous, to: currentDate).day
            else { continue }

            if diff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return best
    }

    func fetch(userId: UUID) async {
        do {
            let records: [FocusDayRecord] = try await supabase
                .from("focus_days")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("was_successful", value: true)
                .execute()
                .value
            successDays = Set(records.map(\.day))
            persist()
            persistBestStreakIfNeeded()
        } catch {
            // Offline — keep using locally persisted data
        }
    }

    func markFocusSessionCompleted(userId: UUID) async {
        let today = todayString()
        guard !successDays.contains(today), !pendingDays.contains(today) else { return }
        pendingDays.insert(today)
        defer { pendingDays.remove(today) }

        successDays.insert(today)
        persist()
        persistBestStreakIfNeeded()

        let record = NewFocusDay(userId: userId, day: today, wasSuccessful: true)
        do {
            try await supabase
                .from("focus_days")
                .upsert(record, onConflict: "user_id,day")
                .execute()
        } catch {
            // Keep local state, queue for sync
            OfflineSyncManager.shared.enqueue(table: "focus_days", action: "upsert", payload: record)
        }
    }

    func lastSevenDays() -> [Bool] {
        let formatter = dayFormatter()
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return successDays.contains(formatter.string(from: date))
        }
    }

    private func streak(endingAtToday: Bool) -> Int {
        let formatter = dayFormatter()
        let calendar = Calendar.current
        var count = 0
        var date = Date()

        // If endingAtToday is true, today must be a success day to have a streak
        if endingAtToday && !successDays.contains(formatter.string(from: date)) {
            return 0
        }

        // Count backwards from today across month boundaries until a
        // non-success day is found
        while successDays.contains(formatter.string(from: date)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }

        return count
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(successDays) {
            UserDefaults.standard.set(data, forKey: localKey)
        }
    }

    private func persistBestStreakIfNeeded() {
        let latest = calculatedBestStreak
        guard latest > persistedBestStreak else { return }
        persistedBestStreak = latest
        UserDefaults.standard.set(latest, forKey: bestStreakKey)
    }

    private func dayFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
