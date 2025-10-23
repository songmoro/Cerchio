//
//  ImageEffectProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit

protocol ImageEffectProtocol {
    func apply(to image: UIImage) -> UIImage?
}

struct BlurImageEffect: ImageEffectProtocol {
    let intensity: CGFloat

    func apply(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(intensity * 20, forKey: kCIInputRadiusKey)

        guard let outputImage = blurFilter?.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

struct BrightnessImageEffect: ImageEffectProtocol {
    let brightness: CGFloat

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
