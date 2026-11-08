import Plist_Core

extension Plist.Binary {

    enum Marker {}
}

extension Plist.Binary.Marker {

    static let null: UInt8 = 0x00

    static let boolFalse: UInt8 = 0x08

    static let boolTrue: UInt8 = 0x09

    static let fill: UInt8 = 0x0F

    static let integerType: UInt8 = 0x10

    static let real4: UInt8 = 0x22

    static let real8: UInt8 = 0x23

    static let date: UInt8 = 0x33

    static let dataType: UInt8 = 0x40

    static let asciiType: UInt8 = 0x50

    static let unicodeType: UInt8 = 0x60

    static let arrayType: UInt8 = 0xA0

    static let dictType: UInt8 = 0xD0

    static let extendedLength: UInt8 = 0x0F
}

extension Plist.Binary.Marker {

    @inlinable
    package static func highNibble(_ byte: UInt8) -> UInt8 {
        byte & 0xF0
    }

    @inlinable
    package static func lowNibble(_ byte: UInt8) -> UInt8 {
        byte & 0x0F
    }

    @inlinable
    package static func hasExtendedLength(_ byte: UInt8) -> Bool {
        lowNibble(byte) == extendedLength
    }
}
