//
//  SplashView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 03.12.2024.
//

import SwiftUI

struct SplashView: View {
    // MARK: - Private Properties
    @ObservedObject private var viewModel: SplashViewModel
    @State private var progress: CGFloat = 0.0 // Для управления анимацией лоадера

    // MARK: - Init
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(alignment: .center, spacing: 52) {
                Image("app_icon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipped()
                    .padding(.top, 171)
                
                Text("Photo Master Assistant")
                    .font(.system(size: 32))
                    .bold()
                    .frame(maxWidth: 298)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Лоадер
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 10)
                
                GeometryReader { geometry in
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 10)
                        .animation(.easeInOut(duration: 2.0), value: progress)
                }
            }
            .padding(.bottom, 29)
            .padding(.horizontal, 106.5)
            .frame(height: 8)
        }
        .background(Color("whiteBlue"))
        .onAppear {
            startProgressAnimation()
        }
        // SwiftUI Alert, который отображается если showTrackingAlert == true
        .alert(isPresented: $viewModel.showTrackingAlert) {
            Alert(
                title: Text("Allow Tracking?"),
                message: Text("Please grant access to tracking for the best experience."),
                primaryButton: .default(Text("Open Settings"), action: {
                    viewModel.openSettings()
                }),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    // MARK: - Private Methods
    private func startProgressAnimation() {
        progress = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            viewModel.requestTrackingPermission {
                viewModel.openNextScreen()
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(
            viewModel: SplashViewModel(router: SplashRouter())
        )
    }
}
