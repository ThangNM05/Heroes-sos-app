//
//  Theme.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import UIKit
import SwiftUI

enum Theme {
    // MARK: - Colors (HEROS Brand Palette)
    enum Colors {
        // HEROS Primary Brand (Tông hồng Magenta Rose chuẩn theo Logo)
        static let primary = "#FF4D88".toUIColor()
        static let primaryColor = "#FF4D88".toColor
        static let primaryDark = "#E11D62".toUIColor()
        static let primaryDarkColor = "#E11D62".toColor
        static let brandPink = "#FF2D6C".toColor
        static let brandRose = "#FA709A".toColor
        
        static let secondary = "#7E798E".toUIColor()
        static let secondaryColor = "#7E798E".toColor
        
        static let textPrimary = "#1E1B2E".toUIColor()
        static let textPrimaryColor = "#1E1B2E".toColor
        
        static let textSecondary = "#7E798E".toUIColor()
        static let textSecondaryColor = "#7E798E".toColor
        
        static let textBlack = "#1E1B2E".toUIColor()
        static let textGray = "#8E8A9F".toUIColor()
        static let textWhite = "#FFFFFF".toUIColor()
        
        // Backgrounds
        static let bgColor = "#FFF5F8".toUIColor()
        static let bgColor2 = "#FFFFFF".toUIColor()
        static let surfaceColor = "#FFFFFF".toUIColor()
        static let cardBg = "#FFFFFF".toColor
        static let softPink = "#FFF0F5".toColor
        
        // Status & Functional Colors
        static let red = "#E11D48".toUIColor()        // SOS Emergency Red
        static let redColor = "#E11D48".toColor
        static let amber = "#F59E0B".toUIColor()      // Recording Gold
        static let amberColor = "#F59E0B".toColor
        static let green = "#10B981".toUIColor()      // Responding Safety Green
        static let greenColor = "#10B981".toColor
        static let blue = "#0284C7".toUIColor()       // Auto-call Fallback Blue
        static let blueColor = "#0284C7".toColor
        
        static let background = "#FFF5F8".toUIColor()
        
        // Gradients
        static let heroGradient = LinearGradient(
            colors: ["#FA709A".toColor, "#FF2D6C".toColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let sosGradient = LinearGradient(
            colors: ["#FF4D88".toColor, "#E11D48".toColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Fonts
    enum Fonts: String {
        case regular = "Inter-Regular"
        case bold = "Inter-Bold"
        case extraBold = "Inter-ExtraBold"
        case semiBold = "Inter-SemiBold"
        case medium = "Inter-Medium"

        func with(_ size: CGFloat) -> UIFont {
            return UIFont(name: rawValue, size: size) ?? .systemFont(ofSize: size)
        }

        func swiftUI(size: CGFloat) -> Font {
            return .custom(rawValue, size: size)
        }
    }
}
