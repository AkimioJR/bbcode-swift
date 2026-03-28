public enum BBCodeError: Error {
    case internalError(String)
    case unfinishedOpeningTag(String)
    case unfinishedClosingTag(String)
    case unfinishedAttr(String)
    case unpairedTag(String)
    case unclosedTag(String)

    public var description: String {
        switch self {
        case .internalError(let msg):
            return msg
        case .unfinishedOpeningTag(let msg):
            return msg
        case .unfinishedClosingTag(let msg):
            return msg
        case .unfinishedAttr(let msg):
            return msg
        case .unpairedTag(let msg):
            return msg
        case .unclosedTag(let msg):
            return msg
        }
    }
}
