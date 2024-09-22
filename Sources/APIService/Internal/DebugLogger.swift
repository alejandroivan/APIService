protocol DebugLogger {

    func log(_ text: String)
}

extension DebugLogger {

    func log(_ text: String) {
#if DEBUG
        Swift.print("[\(Self.self)] \(text)")
#endif
    }
}
