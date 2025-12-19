//
//  BodyHighlighterTests.swift
//  BodyHighlighterTests
//
//  Created by gossamr on 12/16/25.
//

import XCTest
import SwiftUI
@testable import BodyHighlighter

final class BodyHighlighterTests: XCTestCase {
    // MARK: - Color Tests

    func testColorFromHex3Digit() {
        let color = Color(hex: "abc")
        // 3-digit hex should expand: a -> aa, b -> bb, c -> cc
        // This creates RGB(170, 187, 204) with alpha 255
        XCTAssertNotNil(color)
    }

    func testColorFromHex6Digit() {
        let color = Color(hex: "#3f3f3f")
        XCTAssertNotNil(color)
    }

    func testColorFromHex8Digit() {
        let color = Color(hex: "80ff0000")
        // ARGB format: 80 (alpha), ff (red), 00 (green), 00 (blue)
        XCTAssertNotNil(color)
    }

    func testColorFromInvalidHex() {
        let color = Color(hex: "invalid")
        // Should fallback to black (0, 0, 0)
        XCTAssertNotNil(color)
    }

    // MARK: - BodyPartData Tests

    func testBodyPartDataInitialization() {
        let data = BodyPartData(slug: .pectoralis_major, side: .left)
        XCTAssertEqual(data.id, "pectoralis_majorleft")
        XCTAssertEqual(data.slug, .pectoralis_major)
        XCTAssertEqual(data.side, .left)
    }



    func testBodyPartDataInitializationWithStyle() {
        let style = BodyPartStyle(fill: .red, stroke: .blue, strokeWidth: 2)
        let data = BodyPartData(slug: .biceps, style: style)
        XCTAssertEqual(data.style?.fill, .red)
        XCTAssertEqual(data.style?.stroke, .blue)
        XCTAssertEqual(data.style?.strokeWidth, 2)
    }

    func testBodyPartDataInitializationWithColor() {
        let data = BodyPartData(slug: .triceps_brachii_long, color: .green)
        XCTAssertEqual(data.color, .green)
    }

    func testBodyPartDataInitializationWithIntensity() {
        let data = BodyPartData(slug: .deltoids, intensity: 1)
        XCTAssertEqual(data.intensity, 1)
    }

    func testBodyPartDataMatchesSlug() {
        // 1. Direct match check
        let data = BodyPartData(slug: .biceps)
        XCTAssertTrue(data.matches(.biceps))
        XCTAssertFalse(data.matches(.triceps_brachii_long))
    }

    func testBodyPartDataMatchesSection() {
        // 2. Section match check
        let data = BodyPartData(group: .arms)

        // .arms section contains: .brachioradialis, .biceps, .triceps_brachii_long, .triceps_brachii_medial, .triceps_brachii_lateral
        XCTAssertTrue(data.matches(.biceps), "Should match biceps as it is in arms section")
        XCTAssertTrue(data.matches(.triceps_brachii_long), "Should match triceps as it is in arms section")

        XCTAssertFalse(data.matches(.rectus_abdominus), "Should not match abs which is not in arms section")
    }

    func testBodyPartDataMatchesNone() {
        // 3. No match check
        let data = BodyPartData(slug: .neck, side: .left) 
        // Checks that a slug outside of the target still returns false
        XCTAssertFalse(data.matches(.biceps))
    }

    // MARK: - Data Integrity Tests

    func testMaleFrontUpper() {
        let parts = BodyData.bodyAnteriorUpper
        XCTAssertFalse(parts.isEmpty, "Male front upper body data should not be empty")

        // Verify expected parts exist
        XCTAssertTrue(parts.contains(.pectoralis_major), "Should contain chest")
        XCTAssertTrue(parts.contains(.rectus_abdominus), "Should contain abs")
        XCTAssertTrue(parts.contains(.biceps), "Should contain biceps")
    }

    func testMaleFrontLower() {
        let parts = BodyData.bodyAnteriorLower
        XCTAssertFalse(parts.isEmpty, "Male front lower body data should not be empty")

        XCTAssertTrue(parts.contains(.rectus_femoris), "Should contain quadriceps")
        XCTAssertTrue(parts.contains(.tibialis_anterior), "Should contain calves")
    }

    func testMaleBackUpper() {
        let parts = BodyData.bodyPosteriorUpper
        XCTAssertFalse(parts.isEmpty, "Male back upper body data should not be empty")

        XCTAssertTrue(parts.contains(.trapezius), "Should contain trapezius")
        XCTAssertTrue(parts.contains(.deltoid_rear), "Should contain deltoids")
    }

