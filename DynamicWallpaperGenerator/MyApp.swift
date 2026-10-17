//
//  MyApp.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-12.
//

import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        Window("Dynamic Wallpaper Generator", id: "main") {
            ContentView()
                .frame(minWidth: 736, minHeight: 418)
        }
        .defaultSize(width: 736, height: 418)
        .windowResizability(.contentSize)
    }
}
