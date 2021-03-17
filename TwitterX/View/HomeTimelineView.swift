//
//  HomeView.swift
//  TwitterX
//
//  Created by Piyush Kant on 2021/03/06.
//

import SwiftUI
import LinkPresentation
import AVKit
import SwiftyGif

struct HomeTimelineConfig {
    static let TweetsLimit = 10
    static let sampleSingleImageTweetId = "1370325033663426560" //1370325033663426560 //1370329824422551554
    static let sampleMultipleImageTweetId = "1370337291214888962"
    static let sampleImageWithUrlId = "1370316972181848066"
    static let sampleGifTweetId = "1370922422233358336"
    static let sampleVideoTweetId = "1370320412177993739"
}

struct HomeTimelineView: View {
    @ObservedObject var homeTimelineViewModel: HomeTimelineViewModel
    
    init() {
        homeTimelineViewModel = HomeTimelineViewModel()
    }
    
    var body: some View {
        let tweets: [Tweet] = self.homeTimelineViewModel.tweets
        
        NavigationView {
            List(0..<tweets.count, id: \.self) { i in
                if i == tweets.count - 1 {
                    HomeTimelineCellView(tweet: tweets[i], isLast: true, homeTimelineViewModel: self.homeTimelineViewModel)
                } else {
                    HomeTimelineCellView(tweet: tweets[i], isLast: false, homeTimelineViewModel: self.homeTimelineViewModel)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                //                homeTimelineViewModel.fetchHomeTimeline(count: HomeTimelineConfig.TweetsLimit)
                homeTimelineViewModel.fetchSingleTimeLine(id: HomeTimelineConfig.sampleMultipleImageTweetId)
            }
            .navigationBarBackButtonHidden(true)
            .listStyle(PlainListStyle())
            //            .navigationBarTitle(Text(NSLocalizedString("homeTimeline", comment: "")))
            .navigationBarItems(trailing:
                                    Button("Settings") {}
            )
        }
    }
}

struct HomeTimelineCellView: View {
    let tweet: Tweet
    var isLast: Bool
    @ObservedObject var homeTimelineViewModel: HomeTimelineViewModel
    @State var togglePreview = false
    
    var body: some View {
        //        Mark: Disabled for now due to api usage limit
        //        let tweets: [Tweet] = self.homeTimelineViewModel.tweets
        
        VStack(alignment: .leading, spacing: 10) {
            let headline = tweet.text
            
            if let userData = homeTimelineViewModel.fetchUserData(tweet: self.tweet), let data = userData.profileImageData {
                UserView(tweet: self.tweet, data: data)
            }
            
            HyperlinkTextView(headline)
                .fixedSize(horizontal: false, vertical: true)
            

            if let userTweetData = homeTimelineViewModel.fetchUserTweetData(tweet: self.tweet) {
                let mediaType = homeTimelineViewModel.mediaType
                
                //Mark: for now gif will act as video. Fix this if found some good solution
                if (mediaType == .GIF) {
                    /*let gifUrl = homeTimelineViewModel.userTweetData.first?.attachedVideoUrl
                     
                     if let gifUrl = gifUrl, let url = URL(string: gifUrl) {
                     GifView(url: url)
                     .frame(height: 197)
                     .cornerRadius(10)

                     }*/
                    
                    let videoUrl = homeTimelineViewModel.userTweetData.first?.attachedVideoUrl

                    if let videoUrl = videoUrl, let url = URL(string: videoUrl) {
                        let player = AVPlayer(url: url)

                        VideoPlayer(player: player)
                            .frame(height: 197)
                            .cornerRadius(10)
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    }
                } else if (mediaType == .VIDEO) {
                    let videoUrl = homeTimelineViewModel.userTweetData.first?.attachedVideoUrl

                    if let videoUrl = videoUrl, let url = URL(string: videoUrl) {
                        let player = AVPlayer(url: url)
                        
                        VideoPlayer(player: player)
                            .frame(height: 197)
                            .cornerRadius(10)
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    }
                } else if (mediaType == .IMAGES) {
                    if let attachedImages = userTweetData.attachedImages {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
                        
                        LazyVGrid(columns: columns, alignment: .center, spacing: 10, content: {
                            ForEach(attachedImages, id:\.self) { image in
                                GridImageView(homeTimelineViewModel: homeTimelineViewModel, image: image)
                            }
                        })
                        .padding(.top)
                        .overlay(
                            ImageView(homeTimelineViewModel: homeTimelineViewModel, images: attachedImages)
                        )
                    }
                } else {
                    if let link = homeTimelineViewModel.fetchLink(tweet: tweet) {
                        LinkPreview(link: link)
                    } else if let tweetUrl = tweet.entities.urls.first?.url, let url = URL(string: tweetUrl) {
                        EmptyLinkPreview(url: url)
                    }
                }
            }
            
            if self.isLast {
                Text("").onAppear {
                    
                    //                    Mark: Disabled for now due to api usage limit
                    //                    self.homeTimelineViewModel.fetchHomeTimeline(count: tweets.count + HomeTimelineConfig.TweetsLimit)
                }
            }
            
        }
    }
}

struct GridImageView: View {
    @ObservedObject var homeTimelineViewModel: HomeTimelineViewModel
    var image: AttachedImage
    
