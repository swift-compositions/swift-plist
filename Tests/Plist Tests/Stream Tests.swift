import Testing

@testable import Plist

@Suite
struct Test {

    @Test
    func `Parse ND plist stream`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
            <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>
            <?xml version="1.0"?><plist version="1.0"><integer>3</integer></plist>
            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for result in try await collect(Plist.ND.stream(bytes)) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2, 3])
    }

    @Test
    func `Skip empty lines in ND plist`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>

            <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>

            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for result in try await collect(Plist.ND.stream(bytes)) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test
    func `Continue after malformed line`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
            not valid plist
            <?xml version="1.0"?><plist version="1.0"><integer>3</integer></plist>
            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var successes: [Int] = []
        var failures = 0

        for result in try await collect(Plist.ND.stream(bytes)) {
            switch result {
            case .success(let plist):
                if case .integer(let value) = plist.value {
                    successes.append(Int(value))
                }

            case .failure:
                failures += 1
            }
        }

        #expect(successes == [1, 3])
        #expect(failures == 1)
    }

    @Test
    func `Handle CRLF line endings`() async throws {
        let input =
            "<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>1</integer></plist>\r\n<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>2</integer></plist>\r\n"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for result in try await collect(Plist.ND.stream(bytes)) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test
    func `Parse without trailing newline`() async throws {
        let input =
            "<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>1</integer></plist>\n<?xml version=\"1.0\"?><plist version=\"1.0\"><integer>2</integer></plist>"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var values: [Int] = []
        for result in try await collect(Plist.ND.stream(bytes)) {
            let plist = try result.get()
            if case .integer(let value) = plist.value {
                values.append(Int(value))
            }
        }

        #expect(values == [1, 2])
    }

    @Test
    func `Reject binary plist in ND stream`() async throws {

        let input = "bplist00\n"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var failures = 0
        for result in try await collect(Plist.ND.stream(bytes)) {
            if case .failure = result {
                failures += 1
            }
        }

        #expect(failures == 1)
    }

    @Test
    func `Parse single document from async bytes`() async throws {
        let input =
            "<?xml version=\"1.0\"?><plist version=\"1.0\"><dict><key>name</key><string>John</string><key>age</key><integer>30</integer></dict></plist>"

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        let plist = try await Plist.parse(collecting: bytes)

        if case .dictionary(let pairs) = plist.value {
            let keys = pairs.map(\.key)
            #expect(keys.contains("name"))
            #expect(keys.contains("age"))
        } else {
            Issue.record("Expected dictionary")
        }
    }

    @Test
    func `Parse via accessor`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><string>Hello</string></plist>
            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        let plist = try await Plist.parse.collecting(bytes)

        #expect(plist == Plist.string("Hello"))
    }

    @Test
    func `Stream via accessor`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><integer>1</integer></plist>
            <?xml version="1.0"?><plist version="1.0"><integer>2</integer></plist>
            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        var count = 0
        for result in try await collect(Plist.parse.stream(nd: bytes)) {
            _ = try result.get()
            count += 1
        }

        #expect(count == 2)
    }

    @Test
    func `Parse empty async stream`() async {
        let bytes = AsyncStream<UInt8> { continuation in
            continuation.finish()
        }

        do throws(Plist.Error) {
            _ = try await Plist.parse(collecting: bytes)
            Issue.record("Expected error for empty input")
        } catch {

        }
    }

    @Test
    func `Source sequence failure surfaces as sourceSequenceFailure, not unknownFormat`() async {
        struct SourceFailure: Swift.Error {}

        let bytes = AsyncThrowingStream<UInt8, any Swift.Error> { continuation in
            continuation.yield(0x62)
            continuation.finish(throwing: SourceFailure())
        }

        do throws(Plist.Error) {
            _ = try await Plist.parse(collecting: bytes)
            Issue.record("Expected error for a failing source sequence")
        } catch .sourceSequenceFailure(_) {

        } catch {
            Issue.record("Expected .sourceSequenceFailure, got \(error)")
        }
    }

    @Test
    func `Deserialize from async bytes`() async throws {
        let input = """
            <?xml version="1.0"?><plist version="1.0"><integer>42</integer></plist>
            """

        let bytes = AsyncStream<UInt8> { continuation in
            for byte in input.utf8 {
                continuation.yield(byte)
            }
            continuation.finish()
        }

        let plist = try await Plist.parse(collecting: bytes)
        let value = try Int.deserialize(plist)

        #expect(value == 42)
    }
}

private func collect<S: AsyncSequence>(_ sequence: S) async throws -> [S.Element] {
    var elements: [S.Element] = []
    for try await element in sequence { elements.append(element) }
    return elements
}
