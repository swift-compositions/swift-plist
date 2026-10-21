import Plist_Core

extension Plist.Binary {

    public static func serialize(_ plist: Plist) -> [UInt8] {
        let writer = Writer()
        writer.write(plist)
        return writer.bytes
    }
}

extension Plist.Binary {

    final class Writer {
        var bytes: [UInt8] = []
        var objects: [ObjectRef] = []
        var objectOffsets: [Int] = []
        var uniqueObjects: [Plist.Value: Int] = [:]
    }
}

extension Plist.Binary.Writer {
    struct ObjectRef {
        let value: Plist.Value
        var offset: Int = 0
    }
}

extension Plist.Binary.Writer {
    func write(_ plist: Plist) {

        let rootIndex = collectObjects(plist.value)

        writeHeader()

        for i in 0..<objects.count {
            objectOffsets.append(bytes.count)
            writeObject(objects[i].value)
        }

        let offsetTableOffset = bytes.count
        let offsetSize = bytesNeeded(for: UInt64(bytes.count))
        for offset in objectOffsets {
            writeBigEndian(UInt64(offset), size: offsetSize)
        }

        writeTrailer(
            offsetSize: offsetSize,
            objectRefSize: bytesNeeded(for: UInt64(objects.count)),
            numObjects: UInt64(objects.count),
            topObject: UInt64(rootIndex),
            offsetTableOffset: UInt64(offsetTableOffset)
        )
    }
}

extension Plist.Binary.Writer {
    func collectObjects(_ value: Plist.Value) -> Int {

        if let existingIndex = uniqueObjects[value] {
            return existingIndex
        }

        let index = objects.count
        objects.append(ObjectRef(value: value))
        uniqueObjects[value] = index

        switch value {
        case .array(let elements):
            for element in elements {
                _ = collectObjects(element)
            }

        case .dictionary(let members):
            for member in members {
                _ = collectObjects(.string(member.key))
                _ = collectObjects(member.value)
            }

        default:
            break
        }

        return index
    }
}

extension Plist.Binary.Writer {
    func writeHeader() {

        bytes.append(contentsOf: [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30])
    }
}

extension Plist.Binary.Writer {
    func writeObject(_ value: Plist.Value) {
        switch value {
        case .null:
            bytes.append(Plist.Binary.Marker.null)

        case .bool(let flag):
            bytes.append(flag ? Plist.Binary.Marker.boolTrue : Plist.Binary.Marker.boolFalse)

        case .integer(let number):
            writeInteger(number)

        case .real(let number):
            writeReal(number)

        case .date(let seconds):
            writeDate(seconds)

        case .data(let data):
            writeData(data)

        case .string(let text):
            writeString(text)

        case .array(let elements):
            writeArray(elements)

        case .dictionary(let members):
            writeDictionary(members)
        }
    }
}

extension Plist.Binary.Writer {
    func writeInteger(_ value: Int64) {
        let unsigned = UInt64(bitPattern: value)
        let size: Int

        if value >= 0 {
            if unsigned <= 0xFF {
                size = 1
            } else if unsigned <= 0xFFFF {
                size = 2
            } else if unsigned <= 0xFFFF_FFFF {
                size = 4
            } else {
                size = 8
            }
        } else {

            if value >= Int8.min {
                size = 1
            } else if value >= Int16.min {
                size = 2
            } else if value >= Int32.min {
                size = 4
            } else {
                size = 8
            }
        }

        let sizeCode: UInt8
        switch size {
        case 1: sizeCode = 0
        case 2: sizeCode = 1
        case 4: sizeCode = 2
        case 8: sizeCode = 3
        default: sizeCode = 3
        }

        bytes.append(Plist.Binary.Marker.integerType | sizeCode)
        writeBigEndian(unsigned, size: size)
    }

    func writeReal(_ value: Double) {
        bytes.append(Plist.Binary.Marker.real8)
        writeBigEndian(value.bitPattern, size: 8)
    }

    func writeDate(_ seconds: Double) {
        bytes.append(Plist.Binary.Marker.date)
        writeBigEndian(seconds.bitPattern, size: 8)
    }

    func writeData(_ data: [UInt8]) {
        writeMarkerWithLength(Plist.Binary.Marker.dataType, length: data.count)
        bytes.append(contentsOf: data)
    }

    func writeString(_ text: String) {

        let isASCII = text.utf8.allSatisfy { $0 < 128 }

        if isASCII {
            writeMarkerWithLength(Plist.Binary.Marker.asciiType, length: text.utf8.count)
            bytes.append(contentsOf: text.utf8)
        } else {

            let utf16 = Array(text.utf16)
            writeMarkerWithLength(Plist.Binary.Marker.unicodeType, length: utf16.count)
            for codeUnit in utf16 {
                bytes.append(UInt8(codeUnit >> 8))
                bytes.append(UInt8(codeUnit & 0xFF))
            }
        }
    }

    func writeArray(_ elements: [Plist.Value]) {
        writeMarkerWithLength(Plist.Binary.Marker.arrayType, length: elements.count)

        let refSize = bytesNeeded(for: UInt64(objects.count))
        for element in elements {
            guard let ref = uniqueObjects[element] else {
                preconditionFailure("Every object is registered in uniqueObjects before references are written")
            }
            writeBigEndian(UInt64(ref), size: refSize)
        }
    }

    func writeDictionary(_ members: [(key: String, value: Plist.Value)]) {
        writeMarkerWithLength(Plist.Binary.Marker.dictType, length: members.count)

        let refSize = bytesNeeded(for: UInt64(objects.count))

        for member in members {
            guard let keyRef = uniqueObjects[.string(member.key)] else {
                preconditionFailure("Every object is registered in uniqueObjects before references are written")
            }
            writeBigEndian(UInt64(keyRef), size: refSize)
        }

        for member in members {
            guard let valueRef = uniqueObjects[member.value] else {
                preconditionFailure("Every object is registered in uniqueObjects before references are written")
            }
            writeBigEndian(UInt64(valueRef), size: refSize)
        }
    }
}

extension Plist.Binary.Writer {
    func writeMarkerWithLength(_ marker: UInt8, length: Int) {
        if length < 15 {
            bytes.append(marker | UInt8(length))
        } else {
            bytes.append(marker | Plist.Binary.Marker.extendedLength)
            writeInteger(Int64(length))
        }
    }
}

extension Plist.Binary.Writer {
    func writeBigEndian(_ value: UInt64, size: Int) {
        for i in stride(from: size - 1, through: 0, by: -1) {
            bytes.append(UInt8((value >> (i * 8)) & 0xFF))
        }
    }
}

extension Plist.Binary.Writer {
    func writeTrailer(
        offsetSize: Int,
        objectRefSize: Int,
        numObjects: UInt64,
        topObject: UInt64,
        offsetTableOffset: UInt64
    ) {

        bytes.append(contentsOf: [0, 0, 0, 0, 0])

        bytes.append(0)

        bytes.append(UInt8(offsetSize))

        bytes.append(UInt8(objectRefSize))

        writeBigEndian(numObjects, size: 8)

        writeBigEndian(topObject, size: 8)

        writeBigEndian(offsetTableOffset, size: 8)
    }
}

extension Plist.Binary.Writer {
    func bytesNeeded(for value: UInt64) -> Int {
        if value == 0 { return 1 }
        if value <= 0xFF { return 1 }
        if value <= 0xFFFF { return 2 }
        if value <= 0xFFFF_FFFF { return 4 }
        return 8
    }
}
