internal import Byte
import ISO_8601
import Plist_Core
import RFC_4648
import XML

extension Plist.XML {

    private static let xmlDeclaration = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

    private static let doctype =
        "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
}

extension Plist.XML {

    public static func serialize(
        _ plist: Plist,
        pretty: Bool = false
    ) throws(Plist.Error) -> [UInt8] {
        let rootElement = try serializeValue(plist.value)
        let plistElement = XML.element(
            "plist",
            attributes: [XML.Attribute(name: "version", value: "1.0")],
            children: [rootElement]
        )

        var bytes = Array((xmlDeclaration + "\n" + doctype + "\n").utf8)
        bytes.append(contentsOf: plistElement.serialize.bytes(pretty: pretty))
        return bytes
    }

    public static func serializeString(
        _ plist: Plist,
        pretty: Bool = false
    ) throws(Plist.Error) -> String {
        String(decoding: try serialize(plist, pretty: pretty), as: UTF8.self)
    }
}

extension Plist.XML {
    private static func serializeValue(_ value: Plist.Value) throws(Plist.Error) -> XML {
        switch value {
        case .string(let text):
            return XML.element("string", text: text)

        case .integer(let number):
            return XML.element("integer", text: String(number))

        case .real(let number):

            let text = Int(exactly: number).map { "\($0).0" } ?? String(number)
            return XML.element("real", text: text)

        case .bool(let flag):
            return flag ? XML.element("true") : XML.element("false")

        case .data(let bytes):
            let base64 = RFC_4648.Base64.encode(bytes.lazy.map(Byte.init(bitPattern:)), padding: true)
            let base64String = String(decoding: base64.lazy.map(\.underlying), as: UTF8.self)
            return XML.element("data", text: base64String)

        case .date(let secondsSinceRef):
            guard let text = formatDate(secondsSinceRef) else {
                throw .unrepresentableInXML("date \(secondsSinceRef) seconds since 2001-01-01")
            }
            return XML.element("date", text: text)

        case .array(let elements):
            var children: [XML] = []
            for element in elements {
                children.append(try serializeValue(element))
            }
            return XML.element("array", children: children)

        case .dictionary(let members):
            var children: [XML] = []
            for member in members {
                children.append(XML.element("key", text: member.key))
                children.append(try serializeValue(member.value))
            }
            return XML.element("dict", children: children)

        case .null:
            throw .unrepresentableInXML("null")
        }
    }
}

extension Plist.XML {
    private static func formatDate(_ secondsSinceRef: Double) -> String? {

        let wholeSeconds = secondsSinceRef.rounded(.down)
        guard let whole = Int(exactly: wholeSeconds) else { return nil }
        let shifted = whole.addingReportingOverflow(appleReferenceEpochOffset)
        guard !shifted.overflow else { return nil }
        let unixSeconds = shifted.partialValue
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
            return nil
        }

        return ISO_8601.DateTime.Formatter.format(dateTime)
    }
}
