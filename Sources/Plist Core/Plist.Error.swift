extension Plist {

    public enum Error: Swift.Error, Sendable, Hashable {

        case unknownFormat

        case unsupportedVersion(String)

        case invalidXML(message: String, line: Int, column: Int)

        case unexpectedElement(expected: String, got: String)

        case missingRequiredElement(String)

        case invalidBase64Data

        case invalidDateFormat(String)

        case invalidMagic

        case invalidTrailer

        case invalidObjectReference(UInt64)

        case invalidObjectType(UInt8)

        case integerOverflow

        case circularReference

        case unexpectedEndOfData

        case sourceSequenceFailure(String)

        case typeMismatch(expected: String, got: String)

        case missingKey(String)

        /// A value the target format has no representation for, such as
        /// null or an out-of-range date in XML.
        case unrepresentableInXML(String)
    }
}

extension Plist.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknownFormat:
            return "Unknown plist format"

        case .unsupportedVersion(let version):
            return "Unsupported plist version: \(version)"

        case .invalidXML(let message, let line, let column):
            return "Invalid XML at line \(line), column \(column): \(message)"

        case .unexpectedElement(let expected, let got):
            return "Expected \(expected), got \(got)"

        case .missingRequiredElement(let name):
            return "Missing required element: \(name)"

        case .invalidBase64Data:
            return "Invalid Base64-encoded data"

        case .invalidDateFormat(let format):
            return "Invalid date format: \(format)"

        case .invalidMagic:
            return "Invalid binary plist magic number"

        case .invalidTrailer:
            return "Invalid binary plist trailer"

        case .invalidObjectReference(let ref):
            return "Invalid object reference: \(ref)"

        case .invalidObjectType(let marker):
            return "Invalid object type marker: 0x\(String(marker, radix: 16, uppercase: true))"

        case .integerOverflow:
            return "Integer overflow during parsing"

        case .circularReference:
            return "Circular reference detected"

        case .unexpectedEndOfData:
            return "Unexpected end of data"

        case .sourceSequenceFailure(let message):
            return "Failed to read source byte sequence: \(message)"

        case .typeMismatch(let expected, let got):
            return "Type mismatch: expected \(expected), got \(got)"

        case .missingKey(let key):
            return "Missing required key: \(key)"

        case .unrepresentableInXML(let value):
            return "Value has no XML plist representation: \(value)"
        }
    }
}
