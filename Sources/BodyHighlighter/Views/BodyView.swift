//
//  BodyView.swift
//  BodyHighlighter
//
//  Created by gossamr on 12/16/25.
//
//  All SVG paths used and distributed under MIT License by:
//  Copyright (c) 2022 ELABBASSI Hicham
//  https://github.com/HichamELBSI/react-native-body-highlighter

import SwiftUI

public struct BodyView: View {
    // MARK: - Properties
    private let data: [BodyPartData]
    private let side: BodySide
    private let gender: Gender
    private let section: BodySection
    private let colors: [Color]
    private let scale: CGFloat
    private let border: Color?
    private let disabledParts: Set<BodyPartSlug>
    private let disabledFill: Color
    private let hiddenParts: Set<BodyPartSlug>
    private let defaultFill: Color
    private let defaultStroke: Color
    private let defaultStrokeWidth: CGFloat
    private let onBodyPartPress: ((BodyPartSlug, LateralSide?) -> Void)?

    // MARK: - Initializer
    public init(
        data: [BodyPartData] = [],
        side: BodySide = .anterior,
        gender: Gender = .woman,
        section: BodySection = .full,
        colors: [Color] = [Color(hex: "#0984e3"), Color(hex: "#74b9ff")],
        scale: CGFloat = 1.0,
        border: Color? = Color(hex: "#dfdfdf"),
        disabledParts: Set<BodyPartSlug> = BodyPartGroup.skeletal_etc.slugs(),
        disabledFill: Color = Color(hex: "#ebebe4"),
        hiddenParts: Set<BodyPartSlug> = [],
        defaultFill: Color = Color(hex: "#3f3f3f"),
        defaultStroke: Color = .clear,
        defaultStrokeWidth: CGFloat = 0,
        onBodyPartPress: ((BodyPartSlug, LateralSide?) -> Void)? = nil
    ) {
        self.data = data
        self.side = side
        self.gender = gender
        self.section = section
        self.colors = colors
        self.scale = scale
        self.border = border
        self.disabledParts = disabledParts
        self.disabledFill = disabledFill
        self.hiddenParts = hiddenParts
        self.defaultFill = defaultFill
        self.defaultStroke = defaultStroke
        self.defaultStrokeWidth = defaultStrokeWidth
        self.onBodyPartPress = onBodyPartPress
    }

