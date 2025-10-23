//
//  DominantColorExtractor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import UIKit

class DominantColorExtractor {

    static func extract(from image: UIImage, count: Int = 1) -> [UIColor] {
        guard let smallImage = resize(image, to: CGSize(width: 100, height: 100)),
              let cgImage = smallImage.cgImage else {
            return [.gray]
        }

        guard let pixelData = getPixelData(from: cgImage) else {
            return [.gray]
        }

        let colorCounts = countColors(
            pixelData: pixelData,
            width: cgImage.width,
            height: cgImage.height
        )

        let topColors = colorCounts
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { UIColor(hex: $0.key) }

        return topColors.isEmpty ? [.gray] : topColors
    }

    private static func resize(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func getPixelData(from cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelData
    }

    private static func countColors(pixelData: [UInt8], width: Int, height: Int) -> [String: Int] {
        var counts: [String: Int] = [:]
        let sampleRate = 5

        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let offset = (y * width + x) * 4

                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0

                guard a > 0.5 else { continue }

                let brightness = (r + g + b) / 3.0
                guard brightness > 0.1 && brightness < 0.95 else { continue }

                let colorKey = quantize(r: r, g: g, b: b)
                counts[colorKey, default: 0] += 1
            }
        }

        return counts
    }

    private static func quantize(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
        let levels = 8
        let rQ = Int(r * CGFloat(levels)) * (256 / levels)
        let gQ = Int(g * CGFloat(levels)) * (256 / levels)
        let bQ = Int(b * CGFloat(levels)) * (256 / levels)
        return "\(rQ)-\(gQ)-\(bQ)"
    }
}

extension UIColor {
    convenience init(hex: String) {
        let components = hex.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else {
            self.init(white: 0.5, alpha: 1.0)
            return
        }

        self.init(
            red: CGFloat(components[0]) / 255.0,
            green: CGFloat(components[1]) / 255.0,
            blue: CGFloat(components[2]) / 255.0,
            alpha: 1.0
        )
    }
}

