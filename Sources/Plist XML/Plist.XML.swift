import ISO_8601
public import Plist_Core
import RFC_4648
import XML
internal import Byte

extension Plist {

    public enum XML {}
}

extension Plist.XML {

    public static func parse(_ string: String) throws(Plist.Error) -> Plist {
        let doc: XML.Document
        do throws(XML.Error) {
            doc = try XML.parse(removingDoctype(string))
        } catch {
            throw .invalidXML(message: "\(error)", line: 0, column: 0)
        }

        return try parseDocument(doc)
    }

    private static func removingDoctype(_ string: String) -> String {
        guard let declaration = string.firstRange(of: "<!DOCTYPE") else { return string }

        var index = declaration.upperBound
        var depth = 0
        while index < string.endIndex {
            let character = string[index]
            index = string.index(after: index)
            if character == "[" {
                depth += 1
            } else if character == "]" {
                depth -= 1
            } else if character == ">", depth <= 0 {
                break
            }
        }

        return String(string[string.startIndex..<declaration.lowerBound]) + String(string[index...])
    }

    public static func parse<Bytes>(
        _ bytes: Bytes
    ) throws(Plist.Error) -> Plist
    where Bytes: Swift.Collection<UInt8>, Bytes: Sendable {
        try parse(String(decoding: bytes, as: UTF8.self))
    }
}

extension Plist.XML {
    private static func parseDocument(_ doc: XML.Document) throws(Plist.Error) -> Plist {
        let root = doc.root

        guard root.element.name == "plist" else {
            throw .unexpectedElement(expected: "plist", got: root.element.name)
        }

        let children = root.children()
        guard let content = children.first else {
            throw .missingRequiredElement("plist content")
        }

        return try parseElement(content)
    }
}

extension Plist.XML {
    private static func parseElement(_ element: XML) throws(Plist.Error) -> Plist {
        let name = element.element.name

        switch name {
        case "string":
            return Plist(.string(String(element)))

        case "integer":
            let text = String(element)
            guard !text.isEmpty, let value = Int64(text) else {
                throw .typeMismatch(expected: "integer", got: text.isEmpty ? "empty" : text)
            }
            return Plist(.integer(value))

        case "real":
            let text = String(element)
            guard !text.isEmpty, let value = Double(text) else {
                throw .typeMismatch(expected: "real", got: text.isEmpty ? "empty" : text)
            }
            return Plist(.real(value))

        case "true":
            return Plist(.bool(true))

        case "false":
            return Plist(.bool(false))

        case "data":
            let text = element.text.all

            let stripped = text.filter { !$0.isWhitespace }
            guard let bytes = RFC_4648.Base64.decode(stripped) else {
                throw .invalidBase64Data
            }
            return Plist(.data(bytes.map(\.underlying)))

        case "date":
            let text = String(element)
            guard !text.isEmpty else {
                throw .invalidDateFormat("empty")
            }
            return try parseDate(text)

        case "array":
            var elements: [Plist.Value] = []
            for child in element.children() {
                let parsed = try parseElement(child)
                elements.append(parsed.value)
            }
            return Plist(.array(elements))

        case "dict":
            return try parseDictionary(element)

        default:
            throw .unexpectedElement(expected: "plist element", got: name)
        }
    }
}

extension Plist.XML {
    private static func parseDictionary(_ element: XML) throws(Plist.Error) -> Plist {
        var members: [(key: String, value: Plist.Value)] = []
        let children = element.children()

        var index = 0
        while index < children.count {
            let keyElement = children[index]

            guard keyElement.element.name == "key" else {
                throw .unexpectedElement(expected: "key", got: keyElement.element.name)
            }

            let key = String(keyElement)
            guard !key.isEmpty else {
                throw .missingRequiredElement("key text")
            }

            index += 1

            guard index < children.count else {
                throw .missingRequiredElement("value for key '\(key)'")
            }

            let valueElement = children[index]
            let parsedValue = try parseElement(valueElement)
            members.append((key: key, value: parsedValue.value))

            index += 1
        }

        return Plist(.dictionary(members))
    }
}

