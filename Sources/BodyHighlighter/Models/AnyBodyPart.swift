//
//  AnyBodyPart.swift
//  BodyHighlighter
//
//  Created by gossamr on 1/09/25.

import Foundation

public protocol BodyPartStringConvertible: Sendable {
    var rawValue: String { get }
    var displayName: String { get }
    var slugs: Set<BodyPartSlug> { get }
}

extension BodyPartStringConvertible {
    public var displayName: String {
        var components = self.rawValue
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }

        // Define the terms that should be wrapped in parentheses
        let suffixesToWrap = ["Posterior", "Anterior", "Lateral", "Long", "Upper", "Lower", "Medial", "Mid"]

        // Check if the last component exists and matches our list
        if components.count > 1, let last = components.last, suffixesToWrap.contains(last) {
            components[components.count - 1] = "(\(last))"
        }

        return components.joined(separator: " ")
    }
}

/// A type-erased wrapper for `BodyPartStringConvertible` types.
///
/// `AnyBodyPart` allows different body part identifiers (both `BodyPartGroup` and `BodyPartSlug`)
/// to be stored together in collections while maintaining access to their common properties.
///
/// It is designed to be the primary currency for muscle identification throughout an app,
/// providing a single, type-safe entry point for persistence, UI display, and anatomical resolution.
///
/// A value may optionally carry a `LateralSide` to distinguish e.g. "left biceps" from "right biceps"
/// as separate identities. An unset `side` preserves the historical bilateral/unspecified semantics:
/// `AnyBodyPart(.biceps_brachii)` constructs and serializes identically to before.
public struct AnyBodyPart: RawRepresentable, Hashable, Codable, BodyPartStringConvertible, Sendable {
    public init?(rawValue: String) {
        if let part = AnyBodyPart.resolve(rawValue) {
            self = part
        } else {
            return nil
        }
    }

    /// The underlying representation of the body part.
    public enum Representation: Hashable, Sendable {
        case group(BodyPartGroup)
        case slug(BodyPartSlug)
    }

    /// The stored representation.
    public let representation: Representation

    /// Optional laterality. `nil` denotes bilateral / unspecified.
    public let side: LateralSide?

    /// Separator placed between the region rawValue and the side rawValue in `AnyBodyPart.rawValue`.
    /// Chosen because no existing `BodyPartSlug` or `BodyPartGroup` rawValue contains `|`.
    private static let sideSeparator: String = "|"

    // MARK: - Initializers

    /// Creates a wrapper for a specific body part group (unsided).
    ///
    /// Kept as a distinct 1-arg overload (instead of a single `init(_:side:LateralSide? = nil)`)
    /// so that `AnyBodyPart.init` resolves as `(BodyPartGroup) -> AnyBodyPart` when used as a
    /// method reference — e.g. `[BodyPartGroup].map(AnyBodyPart.init)`. With only the 2-arg form,
    /// method-reference resolution falls back to the failable existential init and changes the
    /// element type to `AnyBodyPart?`.
    public init(_ group: BodyPartGroup) {
        self.representation = .group(group)
        self.side = nil
    }

    /// Creates a wrapper for a specific body part group, lateralized.
    public init(_ group: BodyPartGroup, side: LateralSide?) {
        self.representation = .group(group)
        self.side = side
    }

    /// Creates a wrapper for a specific body part slug (unsided). See `init(_:BodyPartGroup)`
    /// for why this is kept as a 1-arg overload distinct from the 2-arg form.
    public init(_ slug: BodyPartSlug) {
        self.representation = .slug(slug)
        self.side = nil
    }

    /// Creates a wrapper for a specific body part slug, lateralized.
    public init(_ slug: BodyPartSlug, side: LateralSide?) {
        self.representation = .slug(slug)
        self.side = side
    }