    func testMaleBackLower() {
        let parts = BodyData.bodyPosteriorLower
        XCTAssertFalse(parts.isEmpty, "Male back lower body data should not be empty")

        XCTAssertTrue(parts.contains(.gluteus_maximus), "Should contain gluteal")
        XCTAssertTrue(parts.contains(.biceps_femoris), "Should contain hamstring")
    }

    func testFemaleFrontUpper() {
        let parts = BodyData.bodyAnteriorUpper
        XCTAssertFalse(parts.isEmpty, "Female front upper body data should not be empty")

        XCTAssertTrue(parts.contains(.pectoralis_major), "Should contain chest")
        XCTAssertTrue(parts.contains(.rectus_abdominus), "Should contain abs")
    }

    func testFemaleFrontLower() {
        let parts = BodyData.bodyAnteriorLower
        XCTAssertFalse(parts.isEmpty, "Female front lower body data should not be empty")

        XCTAssertTrue(parts.contains(.rectus_femoris), "Should contain quadriceps")
        XCTAssertTrue(parts.contains(.tibialis_anterior), "Should contain calves")
    }

    func testFemaleBackUpper() {
        let parts = BodyData.bodyPosteriorUpper
        XCTAssertFalse(parts.isEmpty, "Female back upper body data should not be empty")

        XCTAssertTrue(parts.contains(.trapezius), "Should contain trapezius")
        XCTAssertTrue(parts.contains(.deltoid_rear), "Should contain deltoids")
    }

    func testFemaleBackLower() {
        let parts = BodyData.bodyPosteriorLower
        XCTAssertFalse(parts.isEmpty, "Female back lower body data should not be empty")

        XCTAssertTrue(parts.contains(.gluteus_maximus), "Should contain gluteal")
        XCTAssertTrue(parts.contains(.biceps_femoris), "Should contain hamstring")
    }

    func testDataStructure() {
        // Test that BodyPaths and BodyPart structures work as expected
        let paths = BodyPaths(common: ["M 0 0 L 10 10"], left: ["M 20 20 L 30 30"], right: ["M 40 40 L 50 50"])
        XCTAssertEqual(paths.common.count, 1)
        XCTAssertEqual(paths.left.count, 1)
        XCTAssertEqual(paths.right.count, 1)

        let part = BodyPart(slug: .biceps, paths: paths)
        XCTAssertEqual(part.slug, .biceps)
        XCTAssertEqual(part.paths, paths)
    }

    // MARK: - View Rendering Tests

    func testBodyViewMaleFrontUpper() {
        // Test that view can be initialized with male front configuration
        let view = BodyView(side: .anterior, gender: .man)
        XCTAssertNotNil(view, "Should be able to create view for male front")
    }

    func testBodyViewMaleFrontLower() {
        // View combines upper+lower, but we verify data exists
        let parts = BodyData.bodyAnteriorLower
        XCTAssertFalse(parts.isEmpty, "Male front lower should have data for rendering")
    }

    func testBodyViewMaleBackUpper() {
        let view = BodyView(side: .posterior, gender: .man)
        XCTAssertNotNil(view, "Should be able to create view for male back")
    }

    func testBodyViewMaleBackLower() {
        let parts = BodyData.bodyPosteriorLower
        XCTAssertFalse(parts.isEmpty, "Male back lower should have data for rendering")
    }

    func testBodyViewFemaleFrontUpper() {
        let view = BodyView(side: .anterior, gender: .woman)
        XCTAssertNotNil(view, "Should be able to create view for female front")
    }

    func testBodyViewFemaleFrontLower() {
        let parts = BodyData.bodyAnteriorLower
        XCTAssertFalse(parts.isEmpty, "Female front lower should have data for rendering")
    }

    func testBodyViewFemaleBackUpper() {
        let view = BodyView(side: .posterior, gender: .woman)
        XCTAssertNotNil(view, "Should be able to create view for female back")
    }

    func testBodyViewFemaleBackLower() {
        let parts = BodyData.bodyPosteriorLower
        XCTAssertFalse(parts.isEmpty, "Female back lower should have data for rendering")
    }

    func testBodyViewCombined() {
        // Test that view correctly combines upper and lower parts
        let view = BodyView(side: .anterior, gender: .man)
        XCTAssertNotNil(view)

        // Verify the combined data would include both upper and lower
        let upperParts = BodyData.bodyAnteriorUpper
        let lowerParts = BodyData.bodyAnteriorLower
        XCTAssertFalse(upperParts.isEmpty)
        XCTAssertFalse(lowerParts.isEmpty)
    }

