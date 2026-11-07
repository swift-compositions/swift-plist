import Plist_Binary
import Plist_Core
import Plist_XML


extension Plist {
    public struct LocatedError: Swift.Error, Sendable, Hashable {

        public let error: Plist.Error

        public let offset: Int

        @inlinable
        public init(_ error: Plist.Error, at offset: Int) {
            self.error = error
            self.offset = offset
        }
    }
}
