//
//  Extension + ColorsSwiftUI.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 27.11.2024.
//

import SwiftUI

extension Color {
    // MARK: - Typography

    enum Typography {
        /// 25 25 25
        static let textBlack = color(white: 25)
        /// 250 250 250
        static let textWhite = color(white: 255)
        /// 51 51 51
        static let textDark = color(white: 51)
        /// 153 153 153
        static let textGray = color(white: 153)
        // 46 80 151 0.8
        static let ligtBlue = color(red: 46, green: 80, blue: 151, alpha: 0.8)
        /// 204 204 204
        static let textGhost = color(white: 204)
        /// 19 134 255
        static let textLink = color(red: 19, green: 134, blue: 255)
    }


    // MARK: - Background

    enum Background {
        /// 25 25 25
        static let dark = color(white: 25)
        /// 51 51 51
        static let darkSecondary = color(white: 51)
        /// 244 245 246
        static let secondary = color(red: 244, green: 245, blue: 246)
        /// 250 250 250
        static let light = color(white: 250)
        /// 237 250 255
        static let blue = color(red: 237, green: 250, blue: 255)
        /// 229 239 255
        static let blueLight = color(red: 229, green: 239, blue: 255)
        /// 235 240 255
        static let whiteBlue = color(red: 235, green: 240, blue: 255)
        /// 30 113 255
        static let darkBlue = color(red: 30, green: 113, blue: 255)
        /// 246 255 238
        static let green = color(red: 246, green: 255, blue: 238)
        /// 255 242 240
        static let red = color(red: 255, green: 242, blue: 240)
        /// 255 249 224
        static let yellow = color(red: 255, green: 249, blue: 224)
        /// 227 227 227
        static let shadow = color(white: 227)
        /// 249 250 251
        static let greyLight = color(red: 249, green: 250, blue: 251)
    }

    // MARK: - Borders

    enum Borders {
        /// 12 239 130
        static let green = color(red: 12, green: 239, blue: 130)
        /// 198 245 63
        static let lightGreen = color(red: 198, green: 245, blue: 63)
        /// 245 172 63
        static let orange = color(red: 245, green: 172, blue: 63)
        /// 245 63 63
        static let red = color(red: 245, green: 63, blue: 63)
        /// 204 204 204
        static let borderPrimary = color(white: 204)
        /// 229 229 229
        static let light = color(white: 229)
        /// 244 245 246
        static let extraLight = color(red: 244, green: 245, blue: 246)
    }

    // MARK: - Mono

    enum Mono {
        /// 0 0 0
        static let black100 = color(white: 0)
        /// 25 25 25
        static let black90 = color(white: 25)
        /// 51 51 51
        static let black80 = color(white: 51)
        /// 76 76 76
        static let black70 = color(white: 76)
        /// 102 102 102
        static let black60 = color(white: 102)
        /// 127 127 127
        static let black50 = color(white: 127)
        /// 153 153 153
        static let black40 = color(white: 153)
        /// 178 178 178
        static let black30 = color(white: 178)
        /// 204 204 204
        static let black20 = color(white: 204)
        /// 229 229 229
        static let black10 = color(white: 229)
        /// 242 242 242
        static let black5 = color(white: 242)
        /// 250 250 250
        static let black2 = color(white: 250)
        /// 252 252 252
        static let black1 = color(white: 252)
        /// 255 255 255
        static let white100 = color(white: 255)
    }

    // MARK: - Main

    enum Main {
        /// 19 134 255
        static let link = color(red: 19, green: 134, blue: 255)
        /// 255 69 59
        static let notify = color(red: 255, green: 69, blue: 59)
        /// 255 69 59
        static let red = color(red: 255, green: 69, blue: 59)
        /// 0 191 101
        static let green = color(red: 0, green: 191, blue: 101)
        /// 255 204 51
        static let yellow = color(red: 255, green: 204, blue: 51)
        /// 255 240 230
        static let orange = color(red: 255, green: 240, blue: 230)
        /// 255 255 255
        static let white = color(white: 255)
        /// 196 233 254
        static let blueLight = color(red: 196, green: 233, blue: 254)
        /// 210 247 183
        static let greenLight = color(red: 210, green: 247, blue: 183)
        /// 255 209 204
        static let redLight = color(red: 255, green: 209, blue: 204)
        /// 255 231 138
        static let yellowLight = color(red: 255, green: 231, blue: 138)
        /// 255 245 214
        static let fullPriceYellow = color(red: 255, green: 245, blue: 214)
        /// 235 75 61
        static let redNew = color(red: 235, green: 75, blue: 61)
        /// 19 134 255
        static let blue = color(red: 19, green: 134, blue: 255)
    }


    // MARK: - Gradients

    enum Gradients {
        // FIXME: Как пример
        /// 248 229 252 -> 249 222 207
        static let limitedAccess = [
            color(red: 248, green: 229, blue: 252),
            color(red: 249, green: 222, blue: 207)
        ]
        /// 255 128 56 -> 255 80 56
        static let proSubscriptionLogo = [
            color(red: 255, green: 128, blue: 56),
            color(red: 255, green: 80, blue: 56)
        ]
        /// 32 188 255 -> 32 110 255
        static let bestOfferLogo = [
            color(red: 32, green: 188, blue: 255),
            color(red: 32, green: 110, blue: 255)
        ]
    }

    // MARK: - Hex

    /// Конвертирует hex цвет в нативный UIColor
    /// - Parameter hex: Цвет в формате #****** или ******
    static func hexToColor(hex: String?, fallback: Color = .gray) -> Color {
        guard let hex else {
            return fallback
        }
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var alfa = 100

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if cString.count == 8 {
            alfa = Int(cString.prefix(2)) ?? 100
            cString = String(cString.dropFirst(2))
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        switch cString.count {
        case 3:
            return Color(
                red: Double((rgbValue & 0xF00) >> 8) / 15,
                green: Double((rgbValue & 0x0F0) >> 4) / 15,
                blue: Double(rgbValue & 0x00F) / 15,
                opacity: Double(alfa) / 100
            )
        case 6:
            return Color(
                red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgbValue & 0x0000FF) / 255.0,
                opacity: Double(alfa) / 100
            )
        default:
            return fallback
        }
    }

    // MARK: - Private

    private static func color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> Color {
        .init(red: red / 255, green: green / 255, blue: blue / 255, opacity: alpha)
    }

    private static func color(white: CGFloat, alpha: CGFloat = 1) -> Color {
        .init(red: white / 255, green: white / 255, blue: white / 255, opacity: alpha)
    }
}
