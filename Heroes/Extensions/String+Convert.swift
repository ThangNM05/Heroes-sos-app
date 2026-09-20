//
//  String+Convert.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

extension String {
    
    func toUIColor(alpha: Double = 1.0) -> UIColor {
        if let color = UIColor(named: self) {
            return color.withAlphaComponent(CGFloat(alpha))
        }
        
        var hexWithoutSymbol: String = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexWithoutSymbol.hasPrefix("#") {
            hexWithoutSymbol = String(hexWithoutSymbol.dropFirst())
        }
        
        let scanner = Scanner(string: hexWithoutSymbol)
        var hexInt: UInt64 = 0
        guard scanner.scanHexInt64(&hexInt) else {
            return UIColor.clear
        }
        
        let r, g, b, a: CGFloat
        switch hexWithoutSymbol.count {
        case 3: // RGB (12-bit)
            r = CGFloat((hexInt >> 8) * 17) / 255.0
            g = CGFloat((hexInt >> 4 & 0xF) * 17) / 255.0
            b = CGFloat((hexInt & 0xF) * 17) / 255.0
            a = CGFloat(alpha)
        case 6: // RGB (24-bit)
            r = CGFloat((hexInt & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexInt & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexInt & 0x0000FF) / 255.0
            a = CGFloat(alpha)
        case 8: // ARGB (32-bit)
            a = CGFloat((hexInt & 0xFF000000) >> 24) / 255.0
            r = CGFloat((hexInt & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((hexInt & 0x0000FF00) >> 8) / 255.0
            b = CGFloat(hexInt & 0x000000FF) / 255.0
        default:
            return UIColor.clear
        }
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    var toColor: Color {
        return Color(self.toUIColor())
    }

    func toUIFont(size: CGFloat = 14, weight: UIFont.Weight = .regular) -> UIFont {
        if let font = UIFont(name: self, size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: weight)
    }

    func toFont(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
        return .custom(self, size: size).weight(weight)
    }

    var toInt: Int? {
        return Int(self)
    }

    var toFloat: Float? {
        return Float(self)
    }

    var toDouble: Double? {
        return Double(self)
    }
}
