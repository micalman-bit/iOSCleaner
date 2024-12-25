//
//  OnboardingSlide.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import SwiftUI

struct OnboardingSlide: View {
    let index: Int
    let isActive: Bool
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: .zero) {
            
            ZStack {
                LottieView(name: lottieFileForIndex(index), isActive: isActive)
                    .frame(width: .screenWidth, height: .screenHeight)
                
               
                VStack {
                    // Заголовок
                    Spacer(minLength: .zero)
                    
                    Text(titleForIndex(index))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(bottom: 26)
                    
                    Text(index == 0 ? "GET STARTED" : "Next")
                        .textStyle(.textBig, textColor: .Typography.textWhite)
                        .frame(width: .screenWidth - 40, height: 80)
                        .background(Color.blue)
                        .cornerRadius(55)
                        .padding(bottom: 12)
                        .asButton(style: .scale(.light), action: buttonAction)
                    
                }.padding(bottom: 55)
            }
        }
    }
    
    private func titleForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "Control Your\nDevice Instantly"
        case 1: return "Sort Duplicates\nQuickly"
        case 2: return "Organize Your\nContacts"
        case 3: return "Get Rid of Old\nEvents"
        default: return ""
        }
    }
    
    private func lottieFileForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "cleaner1" // Имя JSON файла
        case 1: return "cleaner2"
        case 2: return "cleaner3"
        case 3: return "cleaner4"
        default: return ""
        }
    }
}
