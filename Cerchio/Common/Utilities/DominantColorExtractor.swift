//
//  DominantColorExtractor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import UIKit

/// 이미지에서 가장 빈번하게 사용되는 색상을 추출하는 유틸리티
class DominantColorExtractor {

    /// 이미지에서 가장 많이 사용된 색상 추출
    /// - Parameters:
    ///   - image: 분석할 이미지
    ///   - count: 추출할 색상 개수 (기본: 1)
    /// - Returns: 추출된 색상 배열 (빈도순)
    static func extract(from image: UIImage, count: Int = 1) -> [UIColor] {
        // 1. 이미지 리사이즈 (성능 최적화)
        guard let smallImage = resize(image, to: CGSize(width: 100, height: 100)),
              let cgImage = smallImage.cgImage else {
            return [.gray] // 실패시 기본 색상
        }

        // 2. 픽셀 데이터 가져오기
        guard let pixelData = getPixelData(from: cgImage) else {
            return [.gray]
        }

        // 3. 색상 빈도수 계산
        let colorCounts = countColors(
            pixelData: pixelData,
            width: cgImage.width,
            height: cgImage.height
        )

        // 4. 상위 N개 색상 반환
        let topColors = colorCounts
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { UIColor(hex: $0.key) }

        return topColors.isEmpty ? [.gray] : topColors
    }

    // MARK: - Private Helpers

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
        let sampleRate = 5 // 5픽셀마다 샘플링

        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let offset = (y * width + x) * 4

                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0

                // 투명한 픽셀 제외
                guard a > 0.5 else { continue }

                // 너무 밝거나 어두운 색 제외
                let brightness = (r + g + b) / 3.0
                guard brightness > 0.1 && brightness < 0.95 else { continue }

                // 색상 양자화 (비슷한 색상 그룹화)
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

// MARK: - UIColor Hex Extension
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

// MARK: - 사용 예시
/*

 // 간단한 사용법
 let image = UIImage(named: "photo")!
 let dominantColor = DominantColorExtractor.extract(from: image).first!
 view.backgroundColor = dominantColor

 // 상위 3개 색상 추출
 let topColors = DominantColorExtractor.extract(from: image, count: 3)

 // 비동기 처리 권장
 DispatchQueue.global().async {
     let color = DominantColorExtractor.extract(from: image).first!
     DispatchQueue.main.async {
         self.view.backgroundColor = color
     }
 }

 */
