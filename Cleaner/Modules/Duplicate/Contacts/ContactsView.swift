//
//  ContactsView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import SwiftUI

struct ContactsView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: ContactsViewModel
    
    // MARK: - Init
    
    init(viewModel: ContactsViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .zero) {
            makeHeaderView()
         
            switch viewModel.screenState {
            case .loading:
                makeLoaderView()
                
            case .content, .allClean:
                makeContentView()
                    .padding(horizontal: 20)
                    .background(Color.hexToColor(hex: "#F4F7FA"))
                
                makeButtonView()

//            case .allClean:
//                VStack {
//                    Spacer(minLength: .zero)
//                    
//                    makeAllCleanView()
//                        .background(Color.hexToColor(hex: "#F4F7FA"))
//                    
//                    Spacer(minLength: .zero)
//                    
//                    makeBackButtonView()
//                }.background(Color.hexToColor(hex: "#F4F7FA"))
            }
            
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // MARK: - Header View
    
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
                    .frame(width: 40, alignment: .center)
                    .font(.system(size: 17))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .asButton(style: .opacity, action: viewModel.dismiss)
            
            Text("Contacts")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 80, alignment: .center)
                .padding(leading: 90)

            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if viewModel.screenState == .content {
                Text(viewModel.isEnabledSeselectAll ? "Deselect All" : "Seselect All")
                    .foregroundColor(viewModel.isEnabledSeselectAll ? .gray : .blue)
                    .frame(width: 90, alignment: .center)
                    .font(.system(size: 15))
                    .asButton(style: .opacity, action: viewModel.setSelectToAllItems)
            } else {
                Spacer(minLength: .zero)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.white)
    }

    // MARK: - Content View
    
    @ViewBuilder private func makeContentView() -> some View {
        ScrollView(showsIndicators: false) {
            
            VStack(alignment: .leading) {
                
                makeTopView()
                
                ForEach(viewModel.duplicates) { item in
                    makeListDuplicatesView(item)
                        .padding(top: 24)
                }
                
            }.padding(top: 20, horizontal: 20)

        }
        .frame(width: .screenWidth)
    }
    
    // MARK: - List Duplicates
    
    @ViewBuilder private func makeListDuplicatesView(_ duplicates:  ContactDuplicateGroup) -> some View {
        VStack(alignment: .leading) {
            
            Text("Merged Contact")
                .textStyle(.h1)
            
            if let duplicate = duplicates.contacts.first {
                makeContactsItemView(isShowCheck: false, item: duplicate)
            }
            
            HStack {
                Text("Duplicates will be removed")
                    .textStyle(.h1, textColor: .Typography.textGray)
                
                Spacer(minLength: .zero)
                
                Text(duplicates.isSelect ? "Deselect All" : "Seselect All")
                    .textStyle(
                        .textBold,
                        textColor: duplicates.isSelect ? .gray : .Typography.textLink
                    )
                    .asButton(style: .opacity, action: { viewModel.setDeselectToItems(duplicates.contacts) })
                
            }.padding(top: 12)
            
            ForEach(duplicates.contacts.dropFirst()) { item in
                makeContactsItemView(item: item)
            }
        }
    }
    
    // MARK: - Contacts Item

    @ViewBuilder private func makeContactsItemView(isShowCheck: Bool = true, item: ContactDuplicateItem) -> some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading) {
                Text(item.name)
                    .textStyle(.h1)
                
                Text(item.number)
                    .textStyle(.text, textColor: .Typography.textGray)
            }
            
            Spacer(minLength: .zero)
            
            if isShowCheck {
                Image(item.isSelect ? "circleCheck" : "circleGray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .asButton(style: .opacity, action: { viewModel.setSelectToItem(item) })
            }
        }
        .padding(vertical: 22.5, horizontal: 20)
        .background(Color.white)
        .cornerRadius(14)
        .padding(top: 16)
    }

    
    // MARK: - Top View
    
    @ViewBuilder private func makeTopView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Duplicate Contacts")
                .font(.system(size: 32, weight: .semibold))
            
            Text(viewModel.duplicateCount)
                .textStyle(.price, textColor: .Typography.textGray)
        }
    }

    
    // MARK: - Button View

    @ViewBuilder private func makeButtonView() -> some View {
        VStack(alignment: .center) {
            Text(viewModel.groupCount)
                .foregroundColor(.white)
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .padding(vertical: 20, horizontal: 52)
                .frame(width: .screenWidth - 20)
                .background(viewModel.isEnabledButton ? Color.blue : Color.hexToColor(hex: "#A8A8A8"))
                .cornerRadius(55)
                .disabled(!viewModel.isEnabledButton)
                .padding(top: 12)
            
            Spacer(minLength: .zero)
        }
        .background(Color.white)
//        .padding(vertical: 12, horizontal: 20)
        .frame(maxWidth: .screenWidth, maxHeight: 118)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .asButton(style: .scale(.light), action: viewModel.mergeContacts)

        
        Spacer(minLength: .zero)
    }

    // MARK: - Loader View
    
    @ViewBuilder private func makeLoaderView() -> some View {
        VStack(spacing: .zero) {
            ZStack {
                LottieView(name: "loaderClenaer ", isActive: true, loopMode: .loop)
                    .frame(width: 300, height: 300)
                    .padding(top: 110)
                
                VStack(spacing: .zero) {
                    Text(viewModel.progressLoading)
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundColor(.Typography.textDark)
                    
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
    
    // MARK: - All Clean

    @ViewBuilder private func makeAllCleanView() -> some View {
        VStack(spacing: 50) {
            Image("allClean")
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 177)
                .foregroundColor(.blue)

            VStack(alignment: .center, spacing: 10) {
                Text("Everything is well-\norganized!")
                    .foregroundColor(.Typography.textDark)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text("No unnecessary files here. Your device is well-organized and optimized in this area.")
                    .foregroundColor(.Typography.textGray)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
            }.frame(width: 316)
            

        }
    }

    // MARK: - Back Button

    @ViewBuilder private func makeBackButtonView() -> some View {
        VStack(alignment: .center) {
            Text("BACK TO HOME")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .padding(vertical: 20, horizontal: 52)
                .frame(width: .screenWidth - 20)
                .background(Color.blue)
                .cornerRadius(55)
                .padding(top: 12)
            
            Spacer(minLength: .zero)
        }
        .frame(maxWidth: .screenWidth, maxHeight: 118)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .asButton(style: .scale(.light), action: viewModel.dismiss)
    }
}

struct ContactsViewView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView(
            viewModel: ContactsViewModel(
                service: ContactsService(),
                router: ContactsRouter()
            )
        )
    }
}
