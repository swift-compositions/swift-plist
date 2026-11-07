import Plist_Core


extension Plist.Binary.Writer {
    struct ObjectRef {
        let value: Plist.Value
        var offset: Int = 0
    }
}
