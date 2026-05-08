public typealias BBRender<T, R> = @Sendable (BBNode, T?) -> R

extension BBCode {
    public func render<Args, Output>(
        _ bbcode: String,
        using parser: BBParser = DefaultBBParser(),
        tagManager: BBTagManager = DefaultBBTagManager(),
        renderer: BBRender<Args, Output>,
        args: Args? = nil,
    ) throws(BBError) -> Output {
        let domTree = try parser.parse(bbcode, BBParserContext(with: tagManager))
        handleNewlineAndParagraph(node: domTree)
        return renderer(domTree, args)
    }
}
