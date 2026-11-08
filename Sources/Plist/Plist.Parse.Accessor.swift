import Plist_Binary
import Plist_Core
import Plist_XML

extension Plist {

    public struct Parse: Sendable {
        @usableFromInline
        internal init() {}
    }

    public static var parse: Parse { Parse() }
}

extension Plist.Parse {

    @inlinable
    public func callAsFunction<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Plist.Format.detect(bytes) else {
            throw .unknownFormat
        }

        switch format {
        case .xml:
            return try Plist.XML.parse(bytes)

        case .binary:
            return try Plist.Binary.parse(bytes)
        }
    }

    @inlinable
    public func xml(_ string: String) throws(Plist.Error) -> Plist {
        try Plist.XML.parse(string)
    }

    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.XML.parse(bytes)
    }

    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Plist.Binary.parse(bytes)
    }
}

extension Plist.Parse {

    @inlinable
    public func prepared() -> Plist.Prepared {
        Plist.Prepared()
    }
}

extension Plist.Parse {

    @inlinable
    public func located() -> Plist.Located {
        Plist.Located()
    }
}

extension Plist {

    public struct Prepared: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Plist.Prepared {

    @inlinable
    public func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.parse(bytes)
    }

    @inlinable
    public func xml(_ string: String) throws(Plist.Error) -> Plist {
        try Plist.parse(xml: string)
    }

    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try Plist.XML.parse(bytes)
    }

    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Plist.Binary.parse(bytes)
    }
}

extension Plist {

    public struct Located: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Plist.Located {

    @inlinable
    public func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Plist.Format.detect(bytes) else {
            throw Plist.LocatedError(.unknownFormat, at: 0)
        }

        switch format {
        case .xml:
            return try xml(bytes)

        case .binary:
            return try binary(bytes)
        }
    }

    @inlinable
    public func xml<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        do throws(Plist.Error) {
            return try Plist.XML.parse(bytes)
        } catch {
            throw Plist.LocatedError(error, at: error.xmlOffset)
        }
    }

    @inlinable
    public func binary<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.LocatedError) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        do throws(Plist.Error) {
            return try Plist.Binary.parse(bytes)
        } catch {
            throw Plist.LocatedError(error, at: error.binaryOffset)
        }
    }
}

extension Plist {

    public struct LocatedError: Swift.Error, Sendable, Hashable {

        public let error: Plist.Error

        public let offset: Int

        @inlinable
        public init(_ error: Plist.Error, at offset: Int) {
            self.error = error
            self.offset = offset
        }
    }
}

extension Plist.LocatedError: CustomStringConvertible {
    public var description: String {
        "at byte \(offset): \(error)"
    }
}

extension Plist.Error {

    @usableFromInline
    var xmlOffset: Int {

        switch self {
        case .invalidXML(_, let line, _):

            return line > 0 ? 0 : 0

        default:
            return 0
        }
    }

    @usableFromInline
    var binaryOffset: Int {

        switch self {
        case .invalidMagic:
            return 0

        case .invalidTrailer:

            return 0

        case .invalidObjectReference(let ref):

            _ = ref
            return 0

        default:
            return 0
        }
    }
}
