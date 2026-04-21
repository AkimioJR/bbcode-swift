public typealias BBRender<K: Hashable, V, R> = @Sendable (BBNode, [K: V]) -> R

extension BBCode {
    public func render<K: Hashable, V, R>(
        _ bbcode: String,
        using parser: BBParser = DefaultBBParser(),
        tagManager: BBTagManager = DefaultBBTagManager(),
        renderer: BBRender<K, V, R>,
        args: [K: V] = [:],
    ) throws(BBError) -> R {
        let domTree = try parser.parse(bbcode, BBParserContext(tagManager: tagManager))
        handleNewlineAndParagraph(node: domTree)
        return renderer(domTree, args)
    }
}
