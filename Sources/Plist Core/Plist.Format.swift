extension Plist {

    public enum Format: Sendable, Hashable {

        case xml

        case binary
    }
}

extension Plist.Format {

    @inlinable
    public static func detect<Bytes>(_ bytes: Bytes) -> Plist.Format?
    where Bytes: Swift.Collection<UInt8> {
        guard bytes.count >= 6 else { return nil }

        var iterator = bytes.makeIterator()
        guard
            let b0 = iterator.next(),
            let b1 = iterator.next(),
            let b2 = iterator.next(),
            let b3 = iterator.next(),
            let b4 = iterator.next(),
            let b5 = iterator.next()
        else { return nil }

        if b0 == 0x62,
            b1 == 0x70,
            b2 == 0x6C,
            b3 == 0x69,
            b4 == 0x73,
            b5 == 0x74
        {
            return .binary
        }

        var offset = 0
        for byte in bytes {
            if byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D {
                offset += 1
                continue
            }
            break
        }

        let remaining = bytes.dropFirst(offset)
        guard remaining.count >= 5 else { return nil }

        var remainingIterator = remaining.makeIterator()
        guard
            let r0 = remainingIterator.next(),
            let r1 = remainingIterator.next(),
            let r2 = remainingIterator.next(),
            let r3 = remainingIterator.next(),
            let r4 = remainingIterator.next()
        else { return nil }

        if r0 == 0x3C,
            r1 == 0x3F,
            r2 == 0x78,
            r3 == 0x6D,
            r4 == 0x6C
        {
            return .xml
        }

        if r0 == 0x3C,
            r1 == 0x70,
            r2 == 0x6C,
            r3 == 0x69,
            r4 == 0x73
        {
            return .xml
        }

        if r0 == 0x3C,
            r1 == 0x21,
            r2 == 0x44,
            r3 == 0x4F,
            r4 == 0x43
        {
            return .xml
        }

        return nil
    }
}
