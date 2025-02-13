//
//  OnboardingView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 04.12.2024.
//

import SwiftUI

struct OnboardingView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: OnboardingViewModel

    @State private var currentPage = 0
    private let totalPages = 4

    // MARK: - Init
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer(minLength: .zero)
            
            TabView(selection: $currentPage) {
                ForEach(0..<totalPages, id: \.self) { index in
                    OnboardingSlide(
                        index: index,
                        isActive: currentPage == index, // Включение анимации только для текущего слайда
                        buttonAction: nextSlide
                    ).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 32) {
                        Text("Terms of Use")
                            .textStyle(.smallText, textColor: .Typography.textGray)
                            .asButton(style: .opacity, action: viewModel.didTapTermsOfUse)
                        
                        Text("Privacy Policy")
                            .textStyle(.smallText, textColor: .Typography.textGray)
                            .asButton(style: .opacity, action: viewModel.didTapPrivacyPolicy)
                    }
                    .opacity(currentPage == 0 ? 1 : 0)
                    .animation(.easeInOut, value: currentPage)

                    PageIndicator(totalPages: totalPages, currentPage: currentPage)
                        .opacity(currentPage == 0 ? 0 : 1)
                        .animation(.easeInOut, value: currentPage)
                }
                .frame(height: 18)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: .screenWidth)
            .background(Color.white)
        }
        .sheet(item: $viewModel.selectedURL) { url in
            WebView(url: url)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.hexToColor(hex: "#EBF0FF"))
        .animation(.easeInOut, value: currentPage)
    }
    
    private func nextSlide() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            viewModel.openPaywall()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            viewModel: OnboardingViewModel(
                service: OnboardingService(),
                router: OnboardingRouter()
            )
        )
    }
}
