//
//  PaywallView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 05.12.2024.
//

import SwiftUI

struct PaywallView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: PaywallViewModel

    // MARK: - Init
    
    init(viewModel: PaywallViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            Image("picstar")
                .resizable()
                .scaledToFit()
                .frame(width: .screenWidth)
                .clipped()

            VStack {
                makeHeaderView()
                
                Spacer(minLength: .zero)
                
                makeButtonsView()
                                
                makeInfoView()
            }
        }.background(Color.hexToColor(hex: "#EBF0FF"))
    }
    
    // MARK: - Header View
    
    @ViewBuilder private func makeHeaderView() -> some View {
        VStack(spacing: 6) {
            Text("Free Trial Enabled")
                .font(.system(size: 40, weight: .semibold))

            Text("Storage")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
                .padding(vertical: 1, horizontal: 10)
                .background(Color.blue)
                .cornerRadius(12)
        }.padding(top: 40)
     
        LottieView(
            name: "paywall",
            contentMode: .scaleAspectFit,
            isActive: true,
            loopMode: .loop
        ).frame(width: .screenWidth - 140, height: .screenWidth - 140)
    }
    
    // MARK: - Buttons View
    
    @ViewBuilder private func makeButtonsView() -> some View {
        // Buttons
        
        VStack(spacing: 12) {
            if !viewModel.isPassTrail {
                // ONE
                HStack(spacing: .zero) {
                    
                    Text("Free Trial Enabled")
                        .textStyle(.semibold)
                    
                    Spacer(minLength: .zero)
                    
                    Toggle("", isOn: $viewModel.isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                        .labelsHidden()
                }
                .padding(vertical: 9, horizontal: 20)
                .background(Color.white)
                .cornerRadius(14)
                
                Spacer(minLength: .zero)
            }

            // TWO
            HStack(spacing: .zero) {
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yearly Access")
                        .textStyle(.textBold, textColor: .Typography.textGray)
                    
                    Text("$39.99/year")
                        .textStyle(.textBold)
                }
                
                Spacer(minLength: .zero)
                
                VStack(spacing: 2) {
                    Text("BEST OFFER")
                        .textStyle(
                            .semibold,
                            textColor: !viewModel.isSelectWeekPlan ? .Typography.textWhite : .Typography.textBlack
                        )
                        .padding(vertical: 3, horizontal: 10)
                        .background(
                            !viewModel.isSelectWeekPlan ?
                            AnyView(
                                LinearGradient(
                                    gradient: Gradient(colors: Color.Gradients.bestOfferLogo),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ) :
                            AnyView(
                                Color.hexToColor(hex: "#A3C3FF")
                            )
                        )
                        .cornerRadius(30)

                    Text("$0.77/week")
                        .textStyle(.textBold, textColor: .Typography.textGray)
                }
            }
            .padding(vertical: 9, horizontal: 20)
            .background(
                !viewModel.isSelectWeekPlan ?
                AnyView(
                    Color.hexToColor(hex: "#EBF0FF")
                ) :
                AnyView(
                    Color.white
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        !viewModel.isSelectWeekPlan ? Color.Background.darkBlue : Color.white,
                        lineWidth: 2 // Укажите желаемую толщину линии
                    )
            )
            .cornerRadius(14)
            .asButton(style: .scale(.light), action: viewModel.didTapMonthPlan)
            
            // THREE
            HStack(spacing: .zero) {
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("3-DAY FREE TRIAL")
                        .textStyle(.textBold, textColor: .Typography.textGray)
                    
                    Text("then $6.99/week")
                        .textStyle(.textBold)
                }
                
                Spacer(minLength: .zero)
                
                VStack(spacing: 2) {
                    Text("3 DAYS FREE")
                        .textStyle(
                            .semibold,
                            textColor: viewModel.isSelectWeekPlan ? .Typography.textWhite : .Typography.textBlack
                        )
                        .padding(vertical: 3, horizontal: 10)
                        .background(
                            viewModel.isSelectWeekPlan ?
                            AnyView(
                                LinearGradient(
                                    gradient: Gradient(colors: Color.Gradients.bestOfferLogo),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            ) :
                            AnyView(
                                Color.hexToColor(hex: "#A3C3FF")
                            )
                        )
                        .cornerRadius(30)
                }
            }
            .padding(vertical: 9, horizontal: 20)
            .background(
                viewModel.isSelectWeekPlan ?
                AnyView(
                    Color.hexToColor(hex: "#EBF0FF")
                ) :
                AnyView(
                    Color.white
                )
            )

            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        viewModel.isSelectWeekPlan ? Color.Background.darkBlue : Color.white,
                        lineWidth: 2
                    )
            )
            .asButton(style: .scale(.light), action: viewModel.didTapWeekPlan)


        }
        .padding(bottom: 12, horizontal: 22)
    }

    // MARK: - Info View
    
    @ViewBuilder private func makeInfoView() -> some View {
        HStack(spacing: 4) {
            Image("blueShield")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .clipped()

            Text("No Payment Now")
                .textStyle(.semibold)
        }.padding(bottom: 13)
        
        Text("Continue")
            .textStyle(.onboardingTitle, textColor: .Typography.textWhite)
            .frame(width: .screenWidth - 40, height: 80)
            .background(Color.blue)
            .cornerRadius(55)
            .padding(bottom: 13)
            .asButton(style: .scale(.light), action: viewModel.didTapContinue)

        HStack(spacing: 32) {
            Text("Restore")
                .textStyle(.smallText, textColor: .Typography.textGray)

            Text("Terms of Use")
                .textStyle(.smallText, textColor: .Typography.textGray)
            
            Text("Privacy Policy")
                .textStyle(.smallText, textColor: .Typography.textGray)
        }
        
        
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(
            viewModel: PaywallViewModel(
                service: PaywallService(),
                router: PaywallRouter()
            )
        )
    }
}
