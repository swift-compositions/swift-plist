public import Async_Stream


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
