//
//  MediaGallery.swift
//  iTello
//
//  Created by Michael Ellis on 12/26/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import SwiftUI
import Photos
import AVKit

struct MediaGallery: View {
    
    @StateObject var viewModel: MediaGalleryViewModel = MediaGalleryViewModel()
    
    @State var selectedVideoIndex = 0
    @Binding var displayMediaGallery: Bool
    
    var videoPlayer: some View {
        if self.viewModel.videoURLs.indices.contains(self.selectedVideoIndex) {
            let videoURL = self.viewModel.videoURLs[self.selectedVideoIndex]
            return VideoPlayer(player: AVPlayer(url: videoURL))
        } else {
            let videoURL: URL = Bundle.main.url(forResource: "itello-instructions", withExtension: "mov")!
            return VideoPlayer(player: AVPlayer(url: videoURL))
        }
    }
    
    var videosList: some View {
        ScrollView(.vertical) {
            LazyVStack {
                HStack {
                    Button(action: {
                        self.displayMediaGallery.toggle()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color.telloLight)
                            Text("Back")
                                .foregroundColor(Color.telloLight)
                        }
                        .padding(.vertical, 8)
                        .padding(.trailing, 4)
                    }
                    .contentShape(Rectangle())
                    Spacer()
                    Button(action: {
                        let fileManager = FileManager.default
                        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
                        guard let documentDirectoryURL: URL = urls.first as URL?,
                              var documentDirComponents = URLComponents(url: documentDirectoryURL, resolvingAgainstBaseURL: true) else {
                                  print("Error: Could Not Open Files App to s Directory")
                                  return
                              }
                        documentDirComponents.scheme = "shareddocuments"
                        if let docURL = documentDirComponents.url {
                            UIApplication.shared.open(docURL)
                        }
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Color.telloLight)
                            Text("Files")
                                .foregroundColor(Color.telloLight)
                        }
                        .frame(width: 80)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                Text("Videos")
                    .font(.headline)
                ForEach(self.viewModel.videoURLs, id: \.self) { videoURL in
                    HStack {
                        Button(action: {
                            if let newVideoIndex = self.viewModel.videoURLs.firstIndex(where: { $0 == videoURL }) {
                                self.selectedVideoIndex = newVideoIndex
                            }
                        }) {
                            Text(videoURL.lastPathComponent)
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        Button(action: {
                            let AV = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
                            UIApplication.shared.currentUIWindow()?.rootViewController?.present(AV, animated: true, completion: nil)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color.white)
                                .padding(.trailing, 16)
                        }
                        .contentShape(Rectangle())
                        
                    }
                    .frame(minHeight: 45, maxHeight: 90)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.telloBlue))
                }
                Spacer()
            }
            .onAppear { self.viewModel.reloadData() }
        }
    }
    
    var body: some View {
        GeometryReader { container in
            HStack {
                videosList
                    .frame(width: container.size.width / 3, height: container.size.height)
                videoPlayer
                    .frame(width: container.size.width * (2 / 3), height: container.size.height)
            }
            .padding(.horizontal, 16)
        }
    }
}

class MediaGalleryViewModel: ObservableObject {
    
    @Published private(set) public var videoURLs: [URL] = []
    
    init() {
        self.reloadData()
    }
    
    func reloadData() {
        var newURLs = self.fetchExistingVideos()
        let videoURL: URL = Bundle.main.url(forResource: "itello-instructions", withExtension: "mov")!
        newURLs.insert(videoURL, at: 0)
        self.videoURLs = newURLs
    }
    
    func fetchExistingVideos() -> [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            return fileURLs.filter { !$0.lastPathComponent.hasPrefix(".Trash") }
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return []
    }
}

public extension UIApplication {
    func currentUIWindow() -> UIWindow? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .filter({
                $0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
        let window = connectedScenes.first?
            .windows
            .first { $0.isKeyWindow }
        return window
    }
}
