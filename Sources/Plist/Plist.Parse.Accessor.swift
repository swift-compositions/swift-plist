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