    var body: some View {
        Button(action: {
            homeTimelineViewModel.selectedImageID = image.id
            homeTimelineViewModel.showImageViewer.toggle()
            
        }, label: {
            ZStack {
                Image(uiImage: image.image ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: (UIScreen.main.bounds.width - 100)/2, height: 120)
                    .cornerRadius(12)
            }
        })
    }
}

struct ImageView: View {
    @ObservedObject var homeTimelineViewModel: HomeTimelineViewModel
    let images: [AttachedImage]
    @GestureState var draggingOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            if homeTimelineViewModel.showImageViewer {
                Color(.black)
                    .opacity(homeTimelineViewModel.bgOpacity)
                    .ignoresSafeArea()
                
                ScrollView(.init()) {
                    TabView(selection: $homeTimelineViewModel.selectedImageID) {
                        ForEach(images, id: \.self) {image in
                            Image(uiImage: image.image ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(image)
                                .scaleEffect(homeTimelineViewModel.selectedImageID == image.id ? (homeTimelineViewModel.imageScale > 1 ? homeTimelineViewModel.imageScale : 1) : 1)
                                .offset(y: homeTimelineViewModel.imageViewerOffset.height)
                                .gesture(
                                    MagnificationGesture().onChanged({(value) in
                                        homeTimelineViewModel.imageScale = value
                                    }).onEnded({(_) in
                                        withAnimation(.spring()){
                                            homeTimelineViewModel.imageScale = 1
                                        }
                                    })
                                    
                                    .simultaneously(with: DragGesture(minimumDistance: homeTimelineViewModel.imageScale == 1 ? 1000 : 0))
                                    
                                    .simultaneously(with: TapGesture(count: 2).onEnded({
                                        withAnimation {
                                            homeTimelineViewModel.imageScale = homeTimelineViewModel.imageScale > 1 ? 1 : 4
                                        }
                                    }))
                                )
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                }
                .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Button(action: {
                homeTimelineViewModel.showImageViewer.toggle()
            }, label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.35))
                    .clipShape(Circle())
            })
            .padding(10)
            .opacity(homeTimelineViewModel.showImageViewer ? homeTimelineViewModel.bgOpacity : 0)
            
            , alignment: .topTrailing
        )
    }
}

struct GifView: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> UIView {
        do {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 200))
            
            let gif = try UIImage(gifName: "giphy.gif")
            let imageview = UIImageView(gifImage: gif, loopCount: 3)
            imageview.frame = view.bounds
            view.addSubview(imageview)
            
            return view
        } catch {
            print(error)
        }
        
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

struct EmptyLinkPreview: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: url)
        linkView.sizeToFit()
        
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
    }
}

struct LinkPreview: UIViewRepresentable {
    var link: Link
    
    func makeUIView(context: Context) -> LPLinkView {
        let linkView = LPLinkView(url: link.url)
        
        linkView.metadata = link.data
        linkView.sizeToFit()
        
        return linkView
    }
    
    func updateUIView(_ uiView: LPLinkView, context: Context) {
    }
}

struct UserView: View {
    let tweet: Tweet
    let data: Data
    
    @State var currentDate = Date()
    private let timer = Timer.publish(every: 10, on: .main, in: .common)
        .autoconnect()
        .eraseToAnyPublisher()
    
    var body: some View {
        HStack(spacing: 10) {
            Image(uiImage: UIImage(data: data) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:50, height:50)
                .cornerRadius(50)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(tweet.user.name)
                    .bold()
                    .font(.system(size:18.0))
                PostTimeView(tweet: tweet, currentDate: currentDate)
            }
        }
        .onReceive(timer) {
            self.currentDate = $0
        }
    }
}

struct PostTimeView: View {
    let tweet: Tweet
    let currentDate: Date
    
    private static var relativeFormatter = RelativeDateTimeFormatter()
    
    private var relativeTimeString: String {
        if let dateCreated =  Utils.convertStringToDate(dateString: tweet.createdAt) {
            return PostTimeView.relativeFormatter.localizedString(fromTimeInterval: dateCreated.timeIntervalSince1970 - self.currentDate.timeIntervalSince1970)
        }
        return ""
    }
    
    var body: some View {
        Text("\(relativeTimeString) by @\(tweet.user.screenName)")
            .font(.system(size: 14))
            .foregroundColor(Color.gray)
    }
}


