//
//  Pretendard.swift
//  Cerchio
//
//  Created by 송재훈 on 9/27/25.
//

enum Pretendard: CustomFont {
    case thin
    case bold
    case extraBold
    case extraLight
    case light
    case medium
    case regular
    case semiBold
    case black
    
    var name: String {
        Self.identifier + "-" + description
    }
    
    private var description: String {
        switch self {
        case .thin: "Thin"
        case .bold: "Bold"
        case .extraBold: "ExtraBold"
        case .extraLight: "ExtraLight"
        case .light: "Light"
        case .medium: "Medium"
        case .regular: "Regular"
        case .semiBold: "SemiBold"
        case .black: "Black"
        }
    }
}
