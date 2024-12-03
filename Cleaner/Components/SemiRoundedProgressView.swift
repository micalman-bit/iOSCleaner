//
//  SemiRoundedProgressView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 29.11.2024.
//

import SwiftUI

struct SemiRoundedProgressView: View {
    var progress: CGFloat // Значение от 0 до 1
    var totalSize: CGFloat = 200 // Размер компонента
    var lineWidth: CGFloat = 15 // Толщина линии
    var gap: CGFloat = 0.12 // Пробел сверху (0.1 = 10% круга)
    var freeSpaceText: String // Текст для отображения памяти
    var totalSpaceText: String // Текст для отображения памяти
    var smileText: String
    var progressLineColor: Color
    
    var body: some View {
        ZStack {
            // Фон круга с пробелом
            Circle()
                .trim(from: gap / 2, to: 1 - gap / 2)
                .stroke(
                    Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: totalSize, height: totalSize)
            
            // Индикатор прогресса с пробелом
            Circle()
                .trim(from: gap / 2, to: progress * (1 - gap) + gap / 2)
                .stroke(
                    progressLineColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: totalSize, height: totalSize)
            
            // Текст внутри круга
            VStack(spacing: .zero) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 68, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: .zero) {
                    Text("\(freeSpaceText) GB")
                        .textStyle(.price, textColor: .Typography.textBlack)

                    Text("/ \(totalSpaceText) GB")
                        .textStyle(.price, textColor: .Typography.textGray)
                }.padding(top: 2)
                
                Text("available")
                    .textStyle(.price, textColor: .Typography.textGray)
            }
            
            // Текст "F" внутри пробела сверху
            Text(smileText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(9)
                .background(Color.white)
                .cornerRadius(20)
                .position(
                    x: totalSize / 2,
                    y: lineWidth / 2
                )
        }
    }
}