    // MARK: - Body
    public var body: some View {
        let bodyParts = getBodyParts()
        let viewBox = getViewBox()

        GeometryReader { geometry in
            Canvas { context, size in
                // Scale to fit
                let scaleFactor = min(size.width / viewBox.width, size.height / viewBox.height) * scale

                // Calculate centering offsets
                let scaledWidth = viewBox.width * scaleFactor
                let scaledHeight = viewBox.height * scaleFactor
                let xOffset = (size.width - scaledWidth) / 2
                let yOffset = (size.height - scaledHeight) / 2

                // Apply transformations
                context.translateBy(x: xOffset, y: yOffset)
                context.scaleBy(x: scaleFactor, y: scaleFactor)
                context.translateBy(x: -viewBox.minX, y: -viewBox.minY)

                // Draw border if provided
                if let borderColor = border,
                   let borderPath = BodyData.getBorder(gender: gender, side: side) {
                    context.stroke(
                        borderPath,
                        with: .color(borderColor),
                        lineWidth: 2 / scaleFactor
                    )
                }

                // Draw body parts
                for bodyPart in bodyParts {
                    let userData = getUserData(for: bodyPart.slug)

                    // Draw common paths
                    for path in bodyPart.paths.common {
                        drawPath(
                            context: &context,
                            path: path,
                            bodyPart: bodyPart,
                            userData: userData,
                            side: nil
                        )
                    }

                    // Draw left paths
                    for path in bodyPart.paths.left {
                        let shouldDim = userData?.side == LateralSide.right
                        drawPath(
                            context: &context,
                            path: path,
                            bodyPart: bodyPart,
                            userData: shouldDim ? nil : userData,
                            side: .left
                        )
                    }

                    // Draw right paths
                    for path in bodyPart.paths.right {
                        let shouldDim = userData?.side == LateralSide.left
                        drawPath(
                            context: &context,
                            path: path,
                            bodyPart: bodyPart,
                            userData: shouldDim ? nil : userData,
                            side: .right
                        )
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 1, coordinateSpace: .local) { location in
                handleTap(at: location, viewSize: geometry.size, viewBox: viewBox)
            }
        }
    }

    private func handleTap(at location: CGPoint, viewSize: CGSize, viewBox: CGRect) {
        guard let onBodyPartPress else { return }

        // 1. Convert tap location to SVG coordinates

        // Calculate the scale factor used in drawing (using current viewSize)
        let scaleFactor = min(viewSize.width / viewBox.width, viewSize.height / viewBox.height) * scale

        // Calculate centering offsets (same as in drawing)
        let scaledWidth = viewBox.width * scaleFactor
        let scaledHeight = viewBox.height * scaleFactor
        let xOffset = (viewSize.width - scaledWidth) / 2
        let yOffset = (viewSize.height - scaledHeight) / 2

        // Convert to SVG space:
        // P = ((Q - M) / s) + V_min
        // where Q = location, M = offset, s = scaleFactor, V_min = viewBox.min

        let svgX = ((location.x - xOffset) / scaleFactor) + viewBox.minX
        let svgY = ((location.y - yOffset) / scaleFactor) + viewBox.minY
        let svgPoint = CGPoint(x: svgX, y: svgY)

        // 2. Find tapped body part
        let bodyParts = getBodyParts()

        for bodyPart in bodyParts {
            // Check Common Paths
            for path in bodyPart.paths.common {
                if hitTest(point: svgPoint, path: path) {
                    if !disabledParts.contains(bodyPart.slug) {
                        onBodyPartPress(bodyPart.slug, nil)
                    }
                    return
                }
            }

            // Check Left Paths
            for path in bodyPart.paths.left {
                if hitTest(point: svgPoint, path: path) {
                    if !disabledParts.contains(bodyPart.slug) {
                        onBodyPartPress(bodyPart.slug, .left)
                    }
                    return
                }
            }

            // Check Right Paths
            for path in bodyPart.paths.right {
                if hitTest(point: svgPoint, path: path) {
                    if !disabledParts.contains(bodyPart.slug) {
                        onBodyPartPress(bodyPart.slug, .right)
                    }
                    return
                }
            }
        }
    }

    private func hitTest(point: CGPoint, path: Path) -> Bool {
        // Optimization: Check bounding box first
        if !path.boundingRect.contains(point) {
            return false
        }

        return path.contains(point)
    }

    private func getBodyParts() -> [BodyPart] {
        let allParts: [BodyPart]

        switch (gender, side, section) {
        case (.man, .anterior, .upper):
            allParts = BodyData.bodyAnteriorUpper.compactMap { BodyData.bodyManAnterior[$0] }
        case (.man, .anterior, .lower):
            allParts = BodyData.bodyAnteriorLower.compactMap { BodyData.bodyManAnterior[$0] }
        case (.man, .anterior, .full):
            allParts = Array(BodyData.bodyManAnterior.values)

        case (.man, .posterior, .upper):
            allParts = BodyData.bodyPosteriorUpper.compactMap { BodyData.bodyManPosterior[$0] }
        case (.man, .posterior, .lower):
            allParts = BodyData.bodyPosteriorLower.compactMap { BodyData.bodyManPosterior[$0] }
        case (.man, .posterior, .full):
            allParts = Array(BodyData.bodyManPosterior.values)

        case (.woman, .anterior, .upper):
            allParts = BodyData.bodyAnteriorUpper.compactMap { BodyData.bodyWomanAnterior[$0] }
        case (.woman, .anterior, .lower):
            allParts = BodyData.bodyAnteriorLower.compactMap { BodyData.bodyWomanAnterior[$0] }
        case (.woman, .anterior, .full):
            allParts = Array(BodyData.bodyWomanAnterior.values)

        case (.woman, .posterior, .upper):
            allParts = BodyData.bodyPosteriorUpper.compactMap { BodyData.bodyWomanPosterior[$0] }
        case (.woman, .posterior, .lower):
            allParts = BodyData.bodyPosteriorLower.compactMap { BodyData.bodyWomanPosterior[$0] }
        case (.woman, .posterior, .full):
            allParts = Array(BodyData.bodyWomanPosterior.values)
        }

        return allParts.filter { !hiddenParts.contains($0.slug) }
    }

    private func calculateBoundingBox(for bodyParts: [BodyPart]) -> CGRect {
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        for bodyPart in bodyParts {
            let allPaths = bodyPart.paths.common + bodyPart.paths.left + bodyPart.paths.right

            for path in allPaths {
                let bounds = path.boundingRect

                minX = min(minX, bounds.minX)
                minY = min(minY, bounds.minY)
                maxX = max(maxX, bounds.maxX)
                maxY = max(maxY, bounds.maxY)
            }
        }

        let actualWidth = maxX - minX
        let actualHeight = maxY - minY

        // Add padding to ensure nothing gets clipped
        let padding: CGFloat = 20

        // Use a normalized width that fits both genders comfortably
        let normalizedWidth: CGFloat = 700
        let normalizedHeight: CGFloat = 1500

        // Calculate center of actual content
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2

        // Determine which dimension needs more space relative to normalized size
        let widthRatio = actualWidth / normalizedWidth
        let heightRatio = actualHeight / normalizedHeight

        // Use the larger ratio to ensure everything fits
        let ratio = max(widthRatio, heightRatio)

        // Calculate final viewBox dimensions that maintain aspect ratio
        let finalWidth = normalizedWidth * ratio + (padding * 2)
        let finalHeight = normalizedHeight * ratio + (padding * 2)

        // Center the viewBox around the content center
        return CGRect(
            x: centerX - finalWidth / 2,
            y: centerY - finalHeight / 2,
            width: finalWidth,
            height: finalHeight
        )
    }

    private func getViewBox() -> CGRect {
        let bodyParts = getBodyParts()
        return calculateBoundingBox(for: bodyParts)
    }

    private func getUserData(for slug: BodyPartSlug) -> BodyPartData? {
        data.first { $0.matches(slug) }
    }

    private func drawPath(
        context: inout GraphicsContext,
        path: Path,
        bodyPart: BodyPart,
        userData: BodyPartData?,
        side: LateralSide?
    ) {
        let fillColor = getFillColor(for: bodyPart, userData: userData)
        let style = userData?.style ?? BodyPartStyle(fill: fillColor)

        context.fill(path, with: .color(style.fill))

        if style.strokeWidth > 0 {
            context.stroke(path, with: .color(style.stroke), lineWidth: style.strokeWidth)
        }
    }

    private func getFillColor(for bodyPart: BodyPart, userData: BodyPartData?) -> Color {
        // Disabled parts
        if disabledParts.contains(bodyPart.slug),
           userData == nil || !userData!.override {
            return disabledFill
        }

        // Priority: style.fill > color > intensity > default
        if let style = userData?.style {
            return style.fill
        }

        if let color = userData?.color {
            return color
        }

        if let intensity = userData?.intensity, intensity > 0, intensity <= colors.count {
            return colors[intensity - 1]
        }

        return defaultFill
    }
}
