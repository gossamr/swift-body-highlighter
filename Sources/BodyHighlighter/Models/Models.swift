//
//  Models.swift
//  BodyHighlighter
//
//  Created by gossamr on 12/16/25.
//

import SwiftUI

// MARK: - Body Part Styling
public struct BodyPartStyle: Equatable, Sendable {
    public let fill: Color
    public let stroke: Color
    public let strokeWidth: CGFloat

    public init(
        fill: Color = Color(hex: "#3f3f3f"),
        stroke: Color = .clear,
        strokeWidth: CGFloat = 0
    ) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
    }
}

// MARK: - User Data for Body Parts
public struct BodyPartData: Identifiable, Equatable, Sendable {
    public let id: String
    public let slug: BodyPartSlug?
    public let group: BodyPartGroup?
    public var style: BodyPartStyle?
    public var color: Color?
    public var intensity: Int?
    public let side: LateralSide?
    public let override: Bool

    public init(
        group: BodyPartGroup,
        style: BodyPartStyle? = nil,
        color: Color? = nil,
        intensity: Int? = nil,
        side: LateralSide? = nil,
        override: Bool = false
    ) {
        self.id = group.rawValue + (side?.rawValue ?? "")
        self.slug = nil
        self.group = group
        self.style = style
        self.color = color
        self.intensity = intensity
        self.side = side
        self.override = override
    }

    public init(
        slug: BodyPartSlug,
        style: BodyPartStyle? = nil,
        color: Color? = nil,
        intensity: Int? = nil,
        side: LateralSide? = nil,
        override: Bool = false
    ) {
        self.id = slug.rawValue + (side?.rawValue ?? "")
        self.slug = slug
        self.group = nil
        self.style = style
        self.color = color
        self.intensity = intensity
        self.side = side
        self.override = override
    }

    public func matches(_ targetSlug: BodyPartSlug, side targetSide: LateralSide? = nil) -> Bool {
        let sideMatches = side == nil || side == targetSide
        guard sideMatches else { return false }

        if let slug {
            return slug == targetSlug
        }

        if let group {
            return targetSlug.groups().contains(group)
        }

        return false
    }

    public mutating func setStyle(_ newStyle: BodyPartStyle) {
        self.style = newStyle
    }

    public mutating func setIntensity(_ newIntensity: Int) {
        self.intensity = newIntensity
    }

    public mutating func setColor(_ newColor: Color) {
        self.color = newColor
    }
}

// MARK: - Enums
public enum BodySide: String, Sendable, CaseIterable, Equatable {
    case anterior
    case posterior
}

public enum Gender: String, Sendable, CaseIterable, Equatable {
    case man
    case woman
}

public enum LateralSide: String, Sendable, CaseIterable, Equatable {
    case left
    case right
}

public enum BodySection: String, Sendable, CaseIterable, Equatable {
    case upper
    case lower
    case full // both upper and lower
}

public enum BodyPartSlug: String, Sendable, CaseIterable, Equatable {
    // skeletal & other non-muscles
    case hair, head, neck, hands, ankles, knees, feet

    // front and back
    case trapezius_upper, vastus_lateralis

    // front-only
    case biceps, brachialis, // arms
         sternocleidomastoid, // neck
         pectoralis_major, serratus_anterior, // chest
         brachioradialis, flexor_carpi_radialis, palmaris_longus, // forearms
         rectus_abdominus, obliques, // abs
         pectineus, sartorius, adductor_longus, // adductors
         rectus_femoris, vastus_medialis, // quads
         popliteus, // knee, technically in the back, but mapped in front/below knee
         tibialis_anterior, fibularis // calves

    // rear-only
    case deltoid_rear,
         infraspinatus, teres_major, trapezius, // upper back
         triceps_brachii_long, triceps_brachii_lateral, triceps_brachii_medial, // triceps
         anconeus, extensor_carpi_ulnaris, extensor_digitorum, extensor_carpi_radialis, // forearms
         lattisimus_dorsi, erector_spinae, serratus_posterior_inferior, // lower back
         gluteus_maximus, gluteus_medius, // glutes
         adductor_magnus, // adductor
         semimembranosus, semitendinosus, biceps_femoris, // hamstring
         gastrocnemius_lateral, gastrocnemius_medial, soleus // calves

    // woman-only
    case pronator_teres, deltoid_side, deltoid_front

    // man-only, front-only
    case deltoids

