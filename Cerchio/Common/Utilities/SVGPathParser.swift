//
//  SVGPathParser.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit

struct SVGPathParser {

    static func extractPath(from svgString: String) -> String? {
        let pattern = #"<path[^>]*\sd="([^"]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: svgString, range: NSRange(svgString.startIndex..., in: svgString)),
              let range = Range(match.range(at: 1), in: svgString) else {
            return nil
        }

        return String(svgString[range])
    }

    static func parse(_ pathData: String, into path: UIBezierPath) {
        var currentPoint = CGPoint.zero

        let pattern = #"([MLCQZHVmlcqzhv])|(-?\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let nsString = pathData as NSString
        let matches = regex.matches(in: pathData, range: NSRange(location: 0, length: nsString.length))

        var tokens: [String] = []
        for match in matches {
            tokens.append(nsString.substring(with: match.range))
        }

        var i = 0
        while i < tokens.count {
            let cmd = tokens[i]

            switch cmd {
            case "M":
                guard i + 2 < tokens.count else { break }
                let x = CGFloat(Double(tokens[i+1]) ?? 0)
                let y = CGFloat(Double(tokens[i+2]) ?? 0)
                currentPoint = CGPoint(x: x, y: y)
                path.move(to: currentPoint)
                i += 3

            case "m":
                guard i + 2 < tokens.count else { break }
                let dx = CGFloat(Double(tokens[i+1]) ?? 0)
                let dy = CGFloat(Double(tokens[i+2]) ?? 0)
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
                path.move(to: currentPoint)
                i += 3

            case "L":
                guard i + 2 < tokens.count else { break }
                let x = CGFloat(Double(tokens[i+1]) ?? 0)
                let y = CGFloat(Double(tokens[i+2]) ?? 0)
                currentPoint = CGPoint(x: x, y: y)
                path.addLine(to: currentPoint)
                i += 3

            case "l":
                guard i + 2 < tokens.count else { break }
                let dx = CGFloat(Double(tokens[i+1]) ?? 0)
                let dy = CGFloat(Double(tokens[i+2]) ?? 0)
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y + dy)
                path.addLine(to: currentPoint)
                i += 3

            case "H":
                guard i + 1 < tokens.count else { break }
                let x = CGFloat(Double(tokens[i+1]) ?? 0)
                currentPoint = CGPoint(x: x, y: currentPoint.y)
                path.addLine(to: currentPoint)
                i += 2

            case "h":
                guard i + 1 < tokens.count else { break }
                let dx = CGFloat(Double(tokens[i+1]) ?? 0)
                currentPoint = CGPoint(x: currentPoint.x + dx, y: currentPoint.y)
                path.addLine(to: currentPoint)
                i += 2

            case "V":
                guard i + 1 < tokens.count else { break }
                let y = CGFloat(Double(tokens[i+1]) ?? 0)
                currentPoint = CGPoint(x: currentPoint.x, y: y)
                path.addLine(to: currentPoint)
                i += 2

            case "v":
                guard i + 1 < tokens.count else { break }
                let dy = CGFloat(Double(tokens[i+1]) ?? 0)
                currentPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + dy)
                path.addLine(to: currentPoint)
                i += 2

            case "C":
                guard i + 6 < tokens.count else { break }
                let cp1 = CGPoint(
                    x: CGFloat(Double(tokens[i+1]) ?? 0),
                    y: CGFloat(Double(tokens[i+2]) ?? 0)
                )
                let cp2 = CGPoint(
                    x: CGFloat(Double(tokens[i+3]) ?? 0),
                    y: CGFloat(Double(tokens[i+4]) ?? 0)
                )
                let end = CGPoint(
                    x: CGFloat(Double(tokens[i+5]) ?? 0),
                    y: CGFloat(Double(tokens[i+6]) ?? 0)
                )
                currentPoint = end
                path.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
                i += 7

            case "c":
                guard i + 6 < tokens.count else { break }
                let cp1 = CGPoint(
                    x: currentPoint.x + CGFloat(Double(tokens[i+1]) ?? 0),
                    y: currentPoint.y + CGFloat(Double(tokens[i+2]) ?? 0)
                )
                let cp2 = CGPoint(
                    x: currentPoint.x + CGFloat(Double(tokens[i+3]) ?? 0),
                    y: currentPoint.y + CGFloat(Double(tokens[i+4]) ?? 0)
                )
                let end = CGPoint(
                    x: currentPoint.x + CGFloat(Double(tokens[i+5]) ?? 0),
                    y: currentPoint.y + CGFloat(Double(tokens[i+6]) ?? 0)
                )
                currentPoint = end
                path.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
                i += 7

            case "Q":
                guard i + 4 < tokens.count else { break }
                let cp = CGPoint(
                    x: CGFloat(Double(tokens[i+1]) ?? 0),
                    y: CGFloat(Double(tokens[i+2]) ?? 0)
                )
                let end = CGPoint(
                    x: CGFloat(Double(tokens[i+3]) ?? 0),
                    y: CGFloat(Double(tokens[i+4]) ?? 0)
                )
                currentPoint = end
                path.addQuadCurve(to: end, controlPoint: cp)
                i += 5

            case "q":
                guard i + 4 < tokens.count else { break }
                let cp = CGPoint(
                    x: currentPoint.x + CGFloat(Double(tokens[i+1]) ?? 0),
                    y: currentPoint.y + CGFloat(Double(tokens[i+2]) ?? 0)
                )
                let end = CGPoint(
                    x: currentPoint.x + CGFloat(Double(tokens[i+3]) ?? 0),
                    y: currentPoint.y + CGFloat(Double(tokens[i+4]) ?? 0)
                )
                currentPoint = end
                path.addQuadCurve(to: end, controlPoint: cp)
                i += 5

            case "Z", "z":
                path.close()
                i += 1

            default:
                i += 1
            }
        }
    }
}

