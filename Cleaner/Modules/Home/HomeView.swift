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

    // MARK: - Init

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack {
            makeHeaderView()
                                    
            makeContentView()
            
            makeButtonListView()
        }
        .background(Color.white)
    }
    
    // MARK: - ViewBuilder
    
    @ViewBuilder private func makeHeaderView() -> some View {
        // Circle Progress Section
        VStack(spacing: .zero) {
            Text("iPhone 14 Pro")
                .font(.system(size: 24, weight: .bold))
            Text("iOS 18.0")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
    }
    
    
    @ViewBuilder private func makeContentView() -> some View {
        VStack(spacing: .zero) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: 0.5) // 50%
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Image(systemName: "face.smiling") // Emoji in the center
                        .font(.system(size: 32))
                        .padding(.bottom, 10)
                    Text("50%")
                        .font(.system(size: 32, weight: .bold))
                    Text("23.2 GB / 128 GB available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 180, height: 180)
            
            Spacer().frame(height: 20)
            
            // Smart Clean Button
            Button(action: {
                // Smart clean action
            }) {
                Text("SMART CLEAN NOW")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    
    @ViewBuilder private func makeButtonListView() -> some View {
        // Bottom List Section
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "photo")
                Text("Photo & Video")
                    .font(.system(size: 16))
                Spacer()
                Text("1.8 GB")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            HStack {
                Image(systemName: "person.crop.circle")
                Text("Contact")
                    .font(.system(size: 16))
                Spacer()
                Text("44")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            HStack {
                Image(systemName: "calendar")
                Text("Calendar")
                    .font(.system(size: 16))
                Spacer()
                Text("Need access, click to allow")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
            .padding(.horizontal)
        }
        
        Spacer()
    }
}

struct CleanerView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(
                service: HomeService(),
                router: HomeRouter()
            )
        )
    }
}
