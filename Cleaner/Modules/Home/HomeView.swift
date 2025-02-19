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
    @State private var animate = false

    // MARK: - Init
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("homeBg")
                .resizable()
                .scaledToFit()
                .imageScale(.large)
                .frame(width: .screenWidth, height: .screenHeight - 150)
                .clipped()
                .overlay(
                    Color.hexToColor(hex: "#C1E3FF").opacity(0.5)
                        .blendMode(.luminosity)
                )
                .contrast(1.1)


            VStack {
                makeHeaderView()
                    .padding(top: 50)
                
                makeContentView()
                    .padding(bottom: 20)
                
                Spacer(minLength: .zero)
                
                makeButtonListView()
            }
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
        .ignoresSafeArea(edges: .top)
        .onAppear { viewModel.checkAccess() }
    }


    // MARK: - Header View
    @ViewBuilder private func makeHeaderView() -> some View {
        ZStack {
            // Центрированный заголовок
            VStack(spacing: .zero) {
                Text(UIDevice.current.name)
                    .textStyle(.h1)
                Text("iOS " + UIDevice.current.systemVersion)
                    .textStyle(.text)
                    .padding(.bottom, 20)
            }
            .padding(.top, 14)
            .asButton(style: .opacity, action: { viewModel.konamiCodeCounter += 1 })
            .frame(maxWidth: .infinity)

            // Элементы, размещенные по краям (например, кнопка настроек слева)
            HStack {
                Image("Setting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(.leading, 24)
                    .asButton(style: .scale(.heavy), action: viewModel.didTapSetting)
                Spacer()
            }
        }
    }

//    @ViewBuilder private func makeHeaderView() -> some View {
//        HStack(spacing: .zero) {
//            Image("Setting")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 40, height: 40)
//                .padding(leading: 24)
//                .asButton(style: .scale(.heavy), action: viewModel.didTapSetting)
//            
//            Spacer(minLength: .zero)
//            
//            VStack(spacing: .zero) {
//                Text(UIDevice.current.name)
//                    .textStyle(.h1)
//                Text("iOS " + UIDevice.current.systemVersion)
//                    .textStyle(.text)
//                    .padding(.bottom, 20)
//            }
//            .padding(top: 14)
//            .asButton(style: .opacity, action: { viewModel.konamiCodeCounter += 1 })
//            
//            
//            Spacer()
//                .frame(width: 64)
//            
//            switch viewModel.isHaveSubscription {
//            case true:
//                HStack(spacing: 3) {
//                    Image("tick")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 24, height: 24)
//                        .clipped()
//                }
//                .frame(width: 45, height: 38)
//                .background(Color.white)
//                .cornerRadius(20)
//                .padding(trailing: 24)
//
//            case false:
//                HStack(spacing: 3) {
//                    Image("crown")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 16, height: 16)
//                        .clipped()
//
//                    Text("PRO")
//                        .textStyle(.textBold, textColor: .Typography.textWhite)
//                }
//                .frame(width: 68, height: 34)
//                .background(
//                    LinearGradient(
//                        gradient: Gradient(
//                            colors: Color.Gradients.proSubscriptionLogo
//                        ),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .cornerRadius(20)
//            }
//        }
//    }
        
    
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
                Image("")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipped()
                
                Text("SMART ANALYZE")
                    .textStyle(.textBig, textColor: .Typography.textWhite)
                
            }
            .padding(vertical: 20, leading: 48.5, trailing: 62.5)
            .background(Color.blue)
            .cornerRadius(55)
            .padding(top: 20)
            .asButton(
                style: .scale(.light),
                action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.didTapSmartAnalize()
                }
            )
            .scaleEffect(animate ? 1.05 : 0.95)
            .animation(
                .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true),
                value: animate
            )
            // При появлении вью запускаем анимацию
            .onAppear {
                animate = true
            }

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
                        HStack(spacing: 10) {
                            Text("Photo & Video")
                                .textStyle(.h1, textColor: .Typography.textDark)
                            
                            Spacer(minLength: .zero)
//                            Text(viewModel.totalFilesCount)
//                                .font(.system(size: 17, weight: .regular))
//                                .foregroundColor(.Typography.textDark)

                        }.frame(maxWidth: .infinity)
                    case false:
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Photo & Video")
                                .textStyle(.h1, textColor: .Typography.textDark)
                            
                            Text("Need access, click to allow")
                                .textStyle(.text, textColor: .Typography.textGray)
                            
                        }
                    }
                    
                    Spacer()
                    
                    makeButtonOfItemView(
                        .photoVideo,
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
                        .contact,
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
                        .calendar,
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
        _ type: HomeButtonType,
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
//        ValentineView(valentineRouter: ValentineRouter())
//        DescriptionValentineView()
        
        HomeView(
            viewModel: HomeViewModel(
                service: HomeService(),
                router: HomeRouter()
            )
        )
    }
}
