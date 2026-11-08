extension Plist: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self.raw = .null
    }
}

extension Plist: ExpressibleByBooleanLiteral {
    @inlinable
    public init(booleanLiteral value: Bool) {
        self.raw = .bool(value)
    }
}

extension Plist: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int) {
        self.raw = .integer(Int64(value))
    }
}

extension Plist: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self.raw = .real(value)
    }
}

extension Plist: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self.raw = .string(value)
    }
}

extension Plist: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: Plist.Value...) {
        self.raw = .array(elements)
    }
}

extension Plist: ExpressibleByDictionaryLiteral {
    public typealias Key = String

    @inlinable
    public init(dictionaryLiteral elements: (String, Plist.Value)...) {
        self.raw = .dictionary(elements.map { ($0.0, $0.1) })
    }
}
