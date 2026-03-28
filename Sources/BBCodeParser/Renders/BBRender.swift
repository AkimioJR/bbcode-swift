public typealias BBRender<K: Hashable, V, R> = @Sendable (BBNode, [K: V]) -> R

extension BBCode {
    public func render<K: Hashable, V, R>(
        _ bbcode: String,
        using parser: BBParser = defaultBBParser,
        tagManager: BBTagManager = BBTagManager(),
        renderer: BBRender<K, V, R>,
        args: [K: V] = [:],
    ) throws(BBCodeError) -> R {
        let domTree = try parser(bbcode, BBParserContext(tagManager: tagManager))
        handleNewlineAndParagraph(node: domTree)
        return renderer(domTree, args)
    }
}