    // unmapped
    case pectoralis_minor,
         gracilis, adductor_brevis, vastus_intermedius, gluteus_minimus, tibialis_posterior, // legs
         flexor_carpi_ulnaris, flexor_digitorum_superficialis, flexor_digitorum_profundus, flexor_policis_longus, // forearm front
         extensor_digiti_minimi, extensor_policis // forearm rear

    public func groups() -> [BodyPartGroup] {
        return BodyPartGroups.keys.filter {
            $0.slugs().contains(self)
        }
    }

    public func section() -> (BodySide, BodySection)? {
        if BodyData.bodyAnteriorUpper.contains(self) {
            return (.anterior, .upper)
        } else if BodyData.bodyAnteriorLower.contains(self) {
            return (.anterior, .lower)
        } else if BodyData.bodyPosteriorUpper.contains(self) {
            return (.posterior, .upper)
        } else if BodyData.bodyPosteriorLower.contains(self) {
            return (.posterior, .lower)
        } else {
            return nil
        }
    }

    public func sameSection() -> Set<BodyPartSlug> {
        if BodyData.bodyAnteriorUpper.contains(self) {
            return BodyData.bodyAnteriorUpper
        } else if BodyData.bodyAnteriorLower.contains(self) {
            return BodyData.bodyAnteriorLower
        } else if BodyData.bodyPosteriorUpper.contains(self) {
            return BodyData.bodyPosteriorUpper
        } else if BodyData.bodyPosteriorLower.contains(self) {
            return BodyData.bodyPosteriorLower
        } else {
            return []
        }
    }
}

public enum BodyPartGroup: String, Sendable, CaseIterable, Equatable {
    case skeletal_etc

    // both
    case neck, trapezius, deltoids, arms, triceps, forearms, adductors, calves

    // front-only
    case quads, chest

    // back-only
    case upper_back, lower_back, glutes, hamstrings

    public func slugs() -> Set<BodyPartSlug> {
        return BodyPartGroups[self] ?? []
    }

    public static func muscles() -> Set<BodyPartSlug> {
        return Set(BodyPartSlug.allCases).subtracting(BodyPartGroups[BodyPartGroup.skeletal_etc]!)
    }
}

public let BodyPartGroups: [BodyPartGroup: Set<BodyPartSlug>] = [
    .skeletal_etc: [.hair, .head, .neck, .hands, .ankles, .knees, .feet],
    .neck: [.neck, .sternocleidomastoid],
    .trapezius: [.trapezius, .trapezius_upper],
    .deltoids: [.deltoid_rear, .deltoid_side, .deltoid_front, .deltoids],
    .arms: [.brachialis, .biceps, .triceps_brachii_long, .triceps_brachii_medial, .triceps_brachii_lateral],
    .triceps: [.triceps_brachii_long, .triceps_brachii_medial, .triceps_brachii_lateral],
    .forearms: [.brachioradialis, .flexor_digitorum_superficialis, .flexor_digitorum_profundus, .flexor_policis_longus, .pronator_teres, .flexor_carpi_radialis, .palmaris_longus, .flexor_carpi_ulnaris, .extensor_policis, .extensor_digitorum, .extensor_carpi_ulnaris, .extensor_digiti_minimi, .extensor_carpi_radialis, .anconeus],
    .upper_back: [.lattisimus_dorsi, .trapezius, .teres_major, .infraspinatus],
    .lower_back: [.erector_spinae, .serratus_posterior_inferior],
    .chest: [.pectoralis_major, .pectoralis_minor, .serratus_anterior],
    .glutes: [.gluteus_medius, .gluteus_maximus, .gluteus_minimus],
    .adductors: [.pectineus, .adductor_longus, .adductor_magnus, .adductor_brevis, .gracilis],
    .quads: [.rectus_femoris, .vastus_lateralis, .vastus_medialis, .vastus_intermedius],
    .hamstrings: [.semimembranosus, .semitendinosus, .biceps_femoris],
    .calves: [.gastrocnemius_lateral, .gastrocnemius_medial, .soleus]
]

// MARK: - Color Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Path Data Structure
struct BodyPaths: Equatable, Sendable {
    public let common: [Path]
    public let left: [Path]
    public let right: [Path]

    public init(common: [String] = [], left: [String] = [], right: [String] = []) {
        self.common = common.map { SVGParser.parse($0) }
        self.left = left.map { SVGParser.parse($0) }
        self.right = right.map { SVGParser.parse($0) }
    }
}

// MARK: - Body Part Definition
struct BodyPart: Equatable, Sendable {
    public let slug: BodyPartSlug
    public let paths: BodyPaths

    public init(slug: BodyPartSlug, paths: BodyPaths) {
        self.slug = slug
        self.paths = paths
    }
}
