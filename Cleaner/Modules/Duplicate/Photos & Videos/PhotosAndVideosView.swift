//
//  PhotosAndVideosView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 06.01.2025.
//

import SwiftUI

struct PhotosAndVideosView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: PhotosAndVideosViewModel
    
    // MARK: - Init
    
    init(viewModel: PhotosAndVideosViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .zero) {
            makeHeaderView()
         
            if viewModel.isAnalyzing {
                makeLoaderView()
            } else {
                makeContentView()
                    .padding(horizontal: 20)
                    .background(Color.hexToColor(hex: "#F4F7FA"))
            }
            
            Spacer(minLength: .zero)
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateCalendarCounter)) { notification in
            if let counter = notification.userInfo?["counter"] as? Int {
                viewModel.updateCalendarCounter(counter)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .updateContactCounter)) { notification in
            if let counter = notification.userInfo?["counter"] as? Int {
                viewModel.updateContactCounter(counter)
            }
        }
    }
    
    @ViewBuilder private func makeHeaderView() -> some View {
        HStack(spacing: .zero) {
            HStack {
                Image(systemName: "chevron.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 20)
                    .foregroundColor(.blue)
                
                Text("Back")
                    .foregroundColor(.blue)
                    .font(.system(size: 17))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .asButton(style: .opacity, action: viewModel.dismiss)
            
            Text(viewModel.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 140, alignment: .center)

            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.white)
    }

    @ViewBuilder private func makeContentView() -> some View {
        ScrollView(showsIndicators: false) {
            ForEach(viewModel.listOfItems) { item in
                HStack(spacing: 8) {
                    
                    if let letftImage = item.letftImage {
                        letftImage.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: letftImage.size, height: letftImage.size)
                    }
                    
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(item.leftTitle)
                            .textStyle(.h1)
                            .lineLimit(1)
                        
                        Text(item.leftSubtitle)
                            .textStyle(
                                .text,
                                textColor: item.isLoading ? Color.hexToColor(hex: "#1D71FF") : .Typography.textGray
                            )
                    }.padding(leading: 12)
                    
                    Spacer(minLength: .zero)
                    
                    if let rightTitle = item.rightTitle {
                        Text(rightTitle)
                            .textStyle(
                                .price,
                                textColor: item.isLoading ? Color.hexToColor(hex: "#1D71FF") : .Typography.textGray
                            )
                    }

                    if let rightImage = item.rightImage {
                        rightImage.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: rightImage.size, height: rightImage.size)
                    }
                }
                .padding(vertical: 22.5, horizontal: 20)
                .background(Color.white)
                .cornerRadius(14)
                .padding(top: 16)
                .asButton(style: .scale(.light), action: item.action)
            }.padding(horizontal: 20)
            
            Spacer(minLength: .zero)
                .frame(width: .screenWidth)
        }
    }
    
    // MARK: - Loader View
    
    @ViewBuilder private func makeLoaderView() -> some View {
        VStack(spacing: .zero) {
            ZStack {
                LottieView(name: "loaderClenaer ", isActive: true, loopMode: .loop)
                    .frame(width: 300, height: 300)
                    .padding(top: 110)
                
                VStack(spacing: .zero) {
                    Text(viewModel.timerText)
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("Analysis in\nprogress")
                        .textStyle(.flatCount)
                        .multilineTextAlignment(.center)
                    
                }.padding(top: 110)
                
            }
            
            Spacer(minLength: .zero)
            
            HStack {
                Image("tick_black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipped()
                
                Text("It won't take long...")
                    .textStyle(.flatCount)
            }
        }
    }
}

struct PhotosAndVideosView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosAndVideosView(
            viewModel: PhotosAndVideosViewModel(
                service: PhotosAndVideosService(),
                router: PhotosAndVideosRouter(), screenType: .analyzeStorage
            )
        )
    }
}
