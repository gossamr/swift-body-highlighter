//
//  BodyHighlighterTests.swift
//  BodyHighlighterTests
//
//  Created by gossamr on 12/16/25.
//

import Foundation
import SwiftUI
import Testing
@testable import BodyHighlighter

// MARK: - Color

@Suite("Color")
struct ColorTests {
    @Test("3-digit hex parses")
    func hex3Digit() {
        _ = Color(hex: "abc")
    }

    @Test("6-digit hex parses")
    func hex6Digit() {
        _ = Color(hex: "#3f3f3f")
    }

    @Test("8-digit ARGB hex parses")
    func hex8Digit() {
        _ = Color(hex: "80ff0000")
    }

    @Test("Invalid hex falls back without crashing")
    func invalidHexFallback() {
        _ = Color(hex: "invalid")
    }
}

// MARK: - BodyPartData

@Suite("BodyPartData")
struct BodyPartDataTests {
    @Test("init(slug:side:) populates id and side")
    func slugInitPopulatesIdAndSide() {
        let data = BodyPartData(slug: .pectoralis_major, side: .left)
        #expect(data.id == "pectoralis_majorleft")
        #expect(data.slug == .pectoralis_major)
        #expect(data.side == .left)
    }

    @Test("init carries explicit style")
    func slugInitCarriesStyle() {
        let style = BodyPartStyle(fill: .red, stroke: .blue, strokeWidth: 2)
        let data = BodyPartData(slug: .biceps_brachii, style: style)
        #expect(data.style?.fill == .red)
        #expect(data.style?.stroke == .blue)
        #expect(data.style?.strokeWidth == 2)
    }

    @Test("init carries explicit color")
    func slugInitCarriesColor() {
        let data = BodyPartData(slug: .triceps_brachii_long, color: .green)
        #expect(data.color == .green)
    }

    @Test("init carries explicit intensity")
    func slugInitCarriesIntensity() {
        let data = BodyPartData(slug: .deltoids, intensity: 1)
        #expect(data.intensity == 1)
    }

    @Test("matches(_:) hits when slug equal")
    func matchesSlug() {
        let data = BodyPartData(slug: .biceps_brachii)
        #expect(data.matches(.biceps_brachii))
        #expect(!data.matches(.triceps_brachii_long))
    }

    @Test("matches(_:) hits any slug in the group")
    func matchesGroupMembers() {
        let data = BodyPartData(group: .biceps)
        #expect(data.matches(.biceps_brachii))
        #expect(data.matches(.brachialis))
        #expect(!data.matches(.rectus_abdominis))
    }

    @Test("matches(_:) misses unrelated slugs")
    func matchesNone() {
        let data = BodyPartData(slug: .neck, side: .left)
        #expect(!data.matches(.biceps_brachii))
    }

    // MARK: init(part:) convenience

    @Test("init(part:) slug sided matches legacy init field-for-field")
    func fromPartSlugSidedMatchesLegacy() {
        let fromPart = BodyPartData(part: AnyBodyPart(.pectoralis_major, side: .left))
        let legacy = BodyPartData(slug: .pectoralis_major, side: .left)
        #expect(fromPart == legacy)
    }

    @Test("init(part:) slug unsided matches legacy init")
    func fromPartSlugUnsidedMatchesLegacy() {
        let fromPart = BodyPartData(part: AnyBodyPart(.pectoralis_major))
        let legacy = BodyPartData(slug: .pectoralis_major)
        #expect(fromPart == legacy)
        #expect(fromPart.side == nil)
    }

    @Test("init(part:) group matches legacy init")
    func fromPartGroupMatchesLegacy() {
        let fromPart = BodyPartData(part: AnyBodyPart(.biceps, side: .right))
        let legacy = BodyPartData(group: .biceps, side: .right)
        #expect(fromPart == legacy)
    }

    @Test("init(part:) id is byte-identical to legacy: slug+sided")
    func fromPartIdSlugSided() {
        let fromPart = BodyPartData(part: AnyBodyPart(.pectoralis_major, side: .left))
        #expect(fromPart.id == "pectoralis_majorleft")
    }

