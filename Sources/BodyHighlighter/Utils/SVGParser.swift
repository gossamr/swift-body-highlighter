//
//  SVGParser.swift
//  BodyHighlighter
//
//  Created by gossamr on 12/16/25.
//

import SwiftUI

public struct SVGParser {
    public static func parse(_ pathString: String, debug: Bool = false) -> Path {
        var path = Path()
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero
        var lastControl = CGPoint.zero
        var previousCommand: Character? = nil
        
        var index = pathString.startIndex
        var currentCommand: Character? = nil
        
        if debug {
            print("SVGParser.parse: Starting a new parse!")
        }
        
        func skipWhitespace() {
            while index < pathString.endIndex && (pathString[index].isWhitespace || pathString[index] == ",") {
                index = pathString.index(after: index)
            }
        }
        
        func isCommandLetter(_ char: Character) -> Bool {
            let commands: Set<Character> = ["M", "m", "L", "l", "H", "h", "V", "v",
                                           "C", "c", "S", "s", "Q", "q", "T", "t",
                                           "A", "a", "Z", "z"]
            return commands.contains(char)
        }
        
        func readNumber() -> Double? {
            skipWhitespace()
            guard index < pathString.endIndex else { return nil }
            
            var numStr = ""
            let start = index
            var hasDecimal = false
            var hasExponent = false
            var hasDigits = false
            
            // Handle sign
            if pathString[index] == "-" || pathString[index] == "+" {
                numStr.append(pathString[index])
                index = pathString.index(after: index)
            }
            
            // Read digits before decimal/exponent
            while index < pathString.endIndex && pathString[index].isNumber {
                hasDigits = true
                numStr.append(pathString[index])
                index = pathString.index(after: index)
            }
            
            // Read decimal point and following digits
            if index < pathString.endIndex && pathString[index] == "." {
                hasDecimal = true
                numStr.append(pathString[index])
                index = pathString.index(after: index)
                
                while index < pathString.endIndex && pathString[index].isNumber {
                    hasDigits = true
                    numStr.append(pathString[index])
                    index = pathString.index(after: index)
                }
            }
            
            // Handle scientific notation
            if index < pathString.endIndex {
                let char = pathString[index]
                if char == "e" || char == "E" {
                    let nextIndex = pathString.index(after: index)
                    if nextIndex < pathString.endIndex {
                        let nextChar = pathString[nextIndex]
                        if nextChar == "+" || nextChar == "-" || nextChar.isNumber {
                            hasExponent = true
                            numStr.append(char)
                            index = pathString.index(after: index)
                            
                            if pathString[index] == "-" || pathString[index] == "+" {
                                numStr.append(pathString[index])
                                index = pathString.index(after: index)
                            }
                            
                            while index < pathString.endIndex && pathString[index].isNumber {
                                numStr.append(pathString[index])
                                index = pathString.index(after: index)
                            }
                        }
                    }
                }
            }
            
            // Validate we have a complete number
            if !hasDigits || numStr.isEmpty || numStr == "-" || numStr == "+" || numStr == "." {
                index = start
                return nil
            }
            
            if let value = Double(numStr) {
                if debug {
                    print("Parsed number: '\(numStr)' = \(value)")
                }
                return value
            }
            
            index = start
            return nil
        }
        
        // Special function for reading arc flags (0 or 1 only)
        func readFlag() -> Double? {
            skipWhitespace()
            guard index < pathString.endIndex else { return nil }
            
            let char = pathString[index]
            if char == "0" {
                index = pathString.index(after: index)
                if debug { print("Parsed flag: '0' = 0.0") }
                return 0.0
            } else if char == "1" {
                index = pathString.index(after: index)
                if debug { print("Parsed flag: '1' = 1.0") }
                return 1.0
            }
            
            return nil
        }
        
        while index < pathString.endIndex {
            skipWhitespace()
            guard index < pathString.endIndex else { break }
            
            let char = pathString[index]
            
            if isCommandLetter(char) {
                previousCommand = currentCommand
                currentCommand = char
                index = pathString.index(after: index)
                if debug {
                    print("\n=== Command: \(char) ===")
                }
            }
            
            guard let cmd = currentCommand else { break }
            
            switch cmd {
            case "M":
                guard let x = readNumber(), let y = readNumber() else {
                    if debug { print("M: Failed to read coordinates") }
                    break
                }
                currentPoint = CGPoint(x: x, y: y)
                startPoint = currentPoint
                path.move(to: currentPoint)
                lastControl = currentPoint
                currentCommand = "L"
                if debug { print("M: move to (\(x), \(y))") }
                
            case "m":
                guard let x = readNumber(), let y = readNumber() else {
                    if debug { print("m: Failed to read coordinates") }
                    break
                }
                currentPoint = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                startPoint = currentPoint
                path.move(to: currentPoint)
                lastControl = currentPoint
                currentCommand = "l"
                if debug { print("m: move by (\(x), \(y)) to (\(currentPoint.x), \(currentPoint.y))") }
                
            case "L":
                guard let x = readNumber(), let y = readNumber() else { break }
                currentPoint = CGPoint(x: x, y: y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("L: line to (\(x), \(y))") }
                
            case "l":
                guard let x = readNumber(), let y = readNumber() else { break }
                currentPoint = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("l: line by (\(x), \(y))") }
                
            case "H":
                guard let x = readNumber() else { break }
                currentPoint = CGPoint(x: x, y: currentPoint.y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("H: horizontal to \(x)") }
                
            case "h":
                guard let x = readNumber() else { break }
                currentPoint = CGPoint(x: currentPoint.x + x, y: currentPoint.y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("h: horizontal by \(x)") }
                
            case "V":
                guard let y = readNumber() else { break }
                currentPoint = CGPoint(x: currentPoint.x, y: y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("V: vertical to \(y)") }
                
            case "v":
                guard let y = readNumber() else { break }
                currentPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + y)
                path.addLine(to: currentPoint)
                lastControl = currentPoint
                if debug { print("v: vertical by \(y)") }
                
            case "C":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else {
                    if debug { print("C: Failed to read all 6 coordinates") }
                    break
                }
                let cp1 = CGPoint(x: x1, y: y1)
                let cp2 = CGPoint(x: x2, y: y2)
                let end = CGPoint(x: x, y: y)
                path.addCurve(to: end, control1: cp1, control2: cp2)
                lastControl = cp2
                currentPoint = end
                if debug { print("C: curve to (\(x), \(y)) with controls (\(x1), \(y1)) and (\(x2), \(y2))") }
                
            case "c":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else {
                    if debug { print("c: Failed to read all 6 coordinates") }
                    break
                }
                let cp1 = CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1)
                let cp2 = CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2)
                let end = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                path.addCurve(to: end, control1: cp1, control2: cp2)
                lastControl = cp2
                currentPoint = end
                if debug { print("c: curve by (\(x), \(y))") }
                
            case "S":
                guard let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { break }
                let cp1: CGPoint
                if let prev = previousCommand, ["C", "c", "S", "s"].contains(prev) {
                    cp1 = CGPoint(x: 2 * currentPoint.x - lastControl.x,
                                 y: 2 * currentPoint.y - lastControl.y)
                } else {
                    cp1 = currentPoint
                }
                let cp2 = CGPoint(x: x2, y: y2)
                let end = CGPoint(x: x, y: y)
                path.addCurve(to: end, control1: cp1, control2: cp2)
                lastControl = cp2
                currentPoint = end
                
            case "s":
                guard let x2 = readNumber(), let y2 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { break }
                let cp1: CGPoint
                if let prev = previousCommand, ["C", "c", "S", "s"].contains(prev) {
                    cp1 = CGPoint(x: 2 * currentPoint.x - lastControl.x,
                                 y: 2 * currentPoint.y - lastControl.y)
                } else {
                    cp1 = currentPoint
                }
                let cp2 = CGPoint(x: currentPoint.x + x2, y: currentPoint.y + y2)
                let end = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                path.addCurve(to: end, control1: cp1, control2: cp2)
                lastControl = cp2
                currentPoint = end
                
            case "Q":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { break }
                let cp = CGPoint(x: x1, y: y1)
                let end = CGPoint(x: x, y: y)
                path.addQuadCurve(to: end, control: cp)
                lastControl = cp
                currentPoint = end
                
            case "q":
                guard let x1 = readNumber(), let y1 = readNumber(),
                      let x = readNumber(), let y = readNumber() else { break }
                let cp = CGPoint(x: currentPoint.x + x1, y: currentPoint.y + y1)
                let end = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                path.addQuadCurve(to: end, control: cp)
                lastControl = cp
                currentPoint = end
                
            case "T":
                guard let x = readNumber(), let y = readNumber() else { break }
                let cp: CGPoint
                if let prev = previousCommand, ["Q", "q", "T", "t"].contains(prev) {
                    cp = CGPoint(x: 2 * currentPoint.x - lastControl.x,
                                y: 2 * currentPoint.y - lastControl.y)
                } else {
                    cp = currentPoint
                }
                let end = CGPoint(x: x, y: y)
                path.addQuadCurve(to: end, control: cp)
                lastControl = cp
                currentPoint = end
                
            case "t":
                guard let x = readNumber(), let y = readNumber() else { break }
                let cp: CGPoint
                if let prev = previousCommand, ["Q", "q", "T", "t"].contains(prev) {
                    cp = CGPoint(x: 2 * currentPoint.x - lastControl.x,
                                y: 2 * currentPoint.y - lastControl.y)
                } else {
                    cp = currentPoint
                }
                let end = CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                path.addQuadCurve(to: end, control: cp)
                lastControl = cp
                currentPoint = end
                
            case "A", "a":
                guard let rx = readNumber(), let ry = readNumber(),
                      let xAxisRotation = readNumber(),
                      let largeArcFlag = readFlag(),
                      let sweepFlag = readFlag(),
                      let x = readNumber(), let y = readNumber() else {
                    if debug { print("\(cmd): Failed to read arc parameters") }
                    break
                }
                
                let endPoint = cmd == "A" ? CGPoint(x: x, y: y) :
                                            CGPoint(x: currentPoint.x + x, y: currentPoint.y + y)
                
                if debug {
                    print("\(cmd): arc rx=\(rx) ry=\(ry) rotation=\(xAxisRotation) large=\(largeArcFlag) sweep=\(sweepFlag) to (\(endPoint.x), \(endPoint.y))")
                }
                
                approximateArc(
                    path: &path,
                    currentPoint: currentPoint,
                    rx: rx, ry: ry,
                    xAxisRotation: xAxisRotation,
                    largeArc: largeArcFlag != 0,
                    sweep: sweepFlag != 0,
                    endPoint: endPoint
                )
                
                lastControl = endPoint
                currentPoint = endPoint
                
            case "Z", "z":
                path.closeSubpath()
                currentPoint = startPoint
                lastControl = currentPoint
                if debug { print("\(cmd): close path") }
                
            default:
                index = pathString.index(after: index)
            }
            
            if cmd != "M" && cmd != "m" {
                previousCommand = cmd
            }
        }
        
        if debug {
            print("SVGParser.parse: Finished parsing!")
        }
        
        return path
    }
    
    private static func approximateArc(
        path: inout Path,
        currentPoint: CGPoint,
        rx: Double, ry: Double,
        xAxisRotation: Double,
        largeArc: Bool,
        sweep: Bool,
        endPoint: CGPoint
    ) {
        guard rx > 0 && ry > 0 else {
            path.addLine(to: endPoint)
            return
        }
        
        if currentPoint == endPoint {
            return
        }
        
        let phi = xAxisRotation * .pi / 180.0
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        
        let dx = (currentPoint.x - endPoint.x) / 2
        let dy = (currentPoint.y - endPoint.y) / 2
        
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy
        
        var rxAbs = abs(rx)
        var ryAbs = abs(ry)
        let lambda = (x1p * x1p) / (rxAbs * rxAbs) + (y1p * y1p) / (ryAbs * ryAbs)
        if lambda > 1 {
            rxAbs *= sqrt(lambda)
            ryAbs *= sqrt(lambda)
        }
        
        let cp1X = currentPoint.x + (endPoint.x - currentPoint.x) / 3
        let cp1Y = currentPoint.y + (endPoint.y - currentPoint.y) / 3
        let cp2X = currentPoint.x + 2 * (endPoint.x - currentPoint.x) / 3
        let cp2Y = currentPoint.y + 2 * (endPoint.y - currentPoint.y) / 3
        
        path.addCurve(
            to: endPoint,
            control1: CGPoint(x: cp1X, y: cp1Y),
            control2: CGPoint(x: cp2X, y: cp2Y)
        )
    }
}
