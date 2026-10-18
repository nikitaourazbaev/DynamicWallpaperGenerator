//
//  ImageWell.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-12.
//

import AppKit
import SwiftUI

struct ImageWell: NSViewRepresentable {
    @Binding var image: NSImage?

    class Coordinator: NSObject {
        var parent: ImageWell

        init(_ parent: ImageWell) {
            self.parent = parent
        }

        @objc func imageDidChange(_ sender: NSImageView) {
            parent.image = sender.image
        }
    }

    /// Does not accept focus if window is invisible (workaround for inconsistent focus behaviour across relaunches).
    class CustomImageView: NSImageView {
        override func becomeFirstResponder() -> Bool {
            guard window?.isVisible == true else { return false }

            return super.becomeFirstResponder()
        }
    }

    func makeNSView(context: Context) -> NSImageView {
        let view = CustomImageView()

        view.isEditable = true
        view.allowsCutCopyPaste = true

        view.imageFrameStyle = .grayBezel
        view.imageScaling = .scaleProportionallyUpOrDown

        view.target = context.coordinator
        view.action = #selector(Coordinator.imageDidChange(_:))

        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        context.coordinator.parent = self

        if view.image !== image {
            view.image = image
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
