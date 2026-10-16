//
//  GlassOrBorderedProminentButtonStyle.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-16.
//

import SwiftUI

struct GlassOrBorderedProminentButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26, *) {
            Button(configuration).buttonStyle(.glassProminent)
        } else {
            Button(configuration).buttonStyle(.borderedProminent)
        }
    }
}

extension PrimitiveButtonStyle
where Self == GlassOrBorderedProminentButtonStyle {
    static var glassOrBorderedProminent: GlassOrBorderedProminentButtonStyle {
        GlassOrBorderedProminentButtonStyle()
    }
}
