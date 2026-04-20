public class DefaultBBTagManager: BBTagManager {

    public init() {}

    public func getTag(_ str: String) -> BBTag? {
        let tag = BBTag.parseByString(str)
        if BBTag.virtualTags.contains(tag) {
            return nil
        } else {
            return tag
        }
    }

    public func getDescription(_ tag: BBTag) -> BBTagDescription? {
        return DefaultBBTagToBBTagDescription[tag]
    }

    public func getDescription(_ str: String) -> BBTagDescription? {
        if let tag = self.getTag(str) {
            return self.getDescription(tag)
        } else {
            return nil
        }
    }
}
