import Foundation

/// The result of running the clean engine once.
struct CleanResult {
    var moves: [FileMove] = []
    var skipped: Int = 0
    var errors: [String] = []

    var movedCount: Int { moves.count }
}

/// Moves eligible items out of the source folders into a destination folder,
/// optionally grouped into a dated subfolder. Pure file I/O — no UI, no state.
/// Safe to run off the main thread.
struct CleanEngine {
    var sources: [URL]
    var destination: URL
    var grouping: Grouping
    var skipLabeled: Bool

    func run(now: Date) -> CleanResult {
        var result = CleanResult()
        let fm = FileManager.default

        // Make sure the destination exists.
        do {
            try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        } catch {
            result.errors.append("Couldn't create destination folder: \(error.localizedDescription)")
            return result
        }

        // Resolve (and create) the target subfolder once, based on the clean date.
        let targetDir: URL
        if let sub = grouping.subfolderName(for: now) {
            targetDir = destination.appendingPathComponent(sub, isDirectory: true)
            do {
                try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
            } catch {
                result.errors.append("Couldn't create folder “\(sub)”: \(error.localizedDescription)")
                return result
            }
        } else {
            targetDir = destination
        }

        // Compare as resolved path strings (not URL ==, which can differ by a
        // trailing slash for directories) so containment checks are reliable.
        let destPath = destination.standardizedFileURL.resolvingSymlinksInPath().path

        for source in sources {
            let contents: [URL]
            do {
                contents = try fm.contentsOfDirectory(
                    at: source,
                    includingPropertiesForKeys: skipLabeled ? [.tagNamesKey] : [],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                result.errors.append("Couldn't read \(source.path): \(error.localizedDescription)")
                continue
            }

            for item in contents {
                let itemPath = item.standardizedFileURL.resolvingSymlinksInPath().path

                // Skip anything that would re-clean or recurse the destination:
                //  - the destination itself,
                //  - items already inside the destination (e.g. a source set to the
                //    destination or a dated subfolder — would churn the archive),
                //  - an ancestor of the destination (would move the destination into itself).
                if itemPath == destPath
                    || itemPath.hasPrefix(destPath + "/")
                    || destPath.hasPrefix(itemPath + "/") {
                    result.skipped += 1
                    continue
                }

                // Skip items that carry Finder tags / labels when requested.
                if skipLabeled {
                    let tags = (try? item.resourceValues(forKeys: [.tagNamesKey]))?.tagNames
                    if let tags, !tags.isEmpty {
                        result.skipped += 1
                        continue
                    }
                }

                let dest = Self.uniqueDestination(for: item.lastPathComponent, in: targetDir, fileManager: fm)
                do {
                    try fm.moveItem(at: item, to: dest)
                    result.moves.append(FileMove(from: item.path, to: dest.path))
                } catch {
                    result.errors.append("Couldn't move \(item.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        return result
    }

    /// Returns a URL inside `dir` for `name`, appending " 2", " 3", … before the
    /// extension if needed so an existing file is never overwritten.
    static func uniqueDestination(for name: String, in dir: URL, fileManager fm: FileManager) -> URL {
        let candidate = dir.appendingPathComponent(name)
        if !fm.fileExists(atPath: candidate.path) { return candidate }

        let ns = name as NSString
        let ext = ns.pathExtension
        let base = ns.deletingPathExtension
        var index = 2
        while true {
            let newName = ext.isEmpty ? "\(base) \(index)" : "\(base) \(index).\(ext)"
            let url = dir.appendingPathComponent(newName)
            if !fm.fileExists(atPath: url.path) { return url }
            index += 1
        }
    }
}
