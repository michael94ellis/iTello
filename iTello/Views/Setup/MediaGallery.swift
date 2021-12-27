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
    @ObservedObject var telloStore: TelloStoreViewModel
    
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
                        .padding(.vertical, 8)
                        .padding(.trailing, 4)
                    }
                    .contentShape(Rectangle())
                    Spacer()
                    if !self.telloStore.hasPurchasedRecording {
                        Button(action: {
                            self.telloStore.purchaseVideoRecording()
                        }) {
                            HStack {
                                Text("Upgrade iTello")
                                    .foregroundColor(Color.telloLight)
                            }
                            .padding(8)
                            .padding(.trailing, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.telloBlue))
                            .shadow(radius: 4)
                        }
                    } else {
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
                                Image(systemName: "doc.circle")
                                    .foregroundColor(Color.telloDark)
                                Text("See Files")
                                    .foregroundColor(Color.telloDark)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.telloSilver))
                        }
                        .contentShape(Rectangle())
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                Text("Videos")
                    .font(.headline)
                ForEach(self.viewModel.videoURLs, id: \.self) { videoURL in
                    HStack {
                        Button(action: {
                            self.selectedVideo = videoURL
                        }) {
                            Text(videoURL.lastPathComponent)
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        Button(action: {
                            let AV = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
                            UIApplication.shared.currentUIWindow()?.rootViewController?.present(AV, animated: true, completion: nil)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 16)
                        }
                        .contentShape(Rectangle())
                        
                    }
                    .frame(minHeight: 45, maxHeight: 90)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.telloBlue))
                }
                Spacer()
            }
        }
    }
    
    var body: some View {
        GeometryReader { container in
            HStack {
                videosList.frame(width: container.size.width / 3, height: container.size.height)
                videoPlayer.frame(width: container.size.width * (2 / 3), height: container.size.height)
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
