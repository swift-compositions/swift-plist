public import Async_Stream

extension Plist {

    @inlinable
    public static func parse<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Self.Error) -> Plist
    where S.Element == UInt8 {
        var buffer: [UInt8] = []
        do {
            for try await byte in bytes {
                buffer.append(byte)
            }
        } catch {
            throw .sourceSequenceFailure("\(error)")
        }
        return try parse(buffer)
    }
}

extension Plist.Parse {

    @inlinable
    public func collecting<S: AsyncSequence & Sendable>(
        _ bytes: S
    ) async throws(Plist.Error) -> Plist
    where S.Element == UInt8 {
        try await Plist.parse(collecting: bytes)
    }
}

extension Plist.Serializable {

    @inlinable
    public init<S: AsyncSequence & Sendable>(
        collecting bytes: S
    ) async throws(Plist.Error)
    where S.Element == UInt8 {
        let plist = try await Plist.parse(collecting: bytes)
        self = try Self.deserialize(plist)
    }
}

extension Plist {

    public enum ND: Sendable {}
}

extension Plist.ND {

    @inlinable
    public static func stream<S: AsyncSequence & Sendable>(
        _ bytes: S
    ) -> Async.Stream<Result<Plist, Plist.Error>>
    where S.Element == UInt8 {
        Async.Stream {
            let state = State(bytes.makeAsyncIterator())
            return Async.Stream<Result<Plist, Plist.Error>>.Iterator {
                await state.next()
            }
        }
    }
}

extension Plist.ND {

    @usableFromInline
    internal final class State<I: AsyncIteratorProtocol>: @unchecked Sendable
    where I.Element == UInt8 {
        @usableFromInline
        var iterator: I

        @usableFromInline
        var buffer: [UInt8] = []

        @usableFromInline
        var done = false

        @usableFromInline
        init(_ iterator: I) {
            self.iterator = iterator
        }
    }
}

extension Plist.ND.State {
    @usableFromInline
    func next() async -> Result<Plist, Plist.Error>? {
        if done { return nil }

        while true {
            let byte: UInt8?
            do {
                byte = try await iterator.next()
            } catch {
                done = true
                if buffer.isEmpty { return nil }
                defer { buffer.removeAll() }
                return parseLine()
            }

            guard let byte else {

                done = true
                if buffer.isEmpty { return nil }
                defer { buffer.removeAll() }
                return parseLine()
            }

            if byte == 0x0A {
                if buffer.isEmpty { continue }
                defer { buffer.removeAll(keepingCapacity: true) }
                return parseLine()
            }

            if byte == 0x0D { continue }

            buffer.append(byte)
        }
    }

    @usableFromInline
    func parseLine() -> Result<Plist, Plist.Error> {

        if buffer.count >= 6,
            buffer[0] == 0x62,
            buffer[1] == 0x70,
            buffer[2] == 0x6C,
            buffer[3] == 0x69,
            buffer[4] == 0x73,
            buffer[5] == 0x74
        {
            return .failure(.unknownFormat)
        }

        do throws(Plist.Error) {
            let plist = try Plist.parse.xml(buffer)
            return .success(plist)
        } catch {
            return .failure(error)
        }
    }
}

extension Plist.Parse {

    @inlinable
    public func stream<S: AsyncSequence & Sendable>(
        nd bytes: S
    ) -> Async.Stream<Result<Plist, Plist.Error>>
    where S.Element == UInt8 {
        Plist.ND.stream(bytes)
    }
}