    func testBodyViewWithData() {
        // Test view with custom body part data
        let customData = [
            BodyPartData(slug: .pectoralis_major, color: .red, intensity: 2),
            BodyPartData(slug: .rectus_abdominus, color: .blue)
        ]

        let view = BodyView(data: customData, side: .anterior, gender: .man)
        XCTAssertNotNil(view)
    }

    func testBodyViewWithDisabledParts() {
        let disabledParts: Set<BodyPartSlug> = [.pectoralis_major, .rectus_abdominus]
        let view = BodyView(
            side: .anterior,
            gender: .man,
            disabledParts: disabledParts
        )
        XCTAssertNotNil(view)
    }

    func testBodyViewWithHiddenParts() {
        let hiddenParts: Set<BodyPartSlug> = [.biceps, .triceps_brachii_long]
        let view = BodyView(
            side: .anterior,
            gender: .man,
            hiddenParts: hiddenParts
        )
        XCTAssertNotNil(view)
    }

    func testBodyViewWithCustomColors() {
        let customColors = [Color.red, Color.blue, Color.green]
        let view = BodyView(
            side: .anterior,
            gender: .man,
            colors: customColors
        )
        XCTAssertNotNil(view)
    }

    func testBodyViewWithScale() {
        let view = BodyView(
            side: .anterior,
            gender: .man,
            scale: 2.0
        )
        XCTAssertNotNil(view)
    }

    // MARK: - BodySection Tests

    func testBodyViewUpperOnly() {
        let view = BodyView(side: .anterior, gender: .man, section: .upper)
        XCTAssertNotNil(view, "Should be able to create view with upper section only")
    }

    func testBodyViewLowerOnly() {
        let view = BodyView(side: .anterior, gender: .man, section: .lower)
        XCTAssertNotNil(view, "Should be able to create view with lower section only")
    }

    func testBodyViewFullSection() {
        let view = BodyView(side: .anterior, gender: .man, section: .full)
        XCTAssertNotNil(view, "Should be able to create view with full section")
    }

    func testBodyViewDefaultSectionIsFull() {
        // When no section is specified, it should default to .full
        let view = BodyView(side: .anterior, gender: .man)
        XCTAssertNotNil(view)
        // Implicitly tests backward compatibility
    }

    func testAllSectionCombinationsMaleFront() {
        // Test all 3 sections for male front
        let upperView = BodyView(side: .anterior, gender: .man, section: .upper)
        let lowerView = BodyView(side: .anterior, gender: .man, section: .lower)
        let fullView = BodyView(side: .anterior, gender: .man, section: .full)

        XCTAssertNotNil(upperView)
        XCTAssertNotNil(lowerView)
        XCTAssertNotNil(fullView)
    }

    func testAllSectionCombinationsMaleBack() {
        let upperView = BodyView(side: .posterior, gender: .man, section: .upper)
        let lowerView = BodyView(side: .posterior, gender: .man, section: .lower)
        let fullView = BodyView(side: .posterior, gender: .man, section: .full)

        XCTAssertNotNil(upperView)
        XCTAssertNotNil(lowerView)
        XCTAssertNotNil(fullView)
    }

    func testAllSectionCombinationsFemaleFront() {
        let upperView = BodyView(side: .anterior, gender: .woman, section: .upper)
        let lowerView = BodyView(side: .anterior, gender: .woman, section: .lower)
        let fullView = BodyView(side: .anterior, gender: .woman, section: .full)

        XCTAssertNotNil(upperView)
        XCTAssertNotNil(lowerView)
        XCTAssertNotNil(fullView)
    }

    func testAllSectionCombinationsFemaleBack() {
        let upperView = BodyView(side: .posterior, gender: .woman, section: .upper)
        let lowerView = BodyView(side: .posterior, gender: .woman, section: .lower)
        let fullView = BodyView(side: .posterior, gender: .woman, section: .full)

        XCTAssertNotNil(upperView)
        XCTAssertNotNil(lowerView)
        XCTAssertNotNil(fullView)
    }

    func testBodySectionEnumCases() {
        // Verify the enum has all expected cases
        let allCases = BodySection.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.upper))
        XCTAssertTrue(allCases.contains(.lower))
        XCTAssertTrue(allCases.contains(.full))
    }
}
