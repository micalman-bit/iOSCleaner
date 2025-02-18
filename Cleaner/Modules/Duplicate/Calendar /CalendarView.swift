//
//  CalendarView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 26.01.2025.
//

import SwiftUI

struct CalendarView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: CalendarViewModel
    
    // MARK: - Init
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: .zero) {
            makeHeaderView()
         
            switch viewModel.screenState {
            case .loading:
                makeLoaderView()
                
            case .content:
                makeContentView()
                    .padding(horizontal: 20)
                    .background(Color.hexToColor(hex: "#F4F7FA"))
                
                makeButtonView()

            case .allClean:
                VStack {
                    Spacer(minLength: .zero)
                    
                    makeAllCleanView()
                        .background(Color.hexToColor(hex: "#F4F7FA"))
                    
                    Spacer(minLength: .zero)
                    
                    makeBackButtonView()
                }.background(Color.hexToColor(hex: "#F4F7FA"))
            }
            
        }
        .alert(isPresented: $viewModel.isShowDeleteAlert) {
            Alert(
                title: Text(viewModel.titleDeleteAlert),
                message: Text(viewModel.messageDeleteAlert),
                primaryButton: .destructive(Text("Delete")) { viewModel.mergeContacts() },
                secondaryButton: .cancel()
            )
        }
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
            
            Text("Calendar")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 80, alignment: .center)
                .padding(leading: 90)

            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            if viewModel.screenState == .content {
                Text("Seselect All")
                    .foregroundColor(.blue)
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
                
                ForEach(viewModel.events) { item in
                    makeListDuplicatesView(item)
                        .padding(top: 24)
                }
                
            }
            .padding(top: 20, horizontal: 20)

        }
        .frame(width: .screenWidth)
    }
    
    // MARK: - List Duplicates
    
    @ViewBuilder private func makeListDuplicatesView(_ duplicates: EventsGroup) -> some View {
        VStack(alignment: .leading) {
                        
            HStack {
                Text(duplicates.monthTitle)
                    .textStyle(.h1, textColor: .Typography.textGray)
                
                Spacer(minLength: .zero)
                
                Text("Deselect All")
                    .textStyle(.textBold, textColor: .Typography.textLink)
                    .asButton(style: .opacity, action: { viewModel.setDeselectToItems(duplicates) })
                
            }.padding(top: 12)
            
            ForEach(duplicates.events) { item in
                makeContactsItemView(item: item)
            }
            
        }.padding(top: 20)
    }
    
    // MARK: - Contacts Item

    @ViewBuilder private func makeContactsItemView(isShowCheck: Bool = true, item: CalendarEventItem) -> some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading) {
                Text(item.title)
                    .textStyle(.h1)
                
                Text(item.startDate.toLongDateString())
                    .textStyle(.text, textColor: .Typography.textGray)
            }
            
            Spacer(minLength: .zero)
            
            if isShowCheck {
                Image(item.isSelected ? "circleCheck" : "circleGray")
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
            Text("Calendar")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.Typography.textDark)
            
            Text(viewModel.duplicateCount)
                .textStyle(.price, textColor: .Typography.textGray)
        }
    }

    
    // MARK: - Button View

    @ViewBuilder private func makeButtonView() -> some View {
        VStack(alignment: .center) {
            Text(viewModel.groupCount)
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .padding(vertical: 20, horizontal: 52)
                .frame(width: .screenWidth - 20)
                .background(viewModel.isEnabledButton ? Color.blue : Color.hexToColor(hex: "#A8A8A8"))
                .cornerRadius(55)
        }
        .background(Color.white)
        .padding(vertical: 12, horizontal: 20)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .asButton(style: .scale(.light), action: {
            guard viewModel.isEnabledButton else { return }
            viewModel.isShowDeleteAlert.toggle()
        })

        
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
                    Text("0%")
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
        }
        .background(Color.white)
        .padding(vertical: 12, horizontal: 20)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .asButton(style: .scale(.light), action: viewModel.dismiss)
    }
}

//struct ContactsViewView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContactsView(
//            viewModel: ContactsViewModel(
//                service: ContactsService(),
//                router: ContactsRouter()
//            )
//        )
//    }
//}

import Foundation

extension Date {
    func toLongDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }
}
