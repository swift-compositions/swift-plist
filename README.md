# swift-plist

Use this package when you read or write Apple property lists, in the XML or the binary format, without Foundation. Start from `Plist`: `Plist.parse(_:)` reads either format, and `Plist.serialize(format:pretty:)` writes one. Conform your own types to `Plist.Serializable` to convert them to and from a `Plist`. For a stream with one XML property list per line, use `Plist.ND.stream(_:)`.

## Laws

- `Plist.parse(_:)` picks the format from the first bytes. Input starting with `bplist` is binary. Otherwise, after any leading white space, input starting with an XML declaration, a `plist` tag or a `DOCTYPE` is XML. Anything else is an unknown format. The binary reader accepts versions `00` and `01`, and the writer emits `00`.
- Dictionaries keep their keys in order, whether parsed or built. Equality compares members in that order, so the same members in a different order are not equal. Duplicate keys are kept: a subscript returns the first, and `Plist.dictionaryValue` keeps the last.
- Reading a missing key, an index out of range, or either from a value of the wrong kind gives null, never a trap.
- XML has no null. Writing a null to XML throws `Plist.Error.unrepresentableInXML`. In the binary format it stays null. An optional that is nil serializes as null, and null deserializes as nil.
- `Double` and `Float` read integers as well as reals. `Int` reads an integer only if it fits exactly. Integer readers never accept a real.
- A date is seconds since 2001-01-01 00:00:00 UTC. XML dates are read as ISO 8601 with any offset applied, and written in UTC. Writing a date that has no ISO 8601 form to XML throws `Plist.Error.unrepresentableInXML`.
- XML input is decoded as UTF-8. The `DOCTYPE` is dropped before parsing, white space inside data is ignored, and only the first element inside `plist` is read. XML output always starts with the XML declaration and Apple's `DOCTYPE`, and a whole real within `Int` range is written with `.0`; any other real is written as Swift's shortest round-tripping form, such as `1e+300`.
- The binary writer stores each distinct value once and points every occurrence at it. Strings are written as ASCII when they can be and as big-endian UTF-16 otherwise. Reals are always written as 8 bytes. The binary reader rejects an object that contains itself.
- `Plist.parse(collecting:)` reads the whole sequence before parsing. A failing sequence is reported as a source failure, not as a parse error.
- `Plist.ND.stream(_:)` splits on line feeds, drops carriage returns and skips empty lines. Each line is parsed as XML on its own, and a line that fails, including a binary one, yields a failure and the stream continues. A last line without a line feed is still parsed. When the source sequence throws, the unfinished line is dropped, the stream yields a source failure and ends.