extension Plist.XML {

    @usableFromInline
    static let appleReferenceEpochOffset: Int = 978_307_200

    private static func parseDate(_ text: String) throws(Plist.Error) -> Plist {

        let dateTime: ISO_8601.DateTime
        do throws(ISO_8601.DateTime.Parser.Error) {
            dateTime = try ISO_8601.DateTime(text)
        } catch {
            throw .invalidDateFormat(text)
        }

        let unixSeconds =
            dateTime.date.daysSinceUnixEpoch * 86_400
            + dateTime.hour * 3_600 + dateTime.minute * 60 + dateTime.second
            - dateTime.offset.seconds
        let nanoseconds = dateTime.nanoseconds
        let appleSeconds =
            Double(unixSeconds - appleReferenceEpochOffset)
            + Double(nanoseconds) / 1_000_000_000

        return Plist(.date(appleSeconds))
    }
}

extension Plist.XML {

    private static let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

    private static let doctype =
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
}

extension Plist.XML {

    public static func serialize(_ plist: Plist, pretty: Bool = false) -> [UInt8] {
        let rootElement = serializeValue(plist.value)
        let plistElement = XML.element(
            "plist",
            attributes: [XML.Attribute(name: "version", value: "1.0")],
            children: [rootElement]
        )

        var bytes = Array((xmlDeclaration + "\n" + doctype + "\n").utf8)
        bytes.append(contentsOf: plistElement.serialize.bytes(pretty: pretty))
        return bytes
    }

    public static func serializeString(_ plist: Plist, pretty: Bool = false) -> String {
        String(decoding: serialize(plist, pretty: pretty), as: UTF8.self)
    }
}

extension Plist.XML {
    private static func serializeValue(_ value: Plist.Value) -> XML {
        switch value {
        case .string(let text):
            return XML.element("string", text: text)

        case .integer(let number):
            return XML.element("integer", text: String(number))

        case .real(let number):

            let text: String
            if number.truncatingRemainder(dividingBy: 1) == 0 {

                let intPart = Int(number)
                text = "\(intPart).0"
            } else {
                text = String(number)
            }
            return XML.element("real", text: text)

        case .bool(let flag):
            return flag ? XML.element("true") : XML.element("false")

        case .data(let bytes):
            let base64 = RFC_4648.Base64.encode(bytes.lazy.map(Byte.init(bitPattern:)), padding: true)
            let base64String = String(decoding: base64.lazy.map(\.underlying), as: UTF8.self)
            return XML.element("data", text: base64String)

        case .date(let secondsSinceRef):
            let text = formatDate(secondsSinceRef)
            return XML.element("date", text: text)

        case .array(let elements):
            let children = elements.map { serializeValue($0) }
            return XML.element("array", children: children)

        case .dictionary(let members):
            var children: [XML] = []
            for member in members {
                children.append(XML.element("key", text: member.key))
                children.append(serializeValue(member.value))
            }
            return XML.element("dict", children: children)

        case .null:

            return XML.element("string", text: "")
        }
    }
}

extension Plist.XML {
    private static func formatDate(_ secondsSinceRef: Double) -> String {

        let wholeSeconds = secondsSinceRef.rounded(.down)
        let unixSeconds = Int(wholeSeconds) + appleReferenceEpochOffset
        let nanoseconds = Int((secondsSinceRef - wholeSeconds) * 1_000_000_000)
        let secondOfDay = (unixSeconds % 86_400 + 86_400) % 86_400

        guard
            let date = try? ISO_8601.CalendarDate(daysSinceUnixEpoch: (unixSeconds - secondOfDay) / 86_400),
            let dateTime = try? ISO_8601.DateTime(
                date: date,
                hour: secondOfDay / 3_600,
                minute: secondOfDay % 3_600 / 60,
                second: secondOfDay % 60,
                nanoseconds: nanoseconds
            )
        else {
            return "2001-01-01T00:00:00Z"
        }

        return ISO_8601.DateTime.Formatter.format(dateTime)
    }
}