    @Test("init(part:) id is byte-identical to legacy: slug+unsided")
    func fromPartIdSlugUnsided() {
        let fromPart = BodyPartData(part: AnyBodyPart(.pectoralis_major))
        #expect(fromPart.id == "pectoralis_major")
    }

    @Test("init(part:) id is byte-identical to legacy: group+sided")
    func fromPartIdGroupSided() {
        let fromPart = BodyPartData(part: AnyBodyPart(.biceps, side: .right))
        #expect(fromPart.id == "bicepsright")
    }

    @Test("init(part:) id is byte-identical to legacy: group+unsided")
    func fromPartIdGroupUnsided() {
        let fromPart = BodyPartData(part: AnyBodyPart(.biceps))
        #expect(fromPart.id == "biceps")
    }

    @Test("init(part:) does not leak the AnyBodyPart `|` separator into id")
    func fromPartIdDoesNotLeakSeparator() {
        // BodyPartData.id is a separate contract from AnyBodyPart.rawValue.
        let fromPart = BodyPartData(part: AnyBodyPart(.biceps, side: .right))
        #expect(!fromPart.id.contains("|"))
    }

    @Test("init(part:) carries style/color/intensity/override")
    func fromPartCarriesOptionalArgs() {
        let style = BodyPartStyle(fill: .red)
        let fromPart = BodyPartData(
            part: AnyBodyPart(.biceps_brachii, side: .left),
            intensity: 2,
            color: .green,
            style: style,
            override: true
        )
        #expect(fromPart.style?.fill == .red)
        #expect(fromPart.color == .green)
        #expect(fromPart.intensity == 2)
        #expect(fromPart.override)
    }

    @Test("init(part:) optional args default to nil")
    func fromPartDefaultsAreNil() {
        let fromPart = BodyPartData(part: AnyBodyPart(.biceps_brachii))
        #expect(fromPart.style == nil)
        #expect(fromPart.color == nil)
        #expect(fromPart.intensity == nil)
        #expect(!fromPart.override)
    }
}

// MARK: - BodyData integrity

@Suite("BodyData section sets")
struct BodyDataIntegrityTests {
    @Test("anterior upper contains chest, abs, biceps")
    func anteriorUpperContents() {
        let parts = BodyData.bodyAnteriorUpper
        #expect(!parts.isEmpty)
        #expect(parts.contains(.pectoralis_major))
        #expect(parts.contains(.rectus_abdominis))
        #expect(parts.contains(.biceps_brachii))
    }

    @Test("anterior lower contains quads and calves")
    func anteriorLowerContents() {
        let parts = BodyData.bodyAnteriorLower
        #expect(!parts.isEmpty)
        #expect(parts.contains(.rectus_femoris))
        #expect(parts.contains(.tibialis_anterior))
    }

    @Test("posterior upper contains trapezius and deltoids")
    func posteriorUpperContents() {
        let parts = BodyData.bodyPosteriorUpper
        #expect(!parts.isEmpty)
        #expect(parts.contains(.trapezius))
        #expect(parts.contains(.deltoid_posterior))
    }

    @Test("posterior lower contains glutes and hamstrings")
    func posteriorLowerContents() {
        let parts = BodyData.bodyPosteriorLower
        #expect(!parts.isEmpty)
        #expect(parts.contains(.gluteus_maximus))
        #expect(parts.contains(.biceps_femoris))
    }

    @Test("BodyPaths and BodyPart accept and round-trip path data")
    func bodyPathsAndPartShape() {
        let paths = BodyPaths(common: ["M 0 0 L 10 10"], left: ["M 20 20 L 30 30"], right: ["M 40 40 L 50 50"])
        #expect(paths.common.count == 1)
        #expect(paths.left.count == 1)
        #expect(paths.right.count == 1)

        let part = BodyPart(slug: .biceps_brachii, paths: paths)
        #expect(part.slug == .biceps_brachii)
        #expect(part.paths == paths)
    }
}

// MARK: - BodyView

@Suite("BodyView")
struct BodyViewTests {
    @Test("init accepts anterior + man")
    func anteriorMan() {
        _ = BodyView(side: .anterior, gender: .man)
    }

    @Test("init accepts posterior + man")
    func posteriorMan() {
        _ = BodyView(side: .posterior, gender: .man)
    }

