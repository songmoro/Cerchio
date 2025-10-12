//
//  ImageEffectProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit

/// Protocol for image effects that can be applied to quote share backgrounds
protocol ImageEffectProtocol {
    /// Apply effect to an image
    func apply(to image: UIImage) -> UIImage?
}

/// Blur effect for images
struct BlurImageEffect: ImageEffectProtocol {
    let intensity: CGFloat

    func apply(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(intensity * 20, forKey: kCIInputRadiusKey) // 0-20 radius

        guard let outputImage = blurFilter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

/// Brightness adjustment effect
struct BrightnessImageEffect: ImageEffectProtocol {
    let brightness: CGFloat // -1.0 to 1.0

    func apply(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
