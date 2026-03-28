public class BBTagManager {
    let gefaultGetTagDescriptionFn: GetTagDescription
    let getTagByStringFn: GetTagByString

    public init(
        gefaultGetTagDescriptionFn: @escaping GetTagDescription = DefaultGetTagDescription,
        getTagByStringFn: @escaping GetTagByString = DefaultGetTagByString,
    ) {
        self.gefaultGetTagDescriptionFn = gefaultGetTagDescriptionFn
        self.getTagByStringFn = getTagByStringFn
    }

    func getTag(_ str: String) -> BBTag? {
        return self.getTagByStringFn(str)
    }

    func getDescription(_ tag: BBTag) -> BBTagDescription? {
        return self.gefaultGetTagDescriptionFn(tag)
    }

    func getDescription(_ str: String) -> BBTagDescription? {
        if let tag = self.getTagByStringFn(str) {
            return self.gefaultGetTagDescriptionFn(tag)
        } else {
            return nil
        }

    }
}