    @Test("init accepts anterior + woman")
    func anteriorWoman() {
        _ = BodyView(side: .anterior, gender: .woman)
    }

    @Test("init accepts posterior + woman")
    func posteriorWoman() {
        _ = BodyView(side: .posterior, gender: .woman)
    }

    @Test("init accepts custom data")
    func withCustomData() {
        let customData = [
            BodyPartData(slug: .pectoralis_major, color: .red, intensity: 2),
            BodyPartData(slug: .rectus_abdominis, color: .blue),
        ]
        _ = BodyView(data: customData, side: .anterior, gender: .man)
    }

    @Test("init accepts disabledParts")
    func withDisabledParts() {
        _ = BodyView(side: .anterior, gender: .man, disabledParts: [.pectoralis_major, .rectus_abdominis])
    }

    @Test("init accepts hiddenParts")
    func withHiddenParts() {
        _ = BodyView(side: .anterior, gender: .man, hiddenParts: [.biceps_brachii, .triceps_brachii_long])
    }

    @Test("init accepts custom intensity colors")
    func withCustomColors() {
        _ = BodyView(side: .anterior, gender: .man, colors: [.red, .blue, .green])
    }

    @Test("init accepts non-unit scale")
    func withScale() {
        _ = BodyView(side: .anterior, gender: .man, scale: 2.0)
    }

    @Test("section: upper, lower, full all initializable", arguments: [BodySection.upper, .lower, .full])
    func sectionInit(section: BodySection) {
        _ = BodyView(side: .anterior, gender: .man, section: section)
    }

    @Test("section combinations across genders and orientations",
          arguments: [BodyGender.man, .woman],
          [BodySide.anterior, .posterior])
    func allSectionCombinations(gender: BodyGender, view: BodySide) {
        _ = BodyView(side: view, gender: gender, section: .upper)
        _ = BodyView(side: view, gender: gender, section: .lower)
        _ = BodyView(side: view, gender: gender, section: .full)
    }

    @Test("BodySection has three cases")
    func sectionEnumCases() {
        let all = BodySection.allCases
        #expect(all.count == 3)
        #expect(all.contains(.upper))
        #expect(all.contains(.lower))
        #expect(all.contains(.full))
    }

    @Test("init accepts SideConvention.screen")
    func acceptsScreenConvention() {
        _ = BodyView(side: .anterior, gender: .man, sideConvention: .screen)
    }

    @Test("init accepts SideConvention.body")
    func acceptsBodyConvention() {
        _ = BodyView(side: .anterior, gender: .man, sideConvention: .body)
    }

    @Test("init defaults SideConvention to .screen (callers without the arg keep compiling)")
    func defaultsToScreenConvention() {
        _ = BodyView(side: .anterior, gender: .man)
    }
}

// MARK: - AnyBodyPart

@Suite("AnyBodyPart")
struct AnyBodyPartTests {

    @Suite("Side & equality")
    struct Side {
        @Test("default side is nil for slug and group")
        func defaultSideIsNil() {
            #expect(AnyBodyPart(.biceps_brachii).side == nil)
            #expect(AnyBodyPart(.biceps).side == nil)
        }

        @Test("sided value is not equal to unsided")
        func sidedNotEqualUnsided() {
            #expect(AnyBodyPart(.biceps_brachii) != AnyBodyPart(.biceps_brachii, side: .left))
        }

        @Test("left and right are distinct identities")
        func leftNotEqualRight() {
            #expect(AnyBodyPart(.biceps_brachii, side: .left) != AnyBodyPart(.biceps_brachii, side: .right))
        }

        @Test("equal sided values hash equally")
        func hashConsistency() {
            let a = AnyBodyPart(.biceps_brachii, side: .left)
            let b = AnyBodyPart(.biceps_brachii, side: .left)
            #expect(a == b)
            #expect(a.hashValue == b.hashValue)
        }

        @Test("Set retains both sided and unsided members of the same region")
        func setRetainsBothMembers() {
            let set: Set<AnyBodyPart> = [
                AnyBodyPart(.biceps_brachii),
                AnyBodyPart(.biceps_brachii, side: .left),
            ]
            #expect(set.count == 2)
        }
    }

