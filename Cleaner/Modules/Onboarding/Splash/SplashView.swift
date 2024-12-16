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
        VStack(spacing: .zero) {
            Image("app_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipped()
                .padding(top: 171)
            
            Spacer(minLength: .zero)
            
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
            .padding(bottom: 29, horizontal: 106.5)
            .onAppear {
                startProgressAnimation()
            }
            .frame(height: 8)

        }
        .background(Color.Background.whiteBlue)
    }
    
    private func startProgressAnimation() {
        progress = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            requestTrackingPermission()
        }
    }
    
    private func requestTrackingPermission() {
        viewModel.requestTrackingPermission {
            viewModel.openNextScreen()
        }
    }
}
