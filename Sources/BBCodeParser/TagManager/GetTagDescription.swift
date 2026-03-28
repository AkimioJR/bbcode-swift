let DefaultBBTagToBBTagDescription: [BBTag: BBTagDescription] = [
    .root: BBTagDescription(
        tagNeeded: false, isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .plain, .br, .paragraphStart, .paragraphEnd,
            .mask, .quote, .code, .url, .image,
            .list,
        ]).union(BBTag.layout)
            .union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .plain: BBTagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: [],
        allowAttr: false,
        isBlock: false
    ),
    .br: BBTagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: [],
        allowAttr: false,
        isBlock: false
    ),

    .paragraphStart: BBTagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: [],
        allowAttr: false,
        isBlock: false
    ),
    .paragraphEnd: BBTagDescription(
        tagNeeded: false, isSelfClosing: true,
        allowedChildren: [],
        allowAttr: false,
        isBlock: false
    ),
    .center: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .br, .mask, .quote, .code, .url, .image,
        ]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .left: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .br, .mask, .quote, .code, .url, .image,
        ]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .right: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .br, .mask, .quote, .code, .url, .image,
        ]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .align: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .br, .mask, .size, .quote, .code, .url, .image,
        ]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: true
    ),
    .list: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.list, .listitem, .br, .url]).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .listitem: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: true,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .code: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: [],
        allowAttr: false,
        isBlock: true
    ),
    .quote: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: Set<BBTag>([
            .br, .mask, .quote, .code, .url, .image,
        ]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .url: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: Set<BBTag>([.image, .br]).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: false
    ),
    .image: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: [],
        allowAttr: true,
        isBlock: true
    ),
    .bold: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: false
    ),
    .italic: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: false
    ),
    .font: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br]).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: false
    ),
    .underline: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: false
    ),
    .strikethrough: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: false
    ),
    .color: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br, .url]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: false
    ),
    .size: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.url, .mask]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: false
    ),
    .mask: BBTagDescription(
        tagNeeded: true,
        isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: false,
        isBlock: true
    ),
    .ruby: BBTagDescription(
        tagNeeded: true, isSelfClosing: false,
        allowedChildren: Set<BBTag>([.br]).union(BBTag.layout).union(BBTag.textStyle),
        allowAttr: true,
        isBlock: false
    ),
]

public typealias GetTagDescription = @Sendable (BBTag) -> BBTagDescription?
public let DefaultGetTagDescription: GetTagDescription = { tag in
    return DefaultBBTagToBBTagDescription[tag]
}