    @Suite("Representation accessors")
    struct Representation {
        @Test("group accessor returns underlying group; slug returns nil")
        func groupAccessor() {
            #expect(AnyBodyPart(.biceps).group == .biceps)
            #expect(AnyBodyPart(.biceps_brachii).group == nil)
        }

        @Test("slug accessor returns underlying slug; group returns nil")
        func slugAccessor() {
            #expect(AnyBodyPart(.biceps_brachii).slug == .biceps_brachii)
            #expect(AnyBodyPart(.biceps).slug == nil)
        }

        @Test("group and slug accessors strip side (consumers read .side separately)")
        func accessorsIgnoreSide() {
            #expect(AnyBodyPart(.biceps, side: .left).group == .biceps)
            #expect(AnyBodyPart(.biceps_brachii, side: .right).slug == .biceps_brachii)
        }
    }

    @Suite("rawValue")
    struct RawValue {
        @Test("unsided slug rawValue is byte-identical to the region rawValue")
        func unsidedSlugByteIdentical() {
            #expect(AnyBodyPart(.biceps_brachii).rawValue == BodyPartSlug.biceps_brachii.rawValue)
        }

        @Test("unsided group rawValue is byte-identical to the region rawValue")
        func unsidedGroupByteIdentical() {
            #expect(AnyBodyPart(.biceps).rawValue == BodyPartGroup.biceps.rawValue)
        }

        @Test("sided slug carries `|<side>` suffix")
        func sidedSlugSuffix() {
            #expect(AnyBodyPart(.biceps_brachii, side: .left).rawValue == "biceps_brachii|left")
        }

        @Test("sided group carries `|<side>` suffix")
        func sidedGroupSuffix() {
            #expect(AnyBodyPart(.biceps, side: .right).rawValue == "biceps|right")
        }

        @Test("rawValue round-trips through init?(rawValue:)",
              arguments: [
                AnyBodyPart(.biceps_brachii),
                AnyBodyPart(.biceps_brachii, side: .left),
                AnyBodyPart(.biceps),
                AnyBodyPart(.biceps, side: .right),
              ])
        func rawValueRoundTrip(value: AnyBodyPart) {
            #expect(AnyBodyPart(rawValue: value.rawValue) == value)
        }

        @Test("region-only string decodes to side == nil")
        func regionOnlyDecodesUnsided() throws {
            let parsed = try #require(AnyBodyPart(rawValue: "biceps_brachii"))
            #expect(parsed.side == nil)
        }

        @Test("malformed rawValue returns nil",
              arguments: [
                "biceps_brachii|",       // empty side
                "|left",                 // empty region
                "|",                     // both empty
                "biceps_brachii|sideways", // unknown side
                "not_a_part|left",       // unknown region
              ])
        func malformedReturnsNil(raw: String) {
            #expect(AnyBodyPart(rawValue: raw) == nil)
        }

        @Test("the side separator does not appear in any existing region rawValue")
        func separatorDoesNotCollide() {
            for slug in BodyPartSlug.allCases {
                #expect(!slug.rawValue.contains("|"), "BodyPartSlug.\(slug) rawValue contains separator")
            }
            for group in BodyPartGroup.allCases {
                #expect(!group.rawValue.contains("|"), "BodyPartGroup.\(group) rawValue contains separator")
            }
        }
    }

    @Suite("Codable")
    struct CodableShape {
        @Test("unsided JSON omits the side key")
        func unsidedOmitsSideKey() throws {
            let encoded = try JSONEncoder().encode(AnyBodyPart(.biceps_brachii))
            let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            #expect(json?["region"] as? String == "biceps_brachii")
            #expect(json?["side"] == nil)
        }

        @Test("sided JSON includes the side key")
        func sidedIncludesSideKey() throws {
            let encoded = try JSONEncoder().encode(AnyBodyPart(.biceps_brachii, side: .left))
            let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
            #expect(json?["region"] as? String == "biceps_brachii")
            #expect(json?["side"] as? String == "left")
        }

        @Test("sided value round-trips through Codable")
        func sidedRoundTrip() throws {
            let original = AnyBodyPart(.biceps_brachii, side: .right)
            let decoded = try JSONDecoder().decode(
                AnyBodyPart.self,
                from: JSONEncoder().encode(original)
            )
            #expect(decoded == original)
            #expect(decoded.side == .right)
        }

