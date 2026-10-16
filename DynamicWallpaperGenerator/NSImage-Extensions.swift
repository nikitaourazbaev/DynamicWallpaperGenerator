//
//  NSImage-Extensions.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-15.
//

import AppKit

extension NSImage {
    nonisolated func defaultCGImage() -> CGImage? {
        self.widestRepresentation?.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        )
    }

    nonisolated var widestRepresentation: NSImageRep? {
        self.representations.max { a, b in a.pixelsWide < b.pixelsWide }
    }
}
