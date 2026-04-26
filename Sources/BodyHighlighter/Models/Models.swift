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
            return targetSlug.groups.contains(group)
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

public enum BodyGender: String, Sendable, CaseIterable, Equatable, Codable {
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

public enum BodyPartSlug: String, Sendable, Codable, CaseIterable, Equatable, BodyPartStringConvertible {
    // skeletal & other non-muscles
    case hair, head, neck, hands, ankles, knees, feet

    // anterior and posterior
    case trapezius_upper, vastus_lateralis

    // anterior-only
    case biceps_brachii, brachialis, // arms
         sternocleidomastoid, // neck
         pectoralis_major, serratus_anterior, // chest
         brachioradialis, flexor_carpi_radialis, palmaris_longus, // forearms
         rectus_abdominis, obliques, // abs
         pectineus, sartorius, adductor_longus, // adductors
         rectus_femoris, vastus_medialis, // quads
         popliteus, // knee, technically in the back, but mapped in front/below knee
         tibialis_anterior, fibularis // calves

    // posterior-only
    case deltoid_posterior,
         infraspinatus, teres_major, trapezius, // upper back
         triceps_brachii_long, triceps_brachii_lateral, triceps_brachii_medial, // triceps
         anconeus, extensor_carpi_ulnaris, extensor_digitorum, extensor_carpi_radialis, // forearms
         latissimus_dorsi, erector_spinae, serratus_posterior_inferior, // lower back
         gluteus_maximus, gluteus_medius, // glutes
         adductor_magnus, // adductor
         semimembranosus, semitendinosus, biceps_femoris, // hamstring
         gastrocnemius_lateral, gastrocnemius_medial, soleus // calves

    // woman-only
    case pronator_teres, deltoid_lateral, deltoid_anterior

    // man-only, anterior-only
    case deltoids

    // unmapped
    case pectoralis_minor, quadratus_lumborum, iliopsoas,
         transverse_abdominis, // inner core
         rhomboid_major, rhomboid_minor,  // upper back
         supraspinatus, teres_minor, subscapularis, // rotator cuff
         gracilis, adductor_brevis, vastus_intermedius, gluteus_minimus, tibialis_posterior, // legs
         flexor_carpi_ulnaris, flexor_digitorum_superficialis, flexor_digitorum_profundus, flexor_policis_longus, // forearm front
         extensor_digiti_minimi, extensor_policis, // forearm rear
         tensor_fasciae_latae // hip

    public var groups: [BodyPartGroup] {
        return BodyPartGroup.allCases.filter {
            $0.slugs.contains(self)
        }
    }

    public var uniqueGroups: [BodyPartGroup] {
        return BodyPartGroup.uniqueGroups.filter {
            $0.uniqueSlugs.contains(self)
        }
    }

//    public static func testUniques() {
//        BodyPartSlug.allCases.forEach {
//            print($0, $0.uniqueGroups())
//        }
//    }