        @Test("Set<AnyBodyPart> with mixed sided/unsided members round-trips")
        func setRoundTripMixed() throws {
            let original: Set<AnyBodyPart> = [
                AnyBodyPart(.biceps_brachii),
                AnyBodyPart(.biceps_brachii, side: .left),
                AnyBodyPart(.biceps, side: .right),
            ]
            let decoded = try JSONDecoder().decode(
                Set<AnyBodyPart>.self,
                from: JSONEncoder().encode(original)
            )
            #expect(decoded == original)
        }

        @Test("decode throws when region key is missing")
        func throwsOnMissingRegion() {
            let json = Data("{\"side\":\"left\"}".utf8)
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(AnyBodyPart.self, from: json)
            }
        }

        @Test("decode throws when region value is unknown")
        func throwsOnUnknownRegion() {
            let json = Data("{\"region\":\"not_a_real_part\"}".utf8)
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(AnyBodyPart.self, from: json)
            }
        }

        @Test("decode throws when side value is unknown")
        func throwsOnUnknownSide() {
            let json = Data("{\"region\":\"biceps_brachii\",\"side\":\"sideways\"}".utf8)
            #expect(throws: (any Error).self) {
                try JSONDecoder().decode(AnyBodyPart.self, from: json)
            }
        }
    }

    @Suite("Display")
    struct Display {
        @Test("qualifiedDisplayName on unsided value matches displayName")
        func qualifiedUnsidedMatchesDisplay() {
            let part = AnyBodyPart(.biceps_brachii)
            #expect(part.qualifiedDisplayName == part.displayName)
        }

        @Test("qualifiedDisplayName suffixes ` (L)` for .left")
        func qualifiedLeftSuffix() {
            let part = AnyBodyPart(.biceps_brachii, side: .left)
            #expect(part.qualifiedDisplayName.hasSuffix(" (L)"))
            #expect(part.qualifiedDisplayName.hasPrefix(part.displayName))
        }

        @Test("qualifiedDisplayName suffixes ` (R)` for .right on group")
        func qualifiedRightSuffixGroup() {
            let part = AnyBodyPart(.biceps, side: .right)
            #expect(part.qualifiedDisplayName.hasSuffix(" (R)"))
        }

        @Test("displayName does not leak the separator or side string")
        func displayNameNoLeakage() {
            // Spec §3.6: `displayName` returns the region name only. Guards against dynamic
            // dispatch routing to the protocol-extension default (which builds from rawValue).
            let part = AnyBodyPart(.biceps_brachii, side: .left)
            #expect(!part.displayName.contains("|"))
            #expect(!part.displayName.lowercased().contains("left"))
            #expect(part.displayName == AnyBodyPart(.biceps_brachii).displayName)
        }

        @Test("slugs does not propagate side")
        func slugsIgnoresSide() {
            // Spec §2.1: slugs() signature is unchanged; consumers must pair side back themselves.
            #expect(AnyBodyPart(.biceps, side: .left).slugs == AnyBodyPart(.biceps).slugs)
            #expect(AnyBodyPart(.biceps_brachii, side: .right).slugs == AnyBodyPart(.biceps_brachii).slugs)
        }
    }

    @Suite("Existential init (`init?(_ identifier:)`)")
    struct ExistentialInit {
        // Regression: this path previously infinite-recursed through
        // `resolve → resolveRegion → AnyBodyPart(slug)` when overload resolution picked the
        // existential init at the resolveRegion call site.

        @Test("from a BodyPartSlug existential")
        func fromSlug() {
            let identifier: any BodyPartStringConvertible = BodyPartSlug.biceps_brachii
            let part = AnyBodyPart(identifier)
            #expect(part == AnyBodyPart(.biceps_brachii))
            #expect(part?.side == nil)
        }

        @Test("from a BodyPartGroup existential")
        func fromGroup() {
            let identifier: any BodyPartStringConvertible = BodyPartGroup.biceps
            let part = AnyBodyPart(identifier)
            #expect(part == AnyBodyPart(.biceps))
        }

        @Test("from a sided AnyBodyPart preserves side via rawValue parsing")
        func fromSidedAnyBodyPartPreservesSide() {
            let original = AnyBodyPart(.biceps_brachii, side: .right)
            let viaIdentifier = AnyBodyPart(original as any BodyPartStringConvertible)
            #expect(viaIdentifier == original)
            #expect(viaIdentifier?.side == .right)
        }

        @Test("returns nil for unknown rawValue")
        func returnsNilForUnknown() {
            struct Unknown: BodyPartStringConvertible {
                let rawValue = "definitely_not_a_real_body_part"
                let slugs: Set<BodyPartSlug> = []
            }
            #expect(AnyBodyPart(Unknown()) == nil)
        }
    }
}

