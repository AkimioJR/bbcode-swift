public class BBParserContext {
    let tagManager: BBTagManager
    var currentNode: BBNode
    private let rootNode: BBNode

    public init(with tagManager: BBTagManager) {
        self.tagManager = tagManager
        self.rootNode = BBNode(tag: .root, parent: nil, tagManager: tagManager)

        self.currentNode = self.rootNode
    }
}
