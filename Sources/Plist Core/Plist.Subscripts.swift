extension Plist {

    @inlinable
    public subscript(key: String) -> Plist {
        guard case .dictionary(let members) = raw else {
            return .null
        }
        for member in members {
            if member.key == key {
                return Plist(member.value)
            }
        }
        return .null
    }

    @inlinable
    public subscript(index: Int) -> Plist {
        guard case .array(let elements) = raw else {
            return .null
        }
        guard index >= 0, index < elements.count else {
            return .null
        }
        return Plist(elements[index])
    }

    @inlinable
    public subscript(dynamicMember member: String) -> Plist {
        self[member]
    }
}
