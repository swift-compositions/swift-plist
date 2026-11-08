extension Bool {

    @inlinable
    public init?(_ plist: Plist) {
        guard case .bool(let value) = plist.raw else { return nil }
        self = value
    }
}