    /// Attempts to create a wrapper from any `BodyPartStringConvertible` identifier.
    ///
    /// Resolution goes through the side-aware parser, so passing an `AnyBodyPart`'s rawValue
    /// round-trips its side. Identifiers whose rawValue is region-only (the typical case for
    /// `BodyPartGroup` / `BodyPartSlug`) resolve to `side == nil`.
    public init?(_ identifier: any BodyPartStringConvertible) {
        if let part = AnyBodyPart.resolve(identifier.rawValue) {
            self = part
        } else {
            return nil
        }
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case region
        case side
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let regionRaw = try container.decode(String.self, forKey: .region)
        guard let region = AnyBodyPart.resolveRegion(regionRaw) else {
            throw DecodingError.dataCorruptedError(
                forKey: .region,
                in: container,
                debugDescription: "Cannot resolve AnyBodyPart region from rawValue: \(regionRaw)"
            )
        }
        self.representation = region.representation
        self.side = try container.decodeIfPresent(LateralSide.self, forKey: .side)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(regionRawValue, forKey: .region)
        try container.encodeIfPresent(side, forKey: .side)
    }

    // MARK: - BodyPartStringConvertible

    /// The stable string identifier for the body part.
    ///
    /// For unsided values this is the region's rawValue (e.g. `"biceps_brachii"`), byte-identical
    /// to pre-`side` behavior. For sided values the side rawValue is appended after the separator
    /// (e.g. `"biceps_brachii|left"`).
    public var rawValue: String {
        guard let side else { return regionRawValue }
        return regionRawValue + AnyBodyPart.sideSeparator + side.rawValue
    }

    /// The region portion of `rawValue`, without any side suffix.
    private var regionRawValue: String {
        switch representation {
        case .group(let group): return group.rawValue
        case .slug(let slug): return slug.rawValue
        }
    }

    /// Returns the localized or formatted display name for the body part.
    ///
    /// Always returns the region name only; the side is not surfaced here so existing consumers
    /// of `displayName` keep their current output. Use `qualifiedDisplayName` for the sided form.
    public var displayName: String {
        switch representation {
        case .group(let group): return group.displayName
        case .slug(let slug): return slug.displayName
        }
    }

    /// `displayName` with a trailing ` (L)` / ` (R)` when a side is set; otherwise identical to
    /// `displayName`.
    public var qualifiedDisplayName: String {
        guard let side else { return displayName }
        let suffix: String
        switch side {
        case .left: suffix = "L"
        case .right: suffix = "R"
        }
        return "\(displayName) (\(suffix))"
    }

    /// Returns the set of individual anatomical slugs associated with this identifier.
    ///
    /// Side is not propagated into the returned set — slugs themselves do not carry side.
    /// Consumers that need per-slug laterality should pair each returned slug with `self.side`.
    public var slugs: Set<BodyPartSlug> {
        switch representation {
        case .group(let group): return group.slugs
        case .slug(let slug): return [slug]
        }
    }

    // MARK: - Utilities

    /// Attempts to resolve a raw string into a known body part group or slug, with optional side
    /// suffix. Strings without the side separator parse to `side == nil` and behave identically
    /// to pre-`side` resolution.
    public static func resolve(_ rawValue: String) -> AnyBodyPart? {
        if let sepRange = rawValue.range(of: sideSeparator) {
            let regionStr = String(rawValue[..<sepRange.lowerBound])
            let sideStr = String(rawValue[sepRange.upperBound...])
            guard !regionStr.isEmpty, !sideStr.isEmpty,
                  let region = resolveRegion(regionStr),
                  let side = LateralSide(rawValue: sideStr)
            else { return nil }
            switch region.representation {
            case .group(let g): return AnyBodyPart(g, side: side)
            case .slug(let s): return AnyBodyPart(s, side: side)
            }
        }
        return resolveRegion(rawValue)
    }

    private static func resolveRegion(_ rawValue: String) -> AnyBodyPart? {
        // Explicit `side: nil` disambiguates against the existential-taking
        // `init?(_ identifier: any BodyPartStringConvertible)` overload — without the label,
        // overload resolution can route here recursively through `resolve` and overflow the stack.
        if let group = BodyPartGroup(rawValue: rawValue) {
            return AnyBodyPart(group, side: nil)
        }
        if let slug = BodyPartSlug(rawValue: rawValue) {
            return AnyBodyPart(slug, side: nil)
        }
        return nil
    }

    // MARK: - Convenience Access

    /// Returns the underlying group if the representation is a group.
    public var group: BodyPartGroup? {
        if case .group(let g) = representation { return g }
        return nil
    }

    /// Returns the underlying slug if the representation is a slug.
    public var slug: BodyPartSlug? {
        if case .slug(let s) = representation { return s }
        return nil
    }

    // MARK: - Hashable & Equality

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: AnyBodyPart, rhs: AnyBodyPart) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
