extension String {

    @inlinable
    public init?(_ plist: Plist) {
        guard case .string(let value) = plist.raw else { return nil }
        self = value
    }
}

extension String {

    @inlinable
    public init?(_ plist: Plist?) {
        guard let plist else { return nil }
        guard case .string(let value) = plist.raw else { return nil }
        self = value
    }
}
