#if canImport(Darwin)
    import Darwin
    import Plist_Binary
    import Testing

    private func readFile(_ path: String) -> [UInt8]? {
        guard let file = unsafe fopen(path, "rb") else {
            return nil
        }
        defer { unsafe fclose(file) }

        unsafe fseek(file, 0, SEEK_END)
        let size = unsafe ftell(file)
        unsafe fseek(file, 0, SEEK_SET)

        guard size > 0 else { return nil }

        var buffer = [UInt8](repeating: 0, count: size)
        let bytesRead = unsafe fread(&buffer, 1, size, file)
        guard bytesRead == size else { return nil }

        return buffer
    }

    private func preferencesPath(_ name: String) -> String? {
        guard let homePointer = unsafe getenv("HOME") else {
            return nil
        }
        let home = unsafe String(cString: homePointer)
        guard !home.isEmpty else { return nil }
        return home + "/Library/Preferences/" + name
    }

    extension Plist.Binary {
        @Suite
        struct Test {
            @Test
            func `Parse com.apple.finder.plist`() throws {
                guard let path = preferencesPath("com.apple.finder.plist"),
                    let bytes = readFile(path)
                else { return }

                let format = Plist.Format.detect(bytes)
                #expect(format == .binary, "Expected binary plist format")

                let plist = try Plist.Binary.parse(bytes)

                #expect(plist.dictionary != nil, "Expected dictionary at root")

                if let dict = plist.dictionary {
                    #expect(dict.count > 10, "Expected many keys in Finder preferences")
                }
            }

            @Test
            func `Parse com.apple.dock.plist`() throws {
                guard let path = preferencesPath("com.apple.dock.plist"),
                    let bytes = readFile(path)
                else { return }

                let format = Plist.Format.detect(bytes)
                #expect(format == .binary, "Expected binary plist format")

                let plist = try Plist.Binary.parse(bytes)

                #expect(plist.dictionary != nil, "Expected dictionary at root")

                if let dict = plist.dictionary {
                    let keys = dict.map { $0.key }

                    let hasTypicalKey =
                        keys.contains("autohide") || keys.contains("tilesize")
                        || keys.contains("persistent-apps")
                    #expect(hasTypicalKey, "Expected typical dock preference keys")
                }
            }

            @Test
            func `Parse any available binary plist`() throws {

                let candidates = [
                    preferencesPath("com.apple.finder.plist"),
                    preferencesPath("com.apple.dock.plist"),
                    "/Library/Preferences/com.apple.loginwindow.plist",
                ].compactMap { $0 }

                for path in candidates {
                    guard let bytes = readFile(path) else { continue }

                    let format = Plist.Format.detect(bytes)
                    guard format == .binary else { continue }

                    let plist = try Plist.Binary.parse(bytes)
                    #expect(
                        plist.dictionary != nil || plist.array != nil,
                        "Expected dictionary or array at root"
                    )
                    break
                }
            }
        }
    }
#endif
