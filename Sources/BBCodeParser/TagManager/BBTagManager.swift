public protocol BBTagManager {
    func getTag(_ str: String) -> BBTag?
    func getDescription(_ tag: BBTag) -> BBTagDescription?
    func getDescription(_ str: String) -> BBTagDescription?
}

extension BBTagManager {
    public func getDescription(_ str: String) -> BBTagDescription? {
        if let tag = self.getTag(str) {
            return self.getDescription(tag)
        } else {
            return nil
        }
    }
}
