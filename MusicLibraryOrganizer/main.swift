//
//  main.swift
//  MusicLibraryOrganizer
//
//  Created by Kyle Erhabor on 6/26/23.
//

import Foundation
import AVFoundation

enum UserError: Error {
  case invalidPath(_ path: String)
}

func metadataForItem<T>(
  _ item: [AVMetadataItem],
  byIdentifier identifier: AVMetadataIdentifier,
  forType type: AVAsyncProperty<AVMetadataItem, T>
) async throws -> T? {
  // This seems to be producing a double optional.
  return try await AVMetadataItem.metadataItems(from: item, filteredByIdentifier: identifier).first?.load(type)
}

func flatten<T>(_ x: T??) -> T? {
  guard let x else {
    return nil
  }

  return x
}

func run() async throws {
  let paths = CommandLine.arguments.dropFirst()
  let urls = try paths.map { path in
    guard var components = URLComponents(string: path) else {
      throw UserError.invalidPath(path)
    }

    components.scheme = "file"

    return components.url!
  }

  for url in urls {
    let asset = AVAsset(url: url)
    let metadata: [AVMetadataItem]

    do {
      metadata = try await asset.load(.metadata)
      // This will most likely occur when something that isn't an audio file is loaded (e.g. a cover image).
    } catch let err as AVError where err.code == .fileFormatNotRecognized {
      print("Could not load the metadata of \(url) due to the file format not being recognized.")

      continue
    }

    // NOTE: If the asset is a FLAC, no metadata will be extracted.
    let album = flatten(try await metadataForItem(metadata, byIdentifier: .commonIdentifierAlbumName, forType: .stringValue))
    // NOTE: I've thought about using ~/Music/Local before, but the music folder is "logically owned/coupled" to
    // Apple's music software (Apple Music, GarageBand, etc.), so I'm not sure it would be safe to do so.
    var library = URL.homeDirectory.appending(components: "Media", "Music")

    if let album, album.lowercased().contains("soundtrack") || album.lowercased().contains("sound track") {
      library.append(component: album)
    } else {
      var artist = flatten(try await metadataForItem(metadata, byIdentifier: .id3MetadataBand, forType: .stringValue))

      if artist == nil {
        artist = flatten(try await metadataForItem(metadata, byIdentifier: .commonIdentifierArtist, forType: .stringValue))
      }

      if let artist, let album {
        library.append(component: "\(artist) - \(album)")
      } else if let name = album ?? artist {
        library.append(component: name)
      } else {
        // Rather than saving to the top directory (which would be a disaster for FLACs), we'll just ignore the file.
        print("No adequate metadata in \(url) to organize.")

        continue
      }
    }

    let discs = try await AVMetadataItem.metadataItems(from: metadata, withKey: "TPOS", keySpace: .id3).first?.load(.stringValue)?
      .split(separator: "/")

    if let discs {
      let disc = Int(discs.first!)!

      if disc > 1 || Int(discs.last ?? "0")! > 1 {
        library.append(component: "Disc \(disc)")
      }
    }

    guard let track = flatten(try await metadataForItem(metadata, byIdentifier: .commonIdentifierTitle, forType: .stringValue)) else {
      print("\(url) is missing a title.")

      continue
    }

    if let no = flatten(try await metadataForItem(metadata, byIdentifier: .id3MetadataTrackNumber, forType: .stringValue))?
      .split(separator: "/")
      .first {
      library.append(component: "\(no). \(track)")
    } else {
      library.append(component: track)
    }

    library.appendPathExtension(url.pathExtension)

    do {
      try FileManager.default.createDirectory(at: library.deletingLastPathComponent(), withIntermediateDirectories: true)
      try FileManager.default.moveItem(at: url, to: library)
    } catch {
      print("Couldn't move \(url).")

      return
    }
  }
}

var stderr = FileHandle.standardError

extension FileHandle: TextOutputStream {
  public func write(_ string: String) {
    let data = Data(string.utf8)

    self.write(data)
  }
}

do {
  try await run()
} catch {
  // TODO: Provide user-formatted error messages for each case.
  print("\(error)", to: &stderr)

  // Dropover recognizes that the script failed from its status code.
  exit(1)
}
