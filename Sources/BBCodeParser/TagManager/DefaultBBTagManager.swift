public class DefaultBBTagManager: BBTagManager {

    public init() {}

    public func getTag(_ str: String) -> BBTag? {
        let tag = BBTag.parseByString(str)
        if tag.isVirtualTags {
            return nil
        } else {
            return tag
        }
    }

    public func getDescription(_ tag: BBTag) -> BBTagDescription? {
        return DefaultBBTagToBBTagDescription[tag]
    }
}
