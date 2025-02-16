//
//  ContentView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

enum DescriptionValentineAssembly {
    static func openValentine() -> UIViewController {
        let router = ValentineRouter()

        let view = DescriptionValentineView()
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}

struct DescriptionValentineView: View {
    var body: some View {
        VStack {
            HeartShape()
                .fill(Color.red)
                .frame(width: 200, height: 200)
                .padding(top: 40)
            
            Text("Я люблю Дашу всем сердцем, потому что её улыбка наполняет мою жизнь светом и радостью. Каждый момент, проведённый с ней, превращается в маленькое чудо, даря вдохновение и тепло моей душе.")
                .font(.title)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(top: 20, horizontal: 20)

            Spacer(minLength: .zero)
            
        }
    }
}


enum ValentineAssembly {
    static func openValentine() -> UIViewController {
        let router = ValentineRouter()

        let view = ValentineView(valentineRouter: router)
        let viewController = TAHostingController(rootView: view)

        router.parentController = viewController
        return viewController
    }
}

final class ValentineRouter: DefaultRouter {
    // MARK: - Public Properties
    
    weak var parentController: UIViewController?
    
    func openDescription() {
        guard let parentController else { return }
        let viewConreoller = DescriptionValentineAssembly.openValentine()
        push(viewConreoller, on: parentController)
    }
    
}
// Пользовательская фигура "Сердце"
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Начинаем с нижней точки сердца
        path.move(to: CGPoint(x: width / 2, y: height))
        
        // Левая сторона
        path.addCurve(
            to: CGPoint(x: 0, y: height / 4),
            control1: CGPoint(x: width / 2, y: height * 3/4),
            control2: CGPoint(x: 0, y: height / 2)
        )
        
        // Левый верхний полукруг
        path.addArc(
            center: CGPoint(x: width / 4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Правый верхний полукруг
        path.addArc(
            center: CGPoint(x: width * 3/4, y: height / 4),
            radius: width / 4,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Правая сторона
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height / 2),
            control2: CGPoint(x: width / 2, y: height * 3/4)
        )
        
        return path
    }
}

struct ValentineView: View {
    
    @State private var scale: CGFloat = 1.0
    private var valentineRouter: ValentineRouter
    
    init(valentineRouter: ValentineRouter) {
        self.valentineRouter = valentineRouter
    }
    
    var body: some View {
        ZStack {
            // Фон
            Color.pink.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Заголовок
                Text("С Днем Святого Валентина!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
//                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
//                    .padding()
                
                ZStack {
                    HeartShape()
                        .fill(Color.red)
                        .frame(width: 200, height: 200)
                    
                    
//                    Text("Даша")
//                        .font(.system(size: 40, weight: .bold))
//                        .foregroundColor(.white)
//                        .scaleEffect(scale)
//                        .animation(
//                            Animation.easeInOut(duration: 1.0)
//                                .repeatForever(autoreverses: true),
//                            value: scale
//                        )
                }.asButton(style: .scale(.heavy), action: valentineRouter.openDescription)
            }
        }
        .onAppear {
            // Запускаем анимацию пульсации
            scale = 1.2
        }
    }
}

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
        .ignoresSafeArea(edges: .top)
        .onAppear { viewModel.checkAccess() }
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
            }
            .padding(top: 14)
            .asButton(style: .opacity, action: { viewModel.konamiCodeCounter += 1 })
            
            
            
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
            .asButton(style: .scale(.light), action: viewModel.didTapSmartAnalize)
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
        ValentineView(valentineRouter: ValentineRouter())
//        DescriptionValentineView()
        
//        HomeView(
//            viewModel: HomeViewModel(
//                service: HomeService(),
//                router: HomeRouter()
//            )
//        )
    }
}
