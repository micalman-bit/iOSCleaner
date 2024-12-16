//
//  ContentView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: HomeViewModel
    
    // MARK: - Init
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("homeBg")
                .resizable()
                .scaledToFill()
                .frame(width: .screenWidth, height: .screenHeight)
                .clipped()

            VStack {
                makeHeaderView()
                    .padding(top: 50)
                
                makeContentView()
                
                Spacer(minLength: .zero)
                
                makeButtonListView()
            }
        }.ignoresSafeArea(edges: .top)
    }


    // MARK: - Header View
    
    @ViewBuilder private func makeHeaderView() -> some View {
        HStack(spacing: .zero) {
            Image("setting")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(leading: 24)
                .asButton(style: .scale(.heavy), action: viewModel.didTapSetting)
            
            Spacer(minLength: .zero)
            
            VStack(spacing: .zero) {
                Text(UIDevice.current.name)
                    .textStyle(.h1)
                Text("iOS " + UIDevice.current.systemVersion)
                    .textStyle(.text)
                    .padding(.bottom, 20)
            }.padding(top: 14)
            
            
            
            Spacer(minLength: .zero)
            
            switch viewModel.isHaveSubscription {
            case true:
                HStack(spacing: 3) {
                    Image("tick")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipped()
                }
                .frame(width: 45, height: 38)
                .background(Color.white)
                .cornerRadius(20)
                .padding(trailing: 24)
                .asButton(style: .scale(.heavy), action: viewModel.didTapSubscription)


            case false:
                HStack(spacing: 3) {
                    Image("crown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipped()

                    Text("PRO")
                        .textStyle(.textBold, textColor: .Typography.textWhite)
                }
                .frame(width: 68, height: 34)
                .background(
                    LinearGradient(
                        gradient: Gradient(
                            colors: Color.Gradients.proSubscriptionLogo
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .asButton(style: .scale(.heavy), action: viewModel.didTapSubscription)
            }
            
        }
    }
        
    
    // MARK: - Content View
    
    @ViewBuilder private func makeContentView() -> some View {
        VStack(spacing: .zero) {
            SemiRoundedProgressView(
                progress: viewModel.progress,
                totalSize: 250,
                freeSpaceText: String(format: "%.1f", viewModel.freeSpaceGB),
                totalSpaceText: String(format: "%.1f", viewModel.totalSpaceGB),
                smileText: viewModel.getSmile(),
                progressLineColor: viewModel.getLineColor()
            )
            .frame(width: 250, height: 250)
            
            Spacer().frame(height: 20)
            
            HStack(spacing: 6) {
                Image("cleanLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipped()
                
                Text("SMART CLEAN NOW")
                    .textStyle(.textBig, textColor: .Typography.textWhite)
                
            }
            .padding(vertical: 20, leading: 48.5, trailing: 62.5)
            .background(Color.blue)
            .cornerRadius(55)
            .padding(top: 20)
        }
        .padding(top: 28)
    }
    
    

    @ViewBuilder private func makeButtonListView() -> some View {
        VStack(spacing: 20) {
            
            ///  Photo & Video
            VStack(spacing: .zero) {
                HStack {
                    Image("photoLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipped()
                    
                    switch viewModel.isPhonoAndVideoAvailable {
                    case true:
                        Text("Photo & Video")
                            .textStyle(.h1, textColor: .Typography.textDark)
                    case false:
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calendar")
                                .textStyle(.h1, textColor: .Typography.textDark)
                            
                            Text("Need access, click to allow")
                                .textStyle(.text, textColor: .Typography.textGray)
                            
                        }
                    }
                    
                    Spacer()
                    
                    makeButtonOfItemView(
                        isEnabled: viewModel.isPhonoAndVideoAvailable,
                        isLoading: viewModel.isPhonoAndVideoLoaderActive,
                        title: viewModel.phonoAndVideoGBText
                    )
                }
                
                Divider()
                    .padding(top: 32)
            }.asButton(style: .opacity, action: viewModel.didTapPhotoAndVideo)
            
            /// Contact
            VStack(spacing: .zero) {
                HStack {
                    Image("contactLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipped()
                    
                    switch viewModel.isСontactsAvailable {
                    case true:
                        Text("Contact")
                            .textStyle(.h1, textColor: .Typography.textDark)
                    case false:
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Contact")
                                .textStyle(.h1, textColor: .Typography.textDark)

                            Text("Need access, click to allow")
                                .textStyle(.text, textColor: .Typography.textGray)
                            
                        }
                    }
                    
                    Spacer()

                    makeButtonOfItemView(
                        isEnabled: viewModel.isСontactsAvailable,
                        isLoading: viewModel.isСontactsLoaderActive,
                        title: viewModel.contactsText
                    )
                }
                
                Divider()
                    .padding(top: 32)
            }.asButton(style: .opacity, action: viewModel.didTapContact)

            /// Calendar
            VStack(spacing: .zero) {
                HStack {
                    Image("calendarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipped()
                    
                    switch viewModel.isCalendarAvailable {
                    case true:
                        Text("Calendar")
                            .textStyle(.h1, textColor: .Typography.textDark)
                    case false:
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Calendar")
                                .textStyle(.h1, textColor: .Typography.textDark)
                            
                            Text("Need access, click to allow")
                                .textStyle(.text, textColor: .Typography.textGray)
                        }
                    }
                    
                    Spacer(minLength: .zero)
                    
                    makeButtonOfItemView(
                        isEnabled: viewModel.isCalendarAvailable,
                        isLoading: viewModel.isCalendarLoaderActive,
                        title: viewModel.сalendarText
                    )
                }
                
                Divider()
                    .padding(top: 32)
            }.asButton(style: .opacity, action: viewModel.didTapCalendar)
        }
        .padding(top: 31, horizontal: 23)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Button List View

    @ViewBuilder private func makeButtonOfItemView(
        isEnabled: Bool,
        isLoading: Bool,
        title: String
    ) -> some View {
        switch isEnabled {
        case true:
            ZStack {
                HStack(spacing: .zero) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                    } else {
                        Text(title)
                            .foregroundColor(.blue)
                        
                        Image("arrow_down_sharp_right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .clipped()
                    }
                }
                .padding(vertical: 7, leading: 14, trailing: 4)
                .background(Color.Background.blueLight)
                .cornerRadius(40)
            }
        case false:
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else {
                    Image("arrow_down_sharp_right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipped()
                }
            }
            .padding(vertical: 7, horizontal: 7)
            .background(Color.Background.blueLight)
            .cornerRadius(40)
        }
    }

}

struct CleanerView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(
                service: HomeService(),
                router: HomeRouter()
            )
        )
    }
}
