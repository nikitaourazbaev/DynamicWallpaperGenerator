//
//  DynamicWallpaper.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-16.
//

import CoreTransferable
import UniformTypeIdentifiers

/// Encoded dynamic wallpaper data that can be exported as an HEIC file.
struct DynamicWallpaper: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .heic) { $0.data }
    }
}
