extension Plist {

    @inlinable
    public var isString: Bool {
        if case .string = raw { return true }
        return false
    }

    @inlinable
    public var isInteger: Bool {
        if case .integer = raw { return true }
        return false
    }

    @inlinable
    public var isReal: Bool {
        if case .real = raw { return true }
        return false
    }

    @inlinable
    public var isBool: Bool {
        if case .bool = raw { return true }
        return false
    }

    @inlinable
    public var isData: Bool {
        if case .data = raw { return true }
        return false
    }

    @inlinable
    public var isDate: Bool {
        if case .date = raw { return true }
        return false
    }

    @inlinable
    public var isArray: Bool {
        if case .array = raw { return true }
        return false
    }

    @inlinable
    public var isDictionary: Bool {
        if case .dictionary = raw { return true }
        return false
    }

    @inlinable
    public var isNull: Bool {
        if case .null = raw { return true }
        return false
    }
}
