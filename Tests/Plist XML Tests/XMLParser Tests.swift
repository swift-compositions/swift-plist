import Plist_XML
import Standard_Library_Extensions
import Testing

extension Plist.XML {
    @Suite
    struct Parser {
        @Test
        func `Parse string element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <string>Hello, World!</string>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(String(plist) == "Hello, World!")
        }

        @Test
        func `Parse integer element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <integer>42</integer>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(Int64(plist) == 42)
        }

        @Test
        func `Parse negative integer`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <integer>-100</integer>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(Int64(plist) == -100)
        }

        @Test
        func `Parse real element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <real>3.14159</real>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(Double(plist) == 3.14159)
        }

        @Test
        func `Parse true element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <true/>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(Bool(plist) == true)
        }

        @Test
        func `Parse false element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <false/>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(Bool(plist) == false)
        }

        @Test
        func `Parse data element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <data>SGVsbG8=</data>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(plist.data == [0x48, 0x65, 0x6C, 0x6C, 0x6F])
        }

        @Test
        func `Parse date element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <date>2024-01-15T12:30:00Z</date>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(plist.isDate)

            #expect(plist.date != nil)
        }

        @Test
        func `Parse array element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <array>
                        <string>one</string>
                        <integer>2</integer>
                        <true/>
                    </array>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(plist.isArray)
            #expect(plist.array?.count == 3)
            #expect(String(plist[0]) == "one")
            #expect(Int64(plist[1]) == 2)
            #expect(Bool(plist[2]) == true)
        }

        @Test
        func `Parse dictionary element`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <dict>
                        <key>name</key>
                        <string>John</string>
                        <key>age</key>
                        <integer>30</integer>
                    </dict>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(plist.isDictionary)
            #expect(String(plist["name"]) == "John")
            #expect(Int64(plist["age"]) == 30)
        }

        @Test
        func `Parse nested structures`() throws {
            let xml = """
                <?xml version="1.0"?>
                <plist version="1.0">
                    <dict>
                        <key>user</key>
                        <dict>
                            <key>name</key>
                            <string>Alice</string>
                            <key>tags</key>
                            <array>
                                <string>swift</string>
                                <string>plist</string>
                            </array>
                        </dict>
                    </dict>
                </plist>
                """

            let plist = try Plist.XML.parse(xml)
            #expect(String(plist.user.name) == "Alice")
            #expect(String(plist.user.tags[0]) == "swift")
            #expect(String(plist.user.tags[1]) == "plist")
        }
    }
}

extension Plist.XML {
    @Suite
    struct Serializer {
        @Test
        func `Serialize string`() {
            let plist = Plist.string("Hello")
            let bytes = Plist.XML.serialize(plist)
            let xml = String(decoding: bytes, as: UTF8.self)

            #expect(xml.contains("<string>Hello</string>"))
        }

        @Test
        func `Serialize emits version attribute and DOCTYPE`() {
            let plist = Plist.string("hello")
            let xml = String(decoding: Plist.XML.serialize(plist), as: UTF8.self)

            #expect(xml.contains("<plist version=\"1.0\">"))
            #expect(
                xml.contains(
                    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
                )
            )

            let doctypeRange = xml.range(of: "<!DOCTYPE")
            let plistRange = xml.range(of: "<plist ")
            #expect(doctypeRange != nil)
            #expect(plistRange != nil)
            if let doctypeRange, let plistRange {
                #expect(doctypeRange.lowerBound < plistRange.lowerBound)
            }
        }

        @Test
        func `Serialize integer`() {
            let plist = Plist.integer(42)
            let bytes = Plist.XML.serialize(plist)
            let xml = String(decoding: bytes, as: UTF8.self)

            #expect(xml.contains("<integer>42</integer>"))
        }

        @Test
        func `Serialize boolean`() {
            let trueValue = Plist.bool(true)
            let falseValue = Plist.bool(false)

            let trueXml = String(decoding: Plist.XML.serialize(trueValue), as: UTF8.self)
            let falseXml = String(decoding: Plist.XML.serialize(falseValue), as: UTF8.self)

            #expect(trueXml.contains("<true/>") || trueXml.contains("<true></true>"))
            #expect(falseXml.contains("<false/>") || falseXml.contains("<false></false>"))
        }

        @Test
        func `Serialize dictionary`() {
            let plist: Plist = [
                "name": "Bob",
                "age": 25,
            ]

            let bytes = Plist.XML.serialize(plist)
            let xml = String(decoding: bytes, as: UTF8.self)

            #expect(xml.contains("<dict>"))
            #expect(xml.contains("<key>name</key>"))
            #expect(xml.contains("<string>Bob</string>"))
        }

        @Test
        func `Round-trip parsing and serialization`() throws {
            let original: Plist = [
                "string": "hello",
                "number": 42,
                "real": 3.14,
                "bool": true,
                "array": [1, 2, 3],
            ]

            let bytes = Plist.XML.serialize(original)
            let parsed = try Plist.XML.parse(bytes)

            #expect(String(parsed["string"]) == "hello")
            #expect(Int64(parsed["number"]) == 42)
            #expect(Bool(parsed["bool"]) == true)
        }
    }
}
