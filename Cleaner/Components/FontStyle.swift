//
//  FontStyle.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

public enum FontStyle {
    /// 60, bold
    case priceDynamic

    /// 22, semibold
    case onboardingTitle

    /// 24, semibold
    case hero

    /// 20, semibold
    case textBig

    /// 18, semibold
    case h1
    
    /// 16, semibold
    case h2
    
    /// 16, regular
    case price
    
    /// 15, regular
    case flatCount
    
    /// 14, semibold
    case textBold
    
    /// 14, regular
    case text
    
    /// 13, semibold
    case semibold
    
    /// 13, regular
    case tableText
    
    /// 12, regular
    case smallText
    
    /// 11, regular
    case badgeText
    
    /// 10, semibold
    case tabbar
    
    /// 10, regular
    case smallerText
    
    /// 9, regular
    case mapSmallText
    
    var spacing: Double {
        switch self {
        case .smallText,
                .badgeText,
                .smallerText,
                .mapSmallText:
            return -0.25
        default:
            return -0.05
        }
    }
    
    var fontSwiftUI: Font {
        switch self {
        case .hero: return .system(size: 24, weight: .semibold)
        case .onboardingTitle: return .system(size: 22, weight: .semibold)
        case .textBig: return .system(size: 20, weight: .semibold)
        case .h1: return .system(size: 18, weight: .semibold)
        case .h2: return .system(size: 16, weight: .semibold)
        case .textBold: return .system(size: 14, weight: .semibold)
        case .text: return .system(size: 14, weight: .regular)
        case .smallText: return .system(size: 12, weight: .regular)
        case .mapSmallText: return .system(size: 8, weight: .regular)
        case .price: return .system(size: 16, weight: .regular)
        case .tabbar: return .system(size: 10, weight: .semibold)
        case .semibold: return .system(size: 13, weight: .semibold)
        case .smallerText: return .system(size: 10, weight: .regular)
        case .tableText: return .system(size: 13, weight: .regular)
        case .badgeText: return .system(size: 11, weight: .regular)
        case .priceDynamic: return .system(size: 60, weight: .bold)
        case .flatCount: return .system(size: 15, weight: .regular)
        }
    }
    
    var lineHeight: CGFloat {
        return 1.2
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .priceDynamic:
            return 6
        case .hero:
            return 5
        case .h1,
                .textBig,
                .h2,
                .price:
            return 4
        case .text,
                .textBold,
                .flatCount:
            return 2.5
        case .semibold,
                .onboardingTitle,
                .tableText,
                .smallText,
                .badgeText,
                .tabbar,
                .smallerText,
                .mapSmallText:
            return 1.2
        }
    }
    
    var weightSwiftUI: Font.Weight {
        switch self {
        case .hero,
                .onboardingTitle,
                .textBig,
                .h1,
                .h2,
                .textBold,
                .tabbar,
                .semibold:
            return .semibold
        case .text,
                .smallText,
                .mapSmallText,
                .price,
                .smallerText,
                .tableText,
                .badgeText,
                .flatCount:
            return .regular
        case .priceDynamic:
            return .bold
        }
    }
    
    func fontTemplate(color: Color) -> FontTemplate {
        .init(
            font: fontSwiftUI,
            weight: weightSwiftUI,
            foregroundColor: color,
            lineSpacing: lineSpacing
        )
    }
}
