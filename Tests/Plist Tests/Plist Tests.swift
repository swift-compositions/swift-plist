import Plist
import Testing

extension Plist.Value {
    @Suite
    struct Test {
        @Test
        func `String creation and access`() {
            let plist = Plist.string("hello")
            #expect(plist.isString)
            #expect(String(plist) == "hello")
            #expect(!plist.isInteger)
            #expect(Int64(plist) == nil)
        }

        @Test
        func `Integer creation and access`() {
            let plist = Plist.integer(42)
            #expect(plist.isInteger)
            #expect(Int64(plist) == 42)
            #expect(Int(plist) == 42)
            #expect(!plist.isString)
        }

        @Test
        func `Real creation and access`() {
            let plist = Plist.real(3.14)
            #expect(plist.isReal)
            #expect(Double(plist) == 3.14)
        }

        @Test
        func `Bool creation and access`() {
            let trueValue = Plist.bool(true)
            let falseValue = Plist.bool(false)

            #expect(trueValue.isBool)
            #expect(Bool(trueValue) == true)
            #expect(Bool(falseValue) == false)
        }

        @Test
        func `Data creation and access`() {
            let bytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
            let plist = Plist.data(bytes)

            #expect(plist.isData)
            #expect(plist.data == bytes)
        }

        @Test
        func `Array creation and access`() {
            let plist = Plist.array([
                .string("one"),
                .integer(2),
                .bool(true),
            ])

            #expect(plist.isArray)
            #expect(plist.array?.count == 3)
            #expect(String(plist[0]) == "one")
            #expect(Int(plist[1]) == 2)
            #expect(Bool(plist[2]) == true)
        }

        @Test
        func `Dictionary creation and access`() {
            let plist = Plist.dictionary([
                ("name", .string("John")),
                ("age", .integer(30)),
            ])

            #expect(plist.isDictionary)
            #expect(String(plist["name"]) == "John")
            #expect(Int(plist["age"]) == 30)
            #expect(String(plist.name) == "John")
            #expect(Int(plist.age) == 30)
        }

        @Test
        func `Null access for missing keys`() {
            let plist = Plist.dictionary([("key", .string("value"))])

            #expect(plist["missing"].isNull)
            #expect(plist.missing.isNull)
            #expect(String(plist.missing) == nil)
        }

        @Test
        func `Subscript out of bounds returns null`() {
            let plist = Plist.array([.integer(1)])

            #expect(plist[5].isNull)
            #expect(plist[-1].isNull)
        }
    }
}

extension Plist {
    @Suite
    struct Test {
        @Test
        func `Boolean literal`() {
            let plist: Plist = true
            #expect(Bool(plist) == true)
        }

        @Test
        func `Integer literal`() {
            let plist: Plist = 42
            #expect(Int64(plist) == 42)
        }

        @Test
        func `Float literal`() {
            let plist: Plist = 3.14
            #expect(Double(plist) == 3.14)
        }

        @Test
        func `String literal`() {
            let plist: Plist = "hello"
            #expect(String(plist) == "hello")
        }

        @Test
        func `Array literal`() {
            let plist: Plist = [1, 2, 3]
            #expect(plist.array?.count == 3)
            #expect(Int64(plist[0]) == 1)
        }

        @Test
        func `Dictionary literal`() {
            let plist: Plist = [
                "name": "Alice",
                "age": 25,
            ]
            #expect(String(plist.name) == "Alice")
            #expect(Int64(plist.age) == 25)
        }

        @Test
        func `Nested literal`() {
            let plist: Plist = [
                "user": [
                    "name": "Bob",
                    "tags": ["swift", "plist"],
                ]
            ]
            #expect(String(plist.user.name) == "Bob")
            #expect(String(plist.user.tags[0]) == "swift")
        }
    }
}

extension Plist.Format {
    @Suite
    struct Test {
        @Test
        func `Detect XML format with declaration`() {
            let xml = "<?xml version=\"1.0\"?><plist></plist>"
            let format = Plist.Format.detect(Array(xml.utf8))
            #expect(format == .xml)
        }

        @Test
        func `Detect XML format with plist tag`() {
            let xml = "<plist version=\"1.0\"><dict></dict></plist>"
            let format = Plist.Format.detect(Array(xml.utf8))
            #expect(format == .xml)
        }

        @Test
        func `Detect binary format`() {
            let binary: [UInt8] = [0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30]
            let format = Plist.Format.detect(binary)
            #expect(format == .binary)
        }

        @Test
        func `Unknown format`() {
            let unknown: [UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05]
            let format = Plist.Format.detect(unknown)
            #expect(format == nil)
        }
    }
}
