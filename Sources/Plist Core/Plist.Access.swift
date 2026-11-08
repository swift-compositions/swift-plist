extension Plist {

    @inlinable
    public var data: [UInt8]? {
        if case .data(let value) = raw { return value }
        return nil
    }

    @inlinable
    public var date: Double? {
        if case .date(let value) = raw { return value }
        return nil
    }

    @inlinable
    public var array: [Plist]? {
        if case .array(let value) = raw {
            return value.map { Plist($0) }
        }
        return nil
    }

    @inlinable
    public var dictionary: [(key: String, value: Plist)]? {
        if case .dictionary(let value) = raw {
            return value.map { (key: $0.key, value: Plist($0.value)) }
        }
        return nil
    }

    @inlinable
    public var dictionaryValue: [String: Plist]? {
        guard let members = dictionary else { return nil }
        var result: [String: Plist] = [:]
        for member in members {
            result[member.key] = member.value
        }
        return result
    }
}
