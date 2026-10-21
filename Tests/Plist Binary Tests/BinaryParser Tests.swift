import Plist_Binary
import Testing

extension Plist.Binary {
    @Suite
    struct `Plist Binary Parser Tests` {
        @Test
        func `Parse simple binary plist with string`() throws {

            let bytes: [UInt8] = [
                0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30,
                0x55, 0x68, 0x65, 0x6C, 0x6C, 0x6F,
                0x08,

                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x01, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0E,
            ]

            let plist = try Plist.Binary.parse(bytes)
            #expect(String(plist) == "hello")
        }

        @Test
        func `Invalid magic throws error`() {
            let bytes: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]

            #expect(throws: Plist.Error.self) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `Empty data throws error`() {
            let bytes: [UInt8] = []

            #expect(throws: Plist.Error.self) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `Object declaring a length past the end of input throws instead of trapping`() {
            var bytes: [UInt8] = Array("bplist00".utf8)

            bytes.append(contentsOf: [0x4F, 0x11, 0x03, 0xE8])
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(1)
            bytes.append(1)
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 12])

            #expect(throws: Plist.Error.unexpectedEndOfData) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `Trailer with out-of-range offsetIntSize throws invalidTrailer`() {
            var bytes: [UInt8] = Array("bplist00".utf8)
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(0)
            bytes.append(1)
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])

            #expect(throws: Plist.Error.invalidTrailer) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `Trailer numObjects exceeding Int range throws integerOverflow`() {
            var bytes: [UInt8] = Array("bplist00".utf8)
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(1)
            bytes.append(1)

            bytes.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])

            #expect(throws: Plist.Error.integerOverflow) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `Self-referencing array throws circularReference instead of returning null`() {
            var bytes: [UInt8] = Array("bplist00".utf8)
            bytes.append(0xA1)
            bytes.append(0x00)
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(1)
            bytes.append(1)
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 10])

            #expect(throws: Plist.Error.circularReference) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `16-byte integer that does not fit Int64 throws integerOverflow`() {
            var bytes: [UInt8] = Array("bplist00".utf8)
            bytes.append(0x14)

            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(1)
            bytes.append(1)
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 25])

            #expect(throws: Plist.Error.integerOverflow) {
                try Plist.Binary.parse(bytes)
            }
        }

        @Test
        func `16-byte integer within Int64 range parses correctly`() throws {
            var bytes: [UInt8] = Array("bplist00".utf8)
            bytes.append(0x14)

            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])

            bytes.append(contentsOf: [0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
            bytes.append(0x08)
            bytes.append(contentsOf: [0, 0, 0, 0, 0])
            bytes.append(0)
            bytes.append(1)
            bytes.append(1)
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 1])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
            bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 25])

            let plist = try Plist.Binary.parse(bytes)
            #expect(Int64(plist) == Int64.max)
        }
    }
}

extension Plist.Binary {
    @Suite
    struct `Plist Binary Serializer Tests` {
        @Test
        func `Serialize and parse string`() throws {
            let original = Plist.string("Hello, Binary!")
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(String(parsed) == "Hello, Binary!")
        }

        @Test
        func `Serialize and parse integer`() throws {
            let original = Plist.integer(12345)
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(Int64(parsed) == 12345)
        }

        @Test
        func `Serialize and parse negative integer`() throws {
            let original = Plist.integer(-9999)
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(Int64(parsed) == -9999)
        }

        @Test
        func `Serialize and parse real`() throws {
            let original = Plist.real(3.14159)
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(Double(parsed) == 3.14159)
        }

        @Test
        func `Serialize and parse boolean`() throws {
            let trueValue = Plist.bool(true)
            let falseValue = Plist.bool(false)

            let trueBytes = Plist.Binary.serialize(trueValue)
            let falseBytes = Plist.Binary.serialize(falseValue)

            let parsedTrue = try Plist.Binary.parse(trueBytes)
            let parsedFalse = try Plist.Binary.parse(falseBytes)

            #expect(Bool(parsedTrue) == true)
            #expect(Bool(parsedFalse) == false)
        }

        @Test
        func `Serialize and parse data`() throws {
            let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
            let original = Plist.data(bytes)
            let serialized = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(serialized)

            #expect(parsed.data == bytes)
        }

        @Test
        func `Serialize and parse array`() throws {
            let original = Plist.array([
                .string("one"),
                .integer(2),
                .bool(true),
            ])
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(parsed.isArray)
            #expect(String(parsed[0]) == "one")
            #expect(Int64(parsed[1]) == 2)
            #expect(Bool(parsed[2]) == true)
        }

        @Test
        func `Serialize and parse dictionary`() throws {
            let original = Plist.dictionary([
                ("name", .string("Alice")),
                ("score", .integer(100)),
            ])
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(parsed.isDictionary)
            #expect(String(parsed["name"]) == "Alice")
            #expect(Int64(parsed["score"]) == 100)
        }

        @Test
        func `Serialize and parse nested structures`() throws {
            let original: Plist = [
                "user": [
                    "name": "Bob",
                    "tags": ["swift", "plist", "binary"],
                ],
                "version": 1,
            ]

            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(String(parsed.user.name) == "Bob")
            #expect(String(parsed.user.tags[0]) == "swift")
            #expect(String(parsed.user.tags[1]) == "plist")
            #expect(String(parsed.user.tags[2]) == "binary")
            #expect(Int64(parsed.version) == 1)
        }

        @Test
        func `Binary starts with correct magic`() {
            let plist = Plist.string("test")
            let bytes = Plist.Binary.serialize(plist)

            #expect(bytes.count >= 8)
            #expect(bytes[0] == 0x62)
            #expect(bytes[1] == 0x70)
            #expect(bytes[2] == 0x6C)
            #expect(bytes[3] == 0x69)
            #expect(bytes[4] == 0x73)
            #expect(bytes[5] == 0x74)
            #expect(bytes[6] == 0x30)
            #expect(bytes[7] == 0x30)
        }

        @Test
        func `Unicode string round-trip`() throws {
            let original = Plist.string("Hello, 世界! 🌍")
            let bytes = Plist.Binary.serialize(original)
            let parsed = try Plist.Binary.parse(bytes)

            #expect(String(parsed) == "Hello, 世界! 🌍")
        }
    }
}
