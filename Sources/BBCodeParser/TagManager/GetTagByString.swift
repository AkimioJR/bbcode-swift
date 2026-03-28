public typealias GetTagByString = @Sendable (String) -> BBTag?

public let DefaultGetTagByString: GetTagByString = { str in
    let tag = BBTag.parseByString(str)
    if BBTag.virtualTags.contains(tag) {
        return nil
    } else {
        return tag
    }
}
