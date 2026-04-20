public protocol BBTagManager {
    func getTag(_ str: String) -> BBTag?
    func getDescription(_ tag: BBTag) -> BBTagDescription?
    func getDescription(_ str: String) -> BBTagDescription?
}
