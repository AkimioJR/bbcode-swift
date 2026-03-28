public struct BBTagDescription: Sendable {
    let tagNeeded: Bool
    let isSelfClosing: Bool
    let allowedChildren: Set<BBTag>
    let allowAttr: Bool
    let isBlock: Bool

    init(
        tagNeeded: Bool,
        isSelfClosing: Bool,
        allowedChildren: Set<BBTag>,
        allowAttr: Bool,
        isBlock: Bool
    ) {
        self.tagNeeded = tagNeeded
        self.isSelfClosing = isSelfClosing
        self.allowedChildren = allowedChildren
        self.allowAttr = allowAttr
        self.isBlock = isBlock
    }
}
