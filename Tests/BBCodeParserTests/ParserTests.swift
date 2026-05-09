import XCTest

@testable import BBCodeParser

class ParserTests: XCTestCase {
    private let bbcode = BBCode<DefaultBBParser, DefaultBBTagManager>()

    private func parse(_ input: String) throws -> BBNode {
        try bbcode.parse(input)
    }

    private func assertParse(
        _ input: String,
        equals expected: NodeSnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let root = try parse(input)
        XCTAssertEqual(NodeSnapshot(root), expected, file: file, line: line)
    }

    func testParseBBCodeToExpectedNodeTree() throws {
        try assertParse(
            "前缀[b]粗体[color=red]红色[/color][/b]尾",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "前缀"),
                    NodeSnapshot(
                        tag: .bold,
                        value: "b",
                        children: [
                            NodeSnapshot(tag: .plain, value: "粗体"),
                            NodeSnapshot(
                                tag: .color,
                                value: "color",
                                attr: "red",
                                children: [
                                    NodeSnapshot(tag: .plain, value: "红色")
                                ]
                            ),
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: "尾"),
                ]
            )
        )
    }

    func testParseListWithSelfClosingListItems() throws {
        try assertParse(
            "[list][*]A[*]B[/list]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .list,
                        value: "list",
                        children: [
                            NodeSnapshot(tag: .listitem, value: "*"),
                            NodeSnapshot(tag: .plain, value: "A"),
                            NodeSnapshot(tag: .listitem, value: "*"),
                            NodeSnapshot(tag: .plain, value: "B"),
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testInvalidTagWithAttrFallsBackToPlainTextNode() throws {
        try assertParse(
            "[notatag=1]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "[notatag="),
                    NodeSnapshot(tag: .plain, value: "1]"),
                ]
            )
        )
    }

    func testOverMaxLengthTagNameFallsBackToPlainTextNode() throws {
        try assertParse(
            "[abcdefghi]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "[abcdefghi"),
                    NodeSnapshot(tag: .plain, value: "]"),
                ]
            )
        )
    }

    func testIllegalOpenBracketInsideTagRestartsTagParsing() throws {
        try assertParse(
            "[[b]x[/b]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "["),
                    NodeSnapshot(
                        tag: .bold,
                        value: "b",
                        children: [
                            NodeSnapshot(tag: .plain, value: "x")
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testUnexpectedClosingTagBecomesPlainTextNode() throws {
        try assertParse(
            "[b]x[/quote]y[/b]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .bold,
                        value: "b",
                        children: [
                            NodeSnapshot(tag: .plain, value: "x"),
                            NodeSnapshot(tag: .plain, value: "[/quote]"),
                            NodeSnapshot(tag: .plain, value: "y"),
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testIllegalEqualSignInClosingTagIsTreatedAsPlainText() throws {
        try assertParse(
            "[b]x[/b=1]y[/b]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .bold,
                        value: "b",
                        children: [
                            NodeSnapshot(tag: .plain, value: "x"),
                            NodeSnapshot(tag: .plain, value: "[/b="),
                            NodeSnapshot(tag: .plain, value: "1]y"),
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testUnclosedTagAtEOFKeepsNodeUnpaired() throws {
        try assertParse(
            "[b]x",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .bold,
                        value: "b",
                        paired: false,
                        children: [
                            NodeSnapshot(tag: .plain, value: "x")
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testBBCodeRenderCallsRendererWithHandledParagraphNodes() throws {
        let rendered: NodeSnapshot = try bbcode.render(
            "a\n\nb",
            renderer: { (node: BBNode, _: Void?) -> NodeSnapshot in NodeSnapshot(node) },
            args: Optional<Void>.none
        )

        XCTAssertEqual(
            rendered,
            NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "a"),
                    NodeSnapshot(tag: .paragraphEnd),
                    NodeSnapshot(tag: .paragraphStart),
                    NodeSnapshot(tag: .plain, value: "b"),
                ]
            )
        )
    }

    func testUtilitiesMakeContextAndNodeContext() {
        let parser = DefaultBBParser()
        let tagManager = DefaultBBTagManager()
        let context = BBParserContext(with: tagManager)

        let colorNode = BBNode(tag: .color, parent: nil, tagManager: tagManager)
        colorNode.value = "color"
        colorNode.attr = "red"

        let plainChild = BBNode(tag: .plain, parent: colorNode, tagManager: tagManager)
        plainChild.value = "A"

        let brChild = BBNode(tag: .br, parent: colorNode, tagManager: tagManager)
        brChild.value = "br"

        let boldChild = BBNode(tag: .bold, parent: colorNode, tagManager: tagManager)
        boldChild.value = "b"
        let boldPlain = BBNode(tag: .plain, parent: boldChild, tagManager: tagManager)
        boldPlain.value = "X"
        boldChild.children = [boldPlain]

        colorNode.children = [plainChild, brChild, boldChild]
        context.currentNode = colorNode

        var scanner = BBScanner("a\nb")
        _ = scanner.next()
        _ = scanner.next()

        let errCtx = parser.makeContext(g: scanner, ctx: context)
        XCTAssertEqual(errCtx.line, 2)
        XCTAssertEqual(errCtx.column, 1)
        XCTAssertEqual(errCtx.nodeDetail, "[color=red]A[br][b]X[/b]")

        XCTAssertEqual(parser.nodeContext(node: boldChild), "[b]X[/b]")
    }

    func testBBNodeSetTagResetPlainAndFallbackDescription() {
        let customTagManager = NilDescriptionTagManager()
        let node = BBNode(tag: .bold, parent: nil, tagManager: customTagManager)

        XCTAssertEqual(node.tag, .bold)
        XCTAssertNotNil(node.description)
        XCTAssertEqual(node.description?.allowAttr, false)
        XCTAssertEqual(node.description?.allowedChildren, [])

        let customDesc = BBTagDescription(
            tagNeeded: true,
            isSelfClosing: false,
            allowedChildren: [.plain],
            allowAttr: true,
            isBlock: false
        )
        node.setTag(tag: .color, desc: customDesc)

        XCTAssertEqual(node.tag, .color)
        XCTAssertEqual(node.description?.allowAttr, true)

        node.resetPlain()
        XCTAssertEqual(node.tag, .plain)
        XCTAssertEqual(node.description?.isSelfClosing, true)
    }

    func testCodeTagKeepsNewlineInsideContent() throws {
        try assertParse(
            "[code]line1\nline2[/code]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .code,
                        value: "code",
                        children: [
                            NodeSnapshot(tag: .plain, value: "line1\nline2")
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testCRLFNewlinesCreateSingleBrNodes() throws {
        try assertParse(
            "\r\nx\r\ny",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .br),
                    NodeSnapshot(tag: .plain, value: "x"),
                    NodeSnapshot(tag: .br),
                    NodeSnapshot(tag: .plain, value: "y"),
                ]
            )
        )
    }

    func testConsecutiveNewlinesTrimEmptyPlainBeforeBr() throws {
        try assertParse(
            "\n\nx",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .br),
                    NodeSnapshot(tag: .br),
                    NodeSnapshot(tag: .plain, value: "x"),
                ]
            )
        )
    }

    func testParseContentKeepsBracketAsTextWhenCurrentNodeHasNoDescription() throws {
        let parser = DefaultBBParser()
        let tagManager = DefaultBBTagManager()
        let context = BBParserContext(with: tagManager)
        let parent = BBNode(tag: .root, parent: nil, tagManager: tagManager)
        let node = BBNode(tag: .plain, desc: nil, parent: parent)
        context.currentNode = node

        var scanner = BBScanner("a[b")
        let state = try parser.parseContent(&scanner, context)

        assertParserState(state, is: .content)
        XCTAssertTrue(context.currentNode === parent)
        XCTAssertEqual(
            NodeSnapshot(node),
            NodeSnapshot(
                tag: .plain,
                children: [
                    NodeSnapshot(tag: .plain, value: "a[b")
                ]
            )
        )
    }

    func testParseContentReturnsTagWhenUnpairedNodeHasNoDescription() throws {
        let parser = DefaultBBParser()
        let tagManager = DefaultBBTagManager()
        let context = BBParserContext(with: tagManager)
        let parent = BBNode(tag: .root, parent: nil, tagManager: tagManager)
        let node = BBNode(tag: .plain, desc: nil, parent: parent)
        node.paired = false
        context.currentNode = node

        var scanner = BBScanner("[")
        let state = try parser.parseContent(&scanner, context)

        assertParserState(state, is: .tag)
        XCTAssertTrue(context.currentNode === node)
    }

    func testLeadingClosingTagIsTreatedAsPlainText() throws {
        try assertParse(
            "[/b]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "[/"),
                    NodeSnapshot(tag: .plain, value: "b]"),
                ]
            )
        )
    }

    func testImageTagWithAttributeParsesAttrAndContent() throws {
        try assertParse(
            "[img=128,72]https://example.com/a.png[/img]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .image,
                        value: "img",
                        attr: "128,72",
                        children: [
                            NodeSnapshot(tag: .plain, value: "https://example.com/a.png")
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testAttributeCanContainEqualSigns() throws {
        try assertParse(
            "[url=https://example.com?q=a=b]link[/url]",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(
                        tag: .url,
                        value: "url",
                        attr: "https://example.com?q=a=b",
                        children: [
                            NodeSnapshot(tag: .plain, value: "link")
                        ]
                    ),
                    NodeSnapshot(tag: .plain, value: ""),
                ]
            )
        )
    }

    func testTagThatDoesNotAllowAttrFallsBackToPlainText() throws {
        try assertParse(
            "[b=strong]x",
            equals: NodeSnapshot(
                tag: .root,
                children: [
                    NodeSnapshot(tag: .plain, value: "[b="),
                    NodeSnapshot(tag: .plain, value: "strong]x"),
                ]
            )
        )
    }

    func testBBTagCoreProperties() {
        XCTAssertEqual(BBTag.parseByString("B"), .bold)
        XCTAssertEqual(BBTag.parseByString("does-not-exist"), .unknown)

        XCTAssertEqual(BBTag.root.label, "")
        XCTAssertEqual(BBTag.bold.label, "b")

        XCTAssertTrue(BBTag.virtualTags.contains(.plain))
        XCTAssertTrue(BBTag.layout.contains(.center))
        XCTAssertTrue(BBTag.textStyle.contains(.italic))

        XCTAssertTrue(BBTag.br.isSelfClosing)
        XCTAssertFalse(BBTag.bold.isSelfClosing)

        XCTAssertTrue(BBTag.color.allowAttr)
        XCTAssertFalse(BBTag.quote.allowAttr)

        XCTAssertTrue(BBTag.mask.isBlock)
        XCTAssertFalse(BBTag.bold.isBlock)

        XCTAssertTrue(BBTag.root.allowedChildren.contains(.quote))
        XCTAssertTrue(BBTag.center.allowedChildren.contains(.mask))
        XCTAssertTrue(BBTag.align.allowedChildren.contains(.size))
        XCTAssertTrue(BBTag.list.allowedChildren.contains(.listitem))
        XCTAssertTrue(BBTag.listitem.allowedChildren.contains(.url))
        XCTAssertTrue(BBTag.url.allowedChildren.contains(.image))
        XCTAssertTrue(BBTag.bold.allowedChildren.contains(.url))
        XCTAssertTrue(BBTag.mask.allowedChildren.contains(.br))
        XCTAssertEqual(BBTag.plain.allowedChildren, [])
        XCTAssertFalse(BBTag.code.allowedChildren.contains(.br))
    }

    func testBBErrorDescriptionsAndFailureReason() {
        let internalError = BBError.internalError("bug detail")
        XCTAssertEqual(internalError.errorDescription, "解析器内部发生错误")
        XCTAssertEqual(internalError.failureReason, "bug detail")

        let context = BBErrorContext(line: 2, column: 3, nodeDetail: "[b]x")
        let parseError = BBError.unfinishedAttr(tag: .color, context: context)
        XCTAssertTrue(parseError.failureReason?.contains("第 2 行, 第 3 列") == true)
        XCTAssertTrue(parseError.failureReason?.contains("异常片段: [b]x") == true)

        XCTAssertEqual(context.locationString, "第 2 行, 第 3 列")
        XCTAssertTrue(BBError.internalError("debug").debugDescription.contains("debug"))

        let errors: [BBError] = [
            .unfinishedOpeningTag(tag: .bold, context: context),
            .unfinishedClosingTag(tag: .bold, context: context),
            .unfinishedAttr(tag: .bold, context: context),
            .unpairedTag(tag: .bold, context: context),
            .unclosedTag(tag: .bold, context: context),
        ]
        for error in errors {
            XCTAssertEqual(
                error.failureReason,
                "在 第 2 行, 第 3 列 附近解析失败。\n异常片段: [b]x"
            )
        }
    }
}

private func assertParserState(
    _ actual: DefaultBBParser.ParserState,
    is expected: DefaultBBParser.ParserState,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch (actual, expected) {
    case (.content, .content), (.tag, .tag), (.tagClosing, .tagClosing), (.attr, .attr),
        (.end, .end):
        break
    default:
        XCTFail("Expected parser state \(expected), got \(actual)", file: file, line: line)
    }
}

private final class NilDescriptionTagManager: BBTagManager {
    func getTag(_ str: String) -> BBTag? {
        BBTag.parseByString(str)
    }

    func getDescription(_ tag: BBTag) -> BBTagDescription? {
        nil
    }

    func getDescription(_ str: String) -> BBTagDescription? {
        nil
    }
}

private struct NodeSnapshot: Equatable {
    let tag: String
    let value: String
    let attr: String
    let paired: Bool
    let children: [NodeSnapshot]

    init(
        tag: BBTag,
        value: String = "",
        attr: String = "",
        paired: Bool = true,
        children: [NodeSnapshot] = []
    ) {
        self.tag = tag.rawValue
        self.value = value
        self.attr = attr
        self.paired = paired
        self.children = children
    }

    init(_ node: BBNode) {
        self.tag = node.tag.rawValue
        self.value = node.value
        self.attr = node.attr
        self.paired = node.paired
        self.children = node.children.map(NodeSnapshot.init)
    }
}
