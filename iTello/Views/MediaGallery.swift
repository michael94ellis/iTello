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
    
    @State var selectedVideo: URL?
    @Binding var displayMediaGallery: Bool
    
    var videoPlayer: some View {
        if let  selectedVideo = selectedVideo {
            return VideoPlayer(player: AVPlayer(url: selectedVideo))
        } else {
            let videoURL: URL = Bundle.main.url(forResource: "itello-initial", withExtension: "mov")!
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
                        .padding(8)
                        .padding(.trailing, 4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloBlue))
                    }
                    Spacer()
                }
                .padding(32)
                Text("Videos")
                ForEach(self.viewModel.videoURLs, id: \.self) { videoURL in
                    HStack {
                        Text(videoURL.lastPathComponent)
                            .foregroundColor(Color.white)
                    }
                    .background(Color.blue)
                }
                Spacer()
            }
            .border(Color.red)
        }
    }
    
    var body: some View {
        GeometryReader { container in
            VStack {
                if container.size.width > container.size.height {
                    HStack {
                        videosList.frame(width: container.size.width / 2, height: container.size.height)
                        videoPlayer.frame(width: container.size.width / 2, height: container.size.height)
                    }
                } else {
                    VStack {
                        videoPlayer.frame(width: container.size.width / 2, height: container.size.height)
                        videosList.frame(width: container.size.width / 2, height: container.size.height)
                    }
                }
            }
        }
    }
}

class MediaGalleryViewModel: ObservableObject {
    
    @Published private(set) public var videoURLs: [URL] = []
    
    init() {
        PHPhotoLibrary.requestAuthorization { authStatus in
            if authStatus != .authorized {
                print(authStatus)
                // TODO: Handle this error
            }
            DispatchQueue.main.async {
                self.videoURLs = self.fetchExistingVideos()
                let videoURL: URL = Bundle.main.url(forResource: "itello-initial", withExtension: "mov")!
                self.videoURLs.insert(videoURL, at: 0)
            }
        }
    }
    
    func fetchExistingVideos() -> [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print(fileURLs)
            return fileURLs
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return []
    }
}
