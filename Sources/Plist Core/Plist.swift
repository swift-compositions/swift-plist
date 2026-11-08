@dynamicMemberLookup
public struct Plist: Sendable, Hashable {
    @usableFromInline
    internal var raw: Value

    @inlinable
    public init(_ raw: Value) {
        self.raw = raw
    }
}

extension Plist {

    @inlinable
    public var value: Value {
        raw
    }
}