extension UIBezierPath {
    convenience init?(svgFile: URL) {
        guard let svgData = try? Data(contentsOf: svgFile),
              let svgString = String(data: svgData, encoding: .utf8),
              let pathData = SVGPathParser.extractPath(from: svgString) else {
            return nil
        }

        self.init()
        SVGPathParser.parse(pathData, into: self)
    }

    convenience init?(svgFileName: String) {
        let fileName = (svgFileName as NSString).deletingPathExtension

        if let svgURL = Bundle.main.url(forResource: fileName, withExtension: "svg") {
            self.init(svgFile: svgURL)
            return
        }

        if let asset = NSDataAsset(name: fileName),
           let svgString = String(data: asset.data, encoding: .utf8),
           let pathData = SVGPathParser.extractPath(from: svgString) {
            self.init()
            SVGPathParser.parse(pathData, into: self)
            return
        }

        return nil
    }

    func point(at percentage: CGFloat) -> CGPoint {
        let percentage = max(0, min(1, percentage))

        var points: [CGPoint] = []

        var pathLength: CGFloat = 0
        var previousPoint: CGPoint?

        cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee

            switch element.type {
            case .moveToPoint:
                previousPoint = element.points[0]
                points.append(element.points[0])

            case .addLineToPoint:
                if let prev = previousPoint {
                    let point = element.points[0]
                    pathLength += prev.distance(to: point)
                    points.append(point)
                    previousPoint = point
                }

            case .addQuadCurveToPoint:
                if let prev = previousPoint {
                    let cp = element.points[0]
                    let end = element.points[1]

                    for i in 1...20 {
                        let t = CGFloat(i) / 20.0
                        let point = quadraticBezierPoint(t: t, p0: prev, p1: cp, p2: end)
                        if let last = points.last {
                            pathLength += last.distance(to: point)
                        }
                        points.append(point)
                    }
                    previousPoint = end
                }

            case .addCurveToPoint:
                if let prev = previousPoint {
                    let cp1 = element.points[0]
                    let cp2 = element.points[1]
                    let end = element.points[2]

                    for i in 1...20 {
                        let t = CGFloat(i) / 20.0
                        let point = cubicBezierPoint(t: t, p0: prev, p1: cp1, p2: cp2, p3: end)
                        if let last = points.last {
                            pathLength += last.distance(to: point)
                        }
                        points.append(point)
                    }
                    previousPoint = end
                }

            case .closeSubpath:
                break

            @unknown default:
                break
            }
        }

        let targetLength = pathLength * percentage
        var currentLength: CGFloat = 0
        var previousSample: CGPoint?

        for point in points {
            if let prev = previousSample {
                let segmentLength = prev.distance(to: point)
                if currentLength + segmentLength >= targetLength {
                    let t = (targetLength - currentLength) / segmentLength
                    return CGPoint(
                        x: prev.x + (point.x - prev.x) * t,
                        y: prev.y + (point.y - prev.y) * t
                    )
                }
                currentLength += segmentLength
            }
            previousSample = point
        }

        return points.last ?? .zero
    }

    private func quadraticBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let mt = 1 - t
        let x = mt * mt * p0.x + 2 * mt * t * p1.x + t * t * p2.x
        let y = mt * mt * p0.y + 2 * mt * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    private func cubicBezierPoint(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        let t2 = t * t
        let t3 = t2 * t

        let x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x
        let y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
        return CGPoint(x: x, y: y)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }
}
