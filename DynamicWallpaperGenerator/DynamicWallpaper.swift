//
//  DynamicWallpaper.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-16.
//

import SwiftUI
import UniformTypeIdentifiers

/// Encoded dynamic wallpaper data that can be exported as a HEIC file.
struct DynamicWallpaper: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .heic) { $0.data }
    }
}
