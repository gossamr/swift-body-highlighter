//
//  AnyBodyPart.swift
//  BodyHighlighter
//
//  Created by gossamr on 1/09/25.

import Foundation

public protocol BodyPartStringConvertible: Sendable {
    var rawValue: String { get }
    func displayName() -> String
    func slugs() -> Set<BodyPartSlug>
}

extension BodyPartStringConvertible {
    public func displayName() -> String {
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

    // MARK: - Initializers

    /// Creates a wrapper for a specific body part group.
    /// - Parameter group: The anatomical group to wrap.
    public init(_ group: BodyPartGroup) {
        self.representation = .group(group)
    }

    /// Creates a wrapper for a specific body part slug.
    /// - Parameter slug: The anatomical slug to wrap.
    public init(_ slug: BodyPartSlug) {
        self.representation = .slug(slug)
    }

    /// Attempts to create a wrapper from any `BodyPartStringConvertible` identifier.
    ///
    /// This initializer will attempt to resolve the identifier's `rawValue` into a 
    /// known `BodyPartGroup` or `BodyPartSlug`.
    ///
    /// - Parameter identifier: An object conforming to `BodyPartStringConvertible`.
    /// - Returns: An `AnyBodyPart` if resolution is successful, nil otherwise.
    public init?(_ identifier: any BodyPartStringConvertible) {
        if let part = AnyBodyPart.resolve(identifier.rawValue) {
            self = part
        } else {
            return nil
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let resolved = AnyBodyPart.resolve(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot resolve AnyBodyPart from rawValue: \(rawValue)"
            )
        }
        self.representation = resolved.representation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    // MARK: - BodyPartStringConvertible

    /// The stable string identifier for the body part.
    public var rawValue: String {
        switch representation {
        case .group(let group): return group.rawValue
        case .slug(let slug): return slug.rawValue
        }
    }

    /// Returns the localized or formatted display name for the body part.
    public func displayName() -> String {
        switch representation {
        case .group(let group): return group.displayName()
        case .slug(let slug): return slug.displayName()
        }
    }

    /// Returns the set of individual anatomical slugs associated with this identifier.
    ///
    /// For a `.slug` representation, this returns a set containing only itself.
    /// For a `.group` representation, this returns all slugs contained within that group.
    public func slugs() -> Set<BodyPartSlug> {
        switch representation {
        case .group(let group): return group.slugs()
        case .slug(let slug): return [slug]
        }
    }

    // MARK: - Utilities

    /// Attempts to resolve a raw string into a known body part group or slug.
    /// - Parameter rawValue: The string identifier to resolve.
    /// - Returns: A populated `AnyBodyPart` if a match is found, nil otherwise.
    public static func resolve(_ rawValue: String) -> AnyBodyPart? {
        if let group = BodyPartGroup(rawValue: rawValue) {
            return AnyBodyPart(group)
        }
        if let slug = BodyPartSlug(rawValue: rawValue) {
            return AnyBodyPart(slug)
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
