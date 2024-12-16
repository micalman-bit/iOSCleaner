//
//  SettingView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 09.12.2024.
//

import SwiftUI

struct SettingView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: SettingViewModel
    
    
    // MARK: - Init
    
    init(viewModel: SettingViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .zero) {
            makeHeaderView()
         
            makeContentView()
                .padding(horizontal: 20)
                .background(Color.hexToColor(hex: "#F4F7FA"))
            
            Spacer(minLength: .zero)
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
            
            Text("Setting")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.white)
    }

    @ViewBuilder private func makeContentView() -> some View {
        ScrollView(showsIndicators: false) {
            // TODO: - ЛОГИКА ЕСТЬ ЛИ ПОДПИСКА
            switch true {
            case true:
                ZStack {
                    Image("bgPremActive")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)
                    
                    HStack(spacing: .zero) {
                        Text("Premium")
                            .textStyle(.textBig, textColor: .Typography.textWhite)
                        
                        Spacer(minLength: .zero)
                        
                        HStack(spacing: 2) {
                            Image("crown")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            
                            Text("Activated")
                                .textStyle(.textBold, textColor: .Typography.textWhite)
                        }
                        .padding(vertical: 6, horizontal: 12)
                        .background(Color.blue)
                        .cornerRadius(20)
                    }
                    .padding(vertical: 18, horizontal: 20)
                }
                .frame(width: .screenWidth - 40, height: 60)
                .padding(top: 24, horizontal: 20)
            case false:
                ZStack {
                    Image("bgPrem")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.blue)

                    HStack(spacing: .zero) {
                        VStack(alignment: .leading, spacing: .zero) {
                            Text("Try Clean Up Premium")
                                .textStyle(.textBig, textColor: .Typography.textWhite)
                            
                            Text("Tap to claim your offer now!")
                                .textStyle(.flatCount, textColor: .Typography.textWhite)
                        }
                        
                        Spacer(minLength: .zero)
                        
                        Image("premiumSubSettings")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 62, height: 62)
                        
                    }
                    .padding(vertical: 18, horizontal: 20)
                }
                .frame(width: .screenWidth - 40, height: 90)
                .padding(top: 24, horizontal: 20)
                    
            }
            
            ForEach(viewModel.listOfItems) { item in
                HStack(spacing: .zero) {
                    Text(item.title)
                        .textStyle(.h1)
                    
                    Spacer(minLength: .zero)
                    
                    Image("arrow-right-s-line")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .padding(vertical: 22.5, horizontal: 20)
                .background(Color.white)
                .cornerRadius(14)
                .padding(top: 16)
            }.padding(horizontal: 20)
            
            Spacer(minLength: .zero)
                .frame(width: .screenWidth)
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView(
            viewModel: SettingViewModel(
                service: SettingService(),
                router: SettingRouter()
            )
        )
    }
}
