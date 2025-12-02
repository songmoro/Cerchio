import UIKit

// MARK: - UIColor Serialization

extension UIColor {
    /// Serializes UIColor to Data using RGBA components
    /// Format: [R: 4 bytes][G: 4 bytes][B: 4 bytes][A: 4 bytes] (Float32)
    func toData() -> Data? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        var data = Data()

        var redFloat = Float32(red)
        var greenFloat = Float32(green)
        var blueFloat = Float32(blue)
        var alphaFloat = Float32(alpha)

        Swift.withUnsafeBytes(of: &redFloat) { data.append(contentsOf: $0) }
        Swift.withUnsafeBytes(of: &greenFloat) { data.append(contentsOf: $0) }
        Swift.withUnsafeBytes(of: &blueFloat) { data.append(contentsOf: $0) }
        Swift.withUnsafeBytes(of: &alphaFloat) { data.append(contentsOf: $0) }

        return data
    }

    /// Deserializes UIColor from Data
    /// Format: [R: 4 bytes][G: 4 bytes][B: 4 bytes][A: 4 bytes] (Float32)
    static func fromData(_ data: Data) -> UIColor? {
        guard data.count == 16 else { return nil }

        let red = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Float32.self) }
        let green = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Float32.self) }
        let blue = data.withUnsafeBytes { $0.load(fromByteOffset: 8, as: Float32.self) }
        let alpha = data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: Float32.self) }

        return UIColor(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: CGFloat(alpha)
        )
    }
}

// MARK: - Array<UIColor> Serialization

extension Array where Element == UIColor {
    /// Serializes array of UIColor to Data
    /// Format: [Count: 4 bytes][Color1: 16 bytes][Color2: 16 bytes]...
    func toData() -> Data? {
        var data = Data()

        // Write count
        var count = Int32(self.count)
        let countBytes = Swift.withUnsafeBytes(of: &count) { Data($0) }
        data.append(countBytes)

        // Write each color
        for color in self {
            guard let colorData = color.toData() else {
                return nil
            }
            data.append(colorData)
        }

        return data
    }

    /// Deserializes array of UIColor from Data
    /// Format: [Count: 4 bytes][Color1: 16 bytes][Color2: 16 bytes]...
    static func fromData(_ data: Data) -> [UIColor]? {
        guard data.count >= 4 else { return nil }

        // Read count
        let count = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Int32.self) }

        guard count >= 0 else { return nil }

        // Validate data size: 4 bytes (count) + count * 16 bytes (colors)
        let expectedSize = 4 + Int(count) * 16
        guard data.count == expectedSize else { return nil }

        var colors: [UIColor] = []

        // Read each color
        for index in 0..<Int(count) {
            let offset = 4 + index * 16
            let colorData = data.subdata(in: offset..<(offset + 16))

            guard let color = UIColor.fromData(colorData) else {
                return nil
            }

            colors.append(color)
        }

        return colors
    }
}
