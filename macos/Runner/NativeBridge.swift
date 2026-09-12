import Cocoa
import FlutterMacOS

/// The ONLY Swift code in this project. Everything here is something Dart
/// cannot do by itself on macOS. Each `case` below is one method that Dart
/// calls through `NativeBridge` (lib/core/native_bridge.dart).
///
/// Adding a new method = add a `case "name":` here + a Dart wrapper. That's it.
class NativeBridge {
  static let channelName = "garbage_cleaner/native"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler(handle)
  }

  private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]

    switch call.method {

    // Move files/folders to the Trash (reversible, like Finder's ⌘⌫).
    // args: { "paths": [String] }  ->  { "trashed": [String], "failed": {path: error} }
    case "moveToTrash":
      let paths = args["paths"] as? [String] ?? []
      var trashed: [String] = []
      var failed: [String: String] = [:]
      for p in paths {
        do {
          try FileManager.default.trashItem(at: URL(fileURLWithPath: p), resultingItemURL: nil)
          trashed.append(p)
        } catch {
          failed[p] = error.localizedDescription
        }
      }
      result(["trashed": trashed, "failed": failed])

    // Full Disk Access check. TCC has no public API, so the standard trick is
    // to try reading a file that is only readable with FDA granted.
    case "hasFullDiskAccess":
      let home = FileManager.default.homeDirectoryForCurrentUser
      let probe = home.appendingPathComponent("Library/Safari/Bookmarks.plist")
      result(FileManager.default.isReadableFile(atPath: probe.path))

    // Deep-link into System Settings > Privacy & Security > Full Disk Access.
    case "openFullDiskAccessSettings":
      let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
      NSWorkspace.shared.open(url)
      result(nil)

    // Disk capacity. `volumeAvailableCapacityForImportantUsage` is what the
    // Finder / "About This Mac" show: it counts purgeable space as free.
    // -> { "total": Int64, "free": Int64 }
    case "volumeInfo":
      let url = URL(fileURLWithPath: args["path"] as? String ?? "/")
      do {
        let v = try url.resourceValues(forKeys: [.volumeTotalCapacityKey,
                                                 .volumeAvailableCapacityForImportantUsageKey])
        result(["total": v.volumeTotalCapacity ?? 0,
                "free": v.volumeAvailableCapacityForImportantUsage ?? 0])
      } catch {
        result(FlutterError(code: "volumeInfo", message: error.localizedDescription, details: nil))
      }

    // Read an .app bundle's identity. Bundle IDs are what tie an app to its
    // leftovers in ~/Library (e.g. com.spotify.client -> Caches/com.spotify.client).
    // -> { "bundleId": String?, "name": String?, "version": String? }
    case "appInfo":
      guard let path = args["path"] as? String, let bundle = Bundle(path: path) else {
        result(nil); return
      }
      let info = bundle.infoDictionary ?? [:]
      result(["bundleId": bundle.bundleIdentifier as Any,
              "name": (info["CFBundleDisplayName"] ?? info["CFBundleName"] ?? NSNull()) as Any,
              "version": info["CFBundleShortVersionString"] as Any])

    // Show the file in Finder.
    case "revealInFinder":
      if let path = args["path"] as? String {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