// MARK: - SideConvention

@Suite("SideConvention")
struct SideConventionTests {
    struct Case: Sendable {
        let convention: SideConvention
        let view: BodySide
        let screenSide: LateralSide
        let expected: LateralSide
    }

    @Test("resolveBodySide identity matrix",
          arguments: [
            Case(convention: .screen, view: .anterior, screenSide: .left, expected: .left),
            Case(convention: .screen, view: .anterior, screenSide: .right, expected: .right),
            Case(convention: .screen, view: .posterior, screenSide: .left, expected: .left),
            Case(convention: .screen, view: .posterior, screenSide: .right, expected: .right),
            // Under `.body`, anterior flips (subject's anatomical-left appears on screen-right
            // when viewed face-on); posterior coincides with screen.
            Case(convention: .body, view: .anterior, screenSide: .left, expected: .right),
            Case(convention: .body, view: .anterior, screenSide: .right, expected: .left),
            Case(convention: .body, view: .posterior, screenSide: .left, expected: .left),
            Case(convention: .body, view: .posterior, screenSide: .right, expected: .right),
          ])
    func resolveBodySideMatrix(_ c: Case) {
        #expect(c.convention.resolveBodySide(c.screenSide, in: c.view) == c.expected)
    }
}

// MARK: - BodyPartSlug

@Suite("BodyPartSlug accessors")
struct BodyPartSlugTests {
    @Test("slugs returns [self]")
    func slugsIsSelf() {
        #expect(BodyPartSlug.biceps_brachii.slugs == [.biceps_brachii])
        #expect(BodyPartSlug.hair.slugs == [.hair])
    }

    struct SectionCase: Sendable {
        let slug: BodyPartSlug
        let side: BodySide
        let section: BodySection
    }

    @Test("section for known slugs",
          arguments: [
            SectionCase(slug: .pectoralis_major, side: .anterior, section: .upper),
            SectionCase(slug: .rectus_femoris, side: .anterior, section: .lower),
            SectionCase(slug: .trapezius, side: .posterior, section: .upper),
            SectionCase(slug: .gluteus_maximus, side: .posterior, section: .lower),
          ])
    func sectionForKnownSlugs(_ c: SectionCase) {
        let section = c.slug.section
        #expect(section?.0 == c.side)
        #expect(section?.1 == c.section)
    }

    @Test("section is nil for slugs absent from every section set")
    func sectionNilForUnmapped() {
        // `.iliopsoas` is intentionally not present in any of the four section sets.
        #expect(BodyPartSlug.iliopsoas.section == nil)
    }

    @Test("sameSection returns the containing section set",
          arguments: zip(
            [BodyPartSlug.pectoralis_major, .rectus_femoris, .trapezius, .gluteus_maximus],
            [BodyData.bodyAnteriorUpper, BodyData.bodyAnteriorLower,
             BodyData.bodyPosteriorUpper, BodyData.bodyPosteriorLower]
          ))
    func sameSectionReturnsContainingSet(slug: BodyPartSlug, expected: Set<BodyPartSlug>) {
        #expect(slug.sameSection == expected)
    }

    @Test("sameSection is empty for unmapped slugs")
    func sameSectionEmptyForUnmapped() {
        #expect(BodyPartSlug.iliopsoas.sameSection.isEmpty)
    }

