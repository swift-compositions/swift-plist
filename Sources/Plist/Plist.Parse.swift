import Plist_Binary
import Plist_Core
import Plist_XML

extension Plist {

    @inlinable
    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Self.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        guard let format = Format.detect(bytes) else {
            throw .unknownFormat
        }

        switch format {
        case .xml:
            return try XML.parse(bytes)

        case .binary:
            return try Binary.parse(bytes)
        }
    }

    @inlinable
    public static func parse(xml string: String) throws(Self.Error) -> Plist {
        try XML.parse(string)
    }

    @inlinable
    public static func parse<Bytes>(
        binary bytes: Bytes
    ) throws(Self.Error) -> Plist
    where Bytes: Swift.Collection<UInt8> {
        try Binary.parse(bytes)
    }
}

extension Plist {

    @inlinable
    public func serialize(
        format: Format = .xml,
        pretty: Bool = false
    ) throws(Plist.Error) -> [UInt8] {
        switch format {
        case .xml:
            return try XML.serialize(self, pretty: pretty)

        case .binary:
            return Binary.serialize(self)
        }
    }

    @inlinable
    public func serializeXML(pretty: Bool = false) throws(Plist.Error) -> String {
        String(decoding: try XML.serialize(self, pretty: pretty), as: UTF8.self)
    }
}

extension Plist.Serializable {

    @inlinable
    public init<Bytes>(
        plistBytes bytes: Bytes
    ) throws(Plist.Error)
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        let plist = try Plist.parse(bytes)
        self = try Self.deserialize(plist)
    }

    @inlinable
    public func plistBytes(
        format: Plist.Format = .xml,
        pretty: Bool = false
    ) throws(Plist.Error) -> [UInt8] {
        try plist.serialize(format: format, pretty: pretty)
    }

    @inlinable
    public func plistString(pretty: Bool = false) throws(Plist.Error) -> String {
        try plist.serializeXML(pretty: pretty)
    }
}

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
