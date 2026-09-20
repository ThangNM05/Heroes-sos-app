//
//  View+Keyboard.swift
//  BaseProject
//
//  Created by Thang Nguyen Minh on 8/24/2026.
//  Copyright © 2026 Thang Nguyen Minh. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - UIApplication Extension for Hiding Keyboard
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Extension for Keyboard Dismissal
extension View {
    /// Hide keyboard directly from any view action
    func hideKeyboard() {
        UIApplication.shared.endEditing()
    }

    /// Dismiss keyboard when tapping anywhere outside input fields
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }

    /// Dismiss keyboard automatically when dragging/scrolling
    func dismissKeyboardOnDrag() -> some View {
        if #available(iOS 16.0, *) {
            return self.scrollDismissesKeyboard(.interactively)
        } else {
            return self.gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.endEditing()
                }
            )
        }
    }
}

// MARK: - KeyboardDismissModifier
struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.endEditing()
                }
            )
    }
}

extension View {
    /// Dismiss keyboard on both tap outside and drag/scroll
    func dismissKeyboardOnTapAndDrag() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}