    public var section: (BodySide, BodySection)? {
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

    public var sameSection: Set<BodyPartSlug> {
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

    public var slugs: Set<BodyPartSlug> { [self] }
}

public enum BodyPartGroup: String, Sendable, Codable, CaseIterable, Equatable, BodyPartStringConvertible {
    case skeletal_etc = "skeletal+"

    // both
    case neck, trapezius = "traps", deltoids = "delts", triceps, forearms, adductors, calves
    case core, shoulders // workout split and in the highlight body anterior and posterior

    // anterior-only
    case quads, chest, abs, biceps, hip_flexors

    // posterior-only
    case back_upper, back_lower, glutes, hamstrings, back

    // unmapped
    case rhomboids

    // workout splits
    case upper, lower, push, pull, legs

    public var slugs: Set<BodyPartSlug> {
        return BodyPartGroups[self] ?? []
    }

    public var uniqueSlugs: Set<BodyPartSlug> {
        return BodyPartUniqueGroups[self] ?? []
    }

    public static var muscles: Set<BodyPartSlug> {
        return Set(BodyPartSlug.allCases).subtracting(BodyPartGroups[BodyPartGroup.skeletal_etc]!)
    }

    // non-overlapping muscle groups
    public static var uniqueGroups: Set<BodyPartGroup> {
        return Set(BodyPartUniqueGroups.keys)
    }
}

// Functional anatomically correct mappings
public let BodyPartGroups: [BodyPartGroup: Set<BodyPartSlug>] = [
    .skeletal_etc: [.hair, .head, .neck, .hands, .ankles, .knees, .feet],
    .neck: [.sternocleidomastoid, .trapezius_upper],
    .shoulders: [.deltoid_posterior, .deltoid_lateral, .deltoid_anterior, .deltoids,
                 .infraspinatus, .supraspinatus, .teres_minor, .subscapularis, .teres_major],
    .chest: [.pectoralis_major, .pectoralis_minor, .serratus_anterior],
    .back_upper: [.latissimus_dorsi, .trapezius, .trapezius_upper,
                  .teres_major, .rhomboid_major, .rhomboid_minor,
                  .infraspinatus, .teres_minor, .supraspinatus, .subscapularis,
                  .serratus_anterior],
    .back_lower: [.erector_spinae, .serratus_posterior_inferior, .quadratus_lumborum],
    .back: [.latissimus_dorsi, .trapezius, .trapezius_upper, .teres_major,
            .rhomboid_major, .rhomboid_minor, .infraspinatus, .teres_minor,
            .supraspinatus, .subscapularis, .erector_spinae,
            .serratus_posterior_inferior, .quadratus_lumborum, .serratus_anterior],
    .core: [.rectus_abdominis, .obliques, .transverse_abdominis,
            .erector_spinae, .quadratus_lumborum, .iliopsoas],
    .abs: [.rectus_abdominis, .obliques, .transverse_abdominis],
    .biceps: [.biceps_brachii, .brachialis, .brachioradialis],
    .triceps: [.triceps_brachii_long, .triceps_brachii_medial, .triceps_brachii_lateral, .anconeus],
    .forearms: [.brachioradialis, .flexor_carpi_radialis, .palmaris_longus,
                .flexor_carpi_ulnaris, .flexor_digitorum_superficialis,
                .flexor_digitorum_profundus, .flexor_policis_longus, .pronator_teres,
                .extensor_carpi_ulnaris, .extensor_digitorum, .extensor_carpi_radialis,
                .extensor_digiti_minimi, .extensor_policis, .anconeus],
    .hip_flexors: [.iliopsoas, .tensor_fasciae_latae, .sartorius,
                   .rectus_femoris, .pectineus],
    .quads: [.rectus_femoris, .vastus_lateralis, .vastus_medialis, .vastus_intermedius],
    .adductors: [.pectineus, .adductor_longus, .adductor_brevis, .adductor_magnus,
                 .gracilis, .sartorius],
    .glutes: [.gluteus_maximus, .gluteus_medius, .gluteus_minimus, .tensor_fasciae_latae],
    .hamstrings: [.semimembranosus, .semitendinosus, .biceps_femoris,
                  .adductor_magnus, .gracilis, .popliteus],
    .calves: [.gastrocnemius_lateral, .gastrocnemius_medial, .soleus,
              .tibialis_anterior, .tibialis_posterior, .fibularis, .popliteus],
    .push: [.pectoralis_major, .pectoralis_minor, .serratus_anterior, .deltoid_anterior, .deltoid_lateral, .triceps_brachii_long, .triceps_brachii_lateral, .triceps_brachii_medial, .anconeus
    ],
    .pull: [.latissimus_dorsi, .trapezius, .trapezius_upper, .rhomboid_major, .rhomboid_minor, .teres_major, .infraspinatus, .deltoid_posterior, .deltoid_lateral, .biceps_brachii, .brachialis, .brachioradialis, .flexor_carpi_radialis, .flexor_carpi_ulnaris, .palmaris_longus
    ],
    .legs: [.sartorius, .pectineus, .adductor_longus, .adductor_magnus, .adductor_brevis, .gracilis, .rectus_femoris, .vastus_lateralis, .vastus_medialis, .vastus_intermedius, .semimembranosus, .semitendinosus, .biceps_femoris, .gastrocnemius_lateral, .gastrocnemius_medial, .soleus, .tibialis_anterior, .fibularis],
    .upper: [
        // neck
        .sternocleidomastoid,
        // shoulders
        .deltoid_anterior, .deltoid_lateral, .deltoid_posterior, .deltoids,
        .supraspinatus, .infraspinatus, .teres_minor, .subscapularis,
        // chest
        .pectoralis_major, .pectoralis_minor, .serratus_anterior,
        // back
        .trapezius, .trapezius_upper, .latissimus_dorsi,
        .rhomboid_major, .rhomboid_minor,
        .teres_major, .serratus_posterior_inferior,
        // arms
        .biceps_brachii, .brachialis,
        .triceps_brachii_long, .triceps_brachii_lateral, .triceps_brachii_medial, .anconeus,
        // forearms
        .brachioradialis, .flexor_carpi_radialis, .palmaris_longus, .flexor_carpi_ulnaris,
        .flexor_digitorum_superficialis, .flexor_digitorum_profundus, .flexor_policis_longus,
        .pronator_teres,
        .extensor_carpi_radialis, .extensor_carpi_ulnaris, .extensor_digitorum,
        .extensor_digiti_minimi, .extensor_policis,
    ],
    .lower: [
        // hip flexors
        .iliopsoas, .sartorius, .pectineus,
        // adductors
        .adductor_longus, .adductor_brevis, .adductor_magnus, .gracilis,
        // glutes
        .gluteus_maximus, .gluteus_medius, .gluteus_minimus,
        // quads
        .rectus_femoris, .vastus_lateralis, .vastus_medialis, .vastus_intermedius,
        // hamstrings
        .biceps_femoris, .semimembranosus, .semitendinosus,
        // calves
        .gastrocnemius_lateral, .gastrocnemius_medial, .soleus,
        .tibialis_anterior, .tibialis_posterior, .fibularis,
        // knee
        .popliteus
    ]
]

// No overlaps between groups for accurate accounting without double-counting
// Decisions were made. Make your own if you need different choices.
public let BodyPartUniqueGroups: [BodyPartGroup: Set<BodyPartSlug>] = [
    .skeletal_etc: [.hair, .head, .neck, .hands, .ankles, .knees, .feet],
    .neck: [.sternocleidomastoid],
    .shoulders: [.deltoid_posterior, .deltoid_lateral, .deltoid_anterior, .deltoids,
                 .infraspinatus, .supraspinatus, .teres_minor, .subscapularis],
    .chest: [.pectoralis_major, .pectoralis_minor, .serratus_anterior],
    .back_upper: [.latissimus_dorsi, .trapezius, .trapezius_upper, .teres_major,
                  .rhomboid_major, .rhomboid_minor],
    .back_lower: [.erector_spinae, .serratus_posterior_inferior, .quadratus_lumborum],
    .abs: [.rectus_abdominis, .obliques, .transverse_abdominis],
    .biceps: [.biceps_brachii, .brachialis],
    .triceps: [.triceps_brachii_long, .triceps_brachii_medial, .triceps_brachii_lateral, .anconeus],
    .forearms: [.brachioradialis, .flexor_carpi_radialis, .palmaris_longus,
                .flexor_carpi_ulnaris, .flexor_digitorum_superficialis,
                .flexor_digitorum_profundus, .flexor_policis_longus, .pronator_teres,
                .extensor_carpi_ulnaris, .extensor_digitorum, .extensor_carpi_radialis,
                .extensor_digiti_minimi, .extensor_policis],
    .hip_flexors: [.iliopsoas, .tensor_fasciae_latae, .sartorius, .rectus_femoris],
    .quads: [.vastus_lateralis, .vastus_medialis, .vastus_intermedius],
    .adductors: [.pectineus, .adductor_longus, .adductor_brevis, .adductor_magnus, .gracilis],
    .glutes: [.gluteus_maximus, .gluteus_medius, .gluteus_minimus],
    .hamstrings: [.semimembranosus, .semitendinosus, .biceps_femoris, .popliteus],
    .calves: [.gastrocnemius_lateral, .gastrocnemius_medial, .soleus,
              .tibialis_anterior, .tibialis_posterior, .fibularis],
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
