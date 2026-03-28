public class BBNode {
    public internal(set) var tag: BBTag
    public private(set) var tagDescription: BBTagDescription? = nil

    public private(set) weak var parent: BBNode? = nil
    public internal(set) var children: [BBNode] = []

    public internal(set) var value: String = ""
    public internal(set) var attr: String = ""
    public internal(set) var paired: Bool = true

    var description: BBTagDescription? {
        return self.tagDescription
    }

    public init(tag: BBTag, desc: BBTagDescription?, parent: BBNode?) {
        self.tag = tag
        self.tagDescription = desc
        self.parent = parent
    }

    public convenience init(tag: BBTag, parent: BBNode?, tagManager: BBTagManager) {
        let desc =
            tagManager.getDescription(tag)
            ?? BBTagDescription(
                tagNeeded: false,
                isSelfClosing: false,
                allowedChildren: [],
                allowAttr: false,
                isBlock: false
            )
        self.init(tag: tag, desc: desc, parent: parent)

    }

    public func setTag(tag: BBTag, desc: BBTagDescription) {
        self.tag = tag
        self.tagDescription = desc
    }

    public func resetPlain() {
        self.tag = .plain
        self.tagDescription = DefaultBBTagToBBTagDescription[.plain]
    }
}
