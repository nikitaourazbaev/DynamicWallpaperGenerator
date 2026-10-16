//
//  CombinedImageGenerator.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-15.
//

/// Based on https://remove.codes/01-dynamic-wallpaper

import AppKit
import CoreTransferable
import ImageIO
import UniformTypeIdentifiers

enum GeneratorError: Error {
    case failed(message: String)
}

struct CombinedImageGenerator {
    nonisolated func createMetadata() -> CGMutableImageMetadata? {
        let ns = "http://ns.apple.com/namespace/1.0" as CFString

        // {"l": 0, "d": 1} as a base64-encoded binary plist
        let apr =
            "YnBsaXN0MDDSAQIDBFFsUWQQABABCA0PERMAAAAAAAABAQAAAAAAAAAFAAAAAAAAAAAAAAAAAAAAFQ=="

        guard
            let tag = CGImageMetadataTagCreate(
                ns,
                "apple_desktop" as CFString,
                "apr" as CFString,
                .string,
                apr as CFString
            )

        else {
            print("createMetadata: Couldn’t create tag")
            return nil
        }

        let mutableMetadata = CGImageMetadataCreateMutable()

        let didRegisterNSPrefix = CGImageMetadataRegisterNamespaceForPrefix(
            mutableMetadata,
            ns,
            "apple_desktop" as CFString,
            nil
        )

        if didRegisterNSPrefix == false {
            print("createMetadata: Could not register namespace prefix")
            return nil
        }

        let didSaveTagInMetadata = CGImageMetadataSetTagWithPath(
            mutableMetadata,
            nil,
            "apple_desktop:apr" as CFString,
            tag
        )

        if didSaveTagInMetadata == false {
            print("createMetadata: Could not save tag in metadata")
            return nil
        }

        return mutableMetadata
    }

    func generate(lightImage: NSImage, darkImage: NSImage) async throws -> Data?
    {
        guard let lightCGImage = lightImage.defaultCGImage() else {
            throw GeneratorError.failed(
                message: "Could not generate light CGImage"
            )

        }

        guard let darkCGImage = darkImage.defaultCGImage() else {
            throw GeneratorError.failed(
                message: "Could not generate dark CGImage"
            )
        }

        return try await encode(
            lightCGImage: lightCGImage,
            darkCGImage: darkCGImage
        )
    }

    @concurrent
    private nonisolated func encode(lightCGImage: CGImage, darkCGImage: CGImage)
        async throws -> Data?
    {
        guard let metadata = createMetadata() else {
            throw GeneratorError.failed(
                message: "Could not create appearance metadata"
            )
        }

        let resultData = NSMutableData()

        let destination = CGImageDestinationCreateWithData(
            resultData as CFMutableData,
            UTType.heic.identifier as CFString,
            2,
            nil
        )

        guard let destination else {
            throw GeneratorError.failed(message: "Could not create destination")
        }

        // Full quality HEIC
        let imageProperties =
            [
                kCGImageDestinationLossyCompressionQuality: 1.0
            ] as CFDictionary

        // The appearance metadata goes on the first (light) image.
        CGImageDestinationAddImageAndMetadata(
            destination,
            lightCGImage,
            metadata,
            imageProperties
        )

        CGImageDestinationAddImage(destination, darkCGImage, imageProperties)

        if CGImageDestinationFinalize(destination) == false {
            throw GeneratorError.failed(
                message: "Could not encode combined image"
            )
        }

        return resultData as Data
    }
}
