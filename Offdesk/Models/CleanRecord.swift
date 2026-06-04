import Foundation

/// A single file/folder move performed during a clean. Stored so a clean can be undone.
struct FileMove: Codable, Hashable {
    /// Absolute path the item was moved *from* (its original location).
    var from: String
    /// Absolute path the item was moved *to*.
    var to: String
}

/// The outcome of one clean run. Persisted as the "last clean" for status display and undo.
struct CleanRecord: Codable {
    var date: Date
    var destination: String
    var moves: [FileMove]
    var skippedCount: Int
    var errorCount: Int

    var itemCount: Int { moves.count }
}
