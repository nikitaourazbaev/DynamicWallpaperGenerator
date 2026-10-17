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

enum GeneratorError: LocalizedError {
    case couldNotCreateLightImage
    case couldNotCreateDarkImage
    case couldNotCreateMetadataTag
    case couldNotRegisterMetadataTagNamespace
    case couldNotSaveTagInMetadata
    case couldNotCreateDestination
    case couldNotEncodeDestinationImage

    var errorDescription: String? {
        switch self {
        case .couldNotCreateLightImage:
            "Could not read the light image."
        case .couldNotCreateDarkImage:
            "Could not read the dark image."
        case .couldNotCreateMetadataTag,
            .couldNotRegisterMetadataTagNamespace,
            .couldNotSaveTagInMetadata:
            "Could not create appearance metadata."
        case .couldNotCreateDestination:
            "Could not create the destination."
        case .couldNotEncodeDestinationImage:
            "Could not encode the output image."
        }
    }
}

struct CombinedImageGenerator {
    // (unsafe) because CGImageMetadata isn’t Sendable
    private nonisolated(unsafe) static let metadata = Result {
        try createMetadata()
    }

    private nonisolated static func createMetadata() throws -> CGImageMetadata {
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
            throw GeneratorError.couldNotCreateMetadataTag
        }

        let mutableMetadata = CGImageMetadataCreateMutable()

        let didRegisterNSPrefix = CGImageMetadataRegisterNamespaceForPrefix(
            mutableMetadata,
            ns,
            "apple_desktop" as CFString,
            nil
        )

        if didRegisterNSPrefix == false {
            throw GeneratorError.couldNotRegisterMetadataTagNamespace
        }

        let didSaveTagInMetadata = CGImageMetadataSetTagWithPath(
            mutableMetadata,
            nil,
            "apple_desktop:apr" as CFString,
            tag
        )

        if didSaveTagInMetadata == false {
            throw GeneratorError.couldNotSaveTagInMetadata
        }

        return mutableMetadata
    }

    func generate(lightImage: NSImage, darkImage: NSImage) async throws -> Data
    {
        guard let lightCGImage = lightImage.defaultCGImage() else {
            throw GeneratorError.couldNotCreateLightImage
        }

        guard let darkCGImage = darkImage.defaultCGImage() else {
            throw GeneratorError.couldNotCreateDarkImage
        }

        return try await encode(
            lightCGImage: lightCGImage,
            darkCGImage: darkCGImage
        )
    }

    @concurrent
    private nonisolated func encode(lightCGImage: CGImage, darkCGImage: CGImage)
        async throws -> Data
    {
        let metadata = try Self.metadata.get()

        let resultData = NSMutableData()

        let destination = CGImageDestinationCreateWithData(
            resultData as CFMutableData,
            UTType.heic.identifier as CFString,
            2,
            nil
        )

        guard let destination else {
            throw GeneratorError.couldNotCreateDestination
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
            throw GeneratorError.couldNotEncodeDestinationImage
        }

        return resultData as Data
    }
}