    @Test("uniqueGroups resolves to the owning unique-group key",
          arguments: zip(
            // `.biceps_brachii` is in .biceps + .pull + .upper in BodyPartGroups, but only .biceps
            // is a unique-group key. `.brachioradialis` is in .biceps.slugs and .forearms.slugs;
            // the partition routes it to .forearms only.
            [BodyPartSlug.biceps_brachii, .brachioradialis, .hair],
            [Set<BodyPartGroup>([.biceps]), [.forearms], [.skeletal_etc]]
          ))
    func uniqueGroupsResolvesToOwner(slug: BodyPartSlug, expected: Set<BodyPartGroup>) {
        #expect(Set(slug.uniqueGroups) == expected)
    }

    @Test("non-overlap invariant: every slug appears in at most one unique group",
          arguments: BodyPartSlug.allCases)
    func uniqueGroupsNonOverlap(slug: BodyPartSlug) {
        // Guards `BodyPartUniqueGroups` against future edits that introduce overlap.
        #expect(
            slug.uniqueGroups.count <= 1,
            "BodyPartSlug.\(slug) appears in multiple unique groups: \(slug.uniqueGroups)"
        )
    }
}

// MARK: - BodyPartGroup

@Suite("BodyPartGroup accessors")
struct BodyPartGroupTests {
    @Test("uniqueSlugs is a curated subset of slugs")
    func uniqueSlugsCuratedSubset() {
        // `.biceps.slugs` includes `.brachioradialis` for broad anatomical mapping; uniqueSlugs
        // drops it so it's accounted for exactly once (under `.forearms`).
        #expect(BodyPartGroup.biceps.uniqueSlugs == [.biceps_brachii, .brachialis])
        #expect(BodyPartGroup.biceps.slugs.contains(.brachioradialis))
        #expect(!BodyPartGroup.biceps.uniqueSlugs.contains(.brachioradialis))
    }

    @Test("uniqueSlugs is empty for workout-split groups",
          arguments: [BodyPartGroup.push, .pull, .legs, .upper, .lower])
    func uniqueSlugsEmptyForWorkoutSplits(group: BodyPartGroup) {
        #expect(group.uniqueSlugs.isEmpty)
    }

    @Test("muscles excludes skeletal slugs and includes actual muscles")
    func musclesExcludesSkeletal() {
        let muscles = BodyPartGroup.muscles
        #expect(!muscles.contains(.hair))
        #expect(!muscles.contains(.head))
        #expect(!muscles.contains(.hands))
        #expect(!muscles.contains(.feet))
        #expect(muscles.contains(.biceps_brachii))
        #expect(muscles.contains(.pectoralis_major))
        #expect(muscles.contains(.gluteus_maximus))
    }

    @Test("muscles equals allCases minus skeletal_etc")
    func musclesIsAllCasesMinusSkeletal() {
        #expect(
            BodyPartGroup.muscles ==
            Set(BodyPartSlug.allCases).subtracting(BodyPartGroup.skeletal_etc.slugs)
        )
    }

    @Test("uniqueGroups excludes workout splits and derived overlapping groups")
    func uniqueGroupsExclusions() {
        let unique = BodyPartGroup.uniqueGroups
        // Curated unique groups present.
        #expect(unique.contains(.biceps))
        #expect(unique.contains(.triceps))
        #expect(unique.contains(.skeletal_etc))
        // Workout splits are not unique groups.
        #expect(!unique.contains(.upper))
        #expect(!unique.contains(.lower))
        #expect(!unique.contains(.push))
        #expect(!unique.contains(.pull))
        #expect(!unique.contains(.legs))
        // Overlapping/derived groups (.core / .back collect from finer groups) are excluded.
        #expect(!unique.contains(.core))
        #expect(!unique.contains(.back))
    }

    @Test("uniqueGroups cover every muscle slug")
    func uniqueGroupsCoverAllMuscles() {
        // Every muscle slug must be assigned to exactly one unique group (per the partitioning
        // contract). This is the group-side dual of the slug-side non-overlap invariant.
        let unionOfUniqueSlugs = BodyPartGroup.uniqueGroups.reduce(into: Set<BodyPartSlug>()) {
            $0.formUnion($1.uniqueSlugs)
        }
        let unassigned = BodyPartGroup.muscles.subtracting(unionOfUniqueSlugs)
        #expect(unassigned.isEmpty, "Muscle slugs missing from unique-group partition: \(unassigned)")
    }
}
