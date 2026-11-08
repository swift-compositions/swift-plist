extension Plist {

    @inlinable
    public static func string(_ value: String) -> Plist {
        Plist(.string(value))
    }

    @inlinable
    public static func integer(_ value: Int64) -> Plist {
        Plist(.integer(value))
    }

    @inlinable
    public static func integer(_ value: Int) -> Plist {
        Plist(.integer(Int64(value)))
    }

    @inlinable
    public static func real(_ value: Double) -> Plist {
        Plist(.real(value))
    }

    @inlinable
    public static func bool(_ value: Bool) -> Plist {
        Plist(.bool(value))
    }

    @inlinable
    public static func data(_ value: [UInt8]) -> Plist {
        Plist(.data(value))
    }

    @inlinable
    public static func date(secondsSinceReferenceDate: Double) -> Plist {
        Plist(.date(secondsSinceReferenceDate))
    }

    @inlinable
    public static func array(_ elements: [Plist]) -> Plist {
        Plist(.array(elements.map(\.raw)))
    }

    @inlinable
    public static func dictionary(_ members: [(String, Plist)]) -> Plist {
        Plist(.dictionary(members.map { ($0.0, $0.1.raw) }))
    }

    @inlinable
    public static var null: Plist {
        Plist(.null)
    }
}
