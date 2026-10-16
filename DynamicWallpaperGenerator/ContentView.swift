//
//  ContentView.swift
//  DynamicWallpaperGenerator
//
//  Created by Nikita Ourazbaev on 2026-10-12.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private let generator = CombinedImageGenerator()

    @State private var lightImage: NSImage?
    @State private var darkImage: NSImage?

    @State private var generatedWallpaper: DynamicWallpaper?
    @State private var isExporting = false

    @State private var isGenerating = false

    @State private var showingErrorAlert: Bool
    @State private var errorMessage: String

    var imageDimensionsAreValid: Bool {
        if let lightImage, let darkImage,
            let lightImageRep = lightImage.widestRepresentation,
            let darkImageRep = darkImage.widestRepresentation
        {
            return lightImageRep.pixelsWide == darkImageRep.pixelsWide
                && lightImageRep.pixelsHigh == darkImageRep.pixelsHigh
        }

        return true
    }

    var noImages: Bool {
        lightImage == nil && darkImage == nil
    }

    var body: some View {
        VStack {
            Text("Drag and drop or paste images below")
                .foregroundStyle(.secondary)
                .opacity(noImages ? 1 : 0)
                .accessibilityHidden(noImages == false)

            HStack {
                VStack {
                    Label("Light", systemImage: "sun.max")
                        .fontWeight(.medium)

                    ImageWell(image: $lightImage)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .frame(maxWidth: 512)
                        .padding()
                }

                VStack {
                    Label("Dark", systemImage: "moon")
                        .fontWeight(.medium)

                    ImageWell(image: $darkImage)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .frame(maxWidth: 512)
                        .padding()
                }
            }
            .padding()

            Text(
                "Image dimensions don’t match – please use images of the same size"
            )
            .padding(.vertical, 3)
            .padding(.horizontal, 12)
            .background(.quaternary)
            .fontWeight(.medium)
            .clipShape(.capsule)
            .padding(.bottom)
            .opacity(imageDimensionsAreValid ? 0 : 1)
            .accessibilityHidden(imageDimensionsAreValid)

            Button {
                guard let lightImage, let darkImage else { return }

                Task {
                    isGenerating = true
                    defer { isGenerating = false }

                    do {
                        if let data = try await generator.generate(
                            lightImage: lightImage,
                            darkImage: darkImage
                        ) {
                            generatedWallpaper = DynamicWallpaper(data: data)

                            isExporting = true
                        }
                    } catch GeneratorError.failed(let message) {
                        showingErrorAlert = true
                        errorMessage = message
                    } catch {
                        showingErrorAlert = true
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                ZStack {
                    Label("Generate", systemImage: "sparkles.rectangle.stack")
                        .font(.title2)
                        .fontWeight(.medium)
                        .opacity(isGenerating ? 0 : 1)

                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .buttonStyle(.glassOrBorderedProminent)
            .disabled(
                lightImage == nil || darkImage == nil
                    || imageDimensionsAreValid == false || isGenerating
                    || isExporting
            )
        }
        .padding()
        .alert("Error", isPresented: $showingErrorAlert) {
        } message: {
            Text(errorMessage)
        }
        .fileExporter(
            isPresented: $isExporting,
            item: generatedWallpaper,
            contentTypes: [.heic],
            defaultFilename: "Dynamic Wallpaper"
        ) { result in
            if case .failure(let error) = result {
                print("Could not save wallpaper: \(error)")
            }
            generatedWallpaper = nil
        } onCancellation: {
            generatedWallpaper = nil
        }
    }
}

#Preview {
    ContentView()
}
