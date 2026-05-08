import XCTest

@testable import BBCodeParser

class HTMLTests: XCTestCase {

    func testBold() {
        XCTAssertEqual(try renderBBCodeToHTML("我是[b]粗体字[/b]"), "我是<strong>粗体字</strong>")
    }

    func testItalic() {
        XCTAssertEqual(try renderBBCodeToHTML("我是[i]斜体字[/i]"), "我是<em>斜体字</em>")
    }

    func testUnderline() {
        XCTAssertEqual(
            try renderBBCodeToHTML("我是[u]下划线文字[/u]"),
            "我是<u>下划线文字</u>")
    }

    func testStrikeThrough() {
        XCTAssertEqual(
            try renderBBCodeToHTML("我是[s]删除线文字[/s]"),
            "我是<del>删除线文字</del>")
    }

    func testCenter() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[center]居中文字[/center]"),
            "<p style=\"text-align: center;\">居中文字</p>")
    }

    func testLeft() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[left]居左文字[/left]"),
            "<p style=\"text-align: left;\">居左文字</p>")
    }

    func testRight() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[right]居右文字[/right]"),
            "<p style=\"text-align: right;\">居右文字</p>")
    }

    func testAlign() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[align=center]居中文字[/align]"),
            "<p style=\"text-align: center;\">居中文字</p>")
    }

    func testMask() {
        XCTAssertEqual(
            try renderBBCodeToHTML("我是[mask]马赛克文字[/mask]"),
            "我是<span class=\"mask\">马赛克文字</span>")
    }

    func testColor() {
        XCTAssertEqual(
            try renderBBCodeToHTML(
                "我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]"
            ),
            "我是<span style=\"color: red;\">彩</span><span style=\"color: green;\">色</span><span style=\"color: blue;\">的</span><span style=\"color: orange;\">哟</span>"
        )
    }

    func testSize() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现"),
            "<span style=\"font-size: 10px;\">不同</span><span style=\"font-size: 14px;\">大小的</span><span style=\"font-size: 18px;\">文字</span>效果也可实现"
        )
    }

    func testSizeWithNewlineBeforeClosingTag() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[size=5]2025.1.6 \n全文更新完毕[/size]"),
            "<span style=\"font-size: large;\">2025.1.6 <br>全文更新完毕</span>"
        )
    }

    func testSizeWithPercentage() {
        XCTAssertEqual(
            try renderBBCodeToHTML(
                "[size=100]正常大小[/size][size=150]放大1.5倍[/size][size=50]缩小一半[/size]"),
            "<span style=\"font-size: 100%;\">正常大小</span><span style=\"font-size: 150%;\">放大1.5倍</span><span style=\"font-size: 50%;\">缩小一半</span>"
        )
    }

    func testSizeWithPxSuffix() {
        XCTAssertEqual(
            try renderBBCodeToHTML("[size=49px]49像素[/size][size=12px]12像素[/size]"),
            "<span style=\"font-size: 49px;\">49像素</span><span style=\"font-size: 12px;\">12像素</span>"
        )
    }

    func testLink() {
        XCTAssertEqual(
            try renderBBCodeToHTML("Bangumi 番组计划: [url]https://chii.in/[/url]"),
            "Bangumi 番组计划: <a href=\"https://chii.in/\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">https://chii.in/</a>"
        )
    }

    func testURL() {
        XCTAssertEqual(
            try renderBBCodeToHTML("带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]"),
            "带文字说明的网站链接：<a href=\"https://chii.in\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">Bangumi 番组计划</a>"
        )
    }

    func testImage() {
        XCTAssertEqual(
            try renderBBCodeToHTML("存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]"),
            "存放于其他网络服务器的图片：<img src=\"https://chii.in/img/ico/bgm88-31.gif\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
        )
    }

    func testImageWithSize() {
        XCTAssertEqual(
            try renderBBCodeToHTML(
                "存放于其他网络服务器的图片：[img=128,72]https://chii.in/img/ico/bgm88-31.gif[/img]"
            ),
            "存放于其他网络服务器的图片：<img src=\"https://chii.in/img/ico/bgm88-31.gif\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"128\" height=\"72\" />"
        )
    }

    func testImageInsideTextStyleTag() {
        XCTAssertEqual(
            try renderBBCodeToHTML(
                "[font=Arial][img]https://chii.in/img/ico/bgm88-31.gif[/img][/font]"),
            "<span style=\"font-family: Arial;\"><img src=\"https://chii.in/img/ico/bgm88-31.gif\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" /></span>"
        )
    }

    func testCode() {
        XCTAssertEqual(
            try renderBBCodeToHTML("代码片段：[code]print(\"Hello, World!\")[/code]"),
            "代码片段：<div class=\"code\"><pre><code>print(&quot;Hello, World!&quot;)</code></pre></div>"
        )
    }

    func testQuote() {
        XCTAssertEqual(
            try renderBBCodeToHTML("引用文字：[quote]这是一段引用文字[/quote]"),
            "引用文字：<div class=\"quote\"><blockquote>这是一段引用文字</blockquote></div>"
        )
    }

    func testParenthesesAtEnd() {
        // Test case for text ending with '(' that should be treated as plain text
        XCTAssertEqual(
            try renderBBCodeToHTML("这是一些文字("),
            "这是一些文字("
        )
    }

    func testParenthesesAtEndWithNewline() {
        // Test case for text ending with '(' followed by newline
        XCTAssertEqual(
            try renderBBCodeToHTML("这是一些文字(\n"),
            "这是一些文字(<br>"
        )
    }

    func testParenthesesAtEndWithCarriageReturn() {
        // Test case for text ending with '(' followed by carriage return
        XCTAssertEqual(
            try renderBBCodeToHTML("这是一些文字(\r"),
            "这是一些文字(<br>"
        )
    }

    func testParenthesesAtEndWithCarriageReturnNewline() {
        // Test case for text ending with '(' followed by CRLF
        XCTAssertEqual(
            try renderBBCodeToHTML("这是一些文字(\r\n"),
            "这是一些文字(<br>"
        )
    }

    func testParenthesesAtEndWithContent() {
        // Test case for text ending with '(' that has some content but no closing ')'
        XCTAssertEqual(
            try renderBBCodeToHTML("这是一些文字(bgm"),
            "这是一些文字(bgm"
        )
    }

    func testFont() {
        XCTAssertEqual(
            try renderBBCodeToHTML("使用字体：[font=Arial]这是Arial[font=宋体]字体[/font][/font]"),
            "使用字体：<span style=\"font-family: Arial;\">这是Arial<span style=\"font-family: 宋体;\">字体</span></span>"
        )
    }

    func testGreaterThanSymbol() {
        // 测试 > 符号应该被正确编码成 &gt;，而不是 &amp;gt;
        XCTAssertEqual(
            try renderBBCodeToHTML("【内容简介】>>>>>"),
            "【内容简介】&gt;&gt;&gt;&gt;&gt;"
        )
    }

    func testLessThanSymbol() {
        // 测试 < 符号应该被正确编码成 &lt;，而不是 &amp;lt;
        XCTAssertEqual(
            try renderBBCodeToHTML("数字 1 < 2"),
            "数字 1 &lt; 2"
        )
    }

    func testAmpersandSymbol() {
        // 测试 & 符号应该被正确编码成 &amp;
        XCTAssertEqual(
            try renderBBCodeToHTML("A & B"),
            "A &amp; B"
        )
    }

    func testGreaterThanInTag() {
        // 测试 BBCode 标签内的 > 符号
        XCTAssertEqual(
            try renderBBCodeToHTML("这是[b]粗体>>>>>[/b]文字"),
            "这是<strong>粗体&gt;&gt;&gt;&gt;&gt;</strong>文字"
        )
    }

    func testAlreadyEncodedGreaterThan() {
        // 测试输入中已经转义的 HTML 实体 - 应该被正确处理而不是二次编码
        XCTAssertEqual(
            try renderBBCodeToHTML("&gt;&gt;&gt;&gt;&gt;【内容简介】&lt;&lt;&lt;&lt;&lt;"),
            "&gt;&gt;&gt;&gt;&gt;【内容简介】&lt;&lt;&lt;&lt;&lt;"
        )
    }

    func testAlreadyEncodedHTMLInTag() {
        // 测试 BBCode 标签内已经转义的 HTML 实体
        XCTAssertEqual(
            try renderBBCodeToHTML("[b]&gt;&gt;&gt;&gt;&gt;[/b]"),
            "<strong>&gt;&gt;&gt;&gt;&gt;</strong>"
        )
    }

    func testAlreadyEncodedAmpersand() {
        // 测试已转义的 & 符号
        XCTAssertEqual(
            try renderBBCodeToHTML("A &amp; B"),
            "A &amp; B"
        )
    }

    func testAlreadyEncodedQuote() {
        // 测试已转义的引号
        XCTAssertEqual(
            try renderBBCodeToHTML("He said &quot;Hello&quot;"),
            "He said &quot;Hello&quot;"
        )
    }

    func testMixedEncodedAndNormal() {
        // 测试混合已转义和未转义的字符
        XCTAssertEqual(
            try renderBBCodeToHTML("This & That &gt; More &lt; Less"),
            "This &amp; That &gt; More &lt; Less"
        )
    }
    func testHTMLInBBCode1() {
        // 测试输入中包含 HTML 标签 - 应该被正确转义而不是直接渲染
        XCTAssertEqual(
            try renderBBCodeToHTML(
                """
                <iframe width="100%" height="495" src="//player.bilibili.com/player.html?isOutside=true&amp;aid=113990931845617&amp;bvid=BV1BSKLejESd&amp;cid=28355461245&amp;p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>
                """
            ),
            """
            <iframe width="100%" height="495" src="//player.bilibili.com/player.html?isOutside=true&amp;aid=113990931845617&amp;bvid=BV1BSKLejESd&amp;cid=28355461245&amp;p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>
            """
        )
    }
    func testHTMLInBBCode2() {
        // 测试输入中包含 HTML 标签 - 应该被正确转义而不是直接渲染
        XCTAssertEqual(
            try renderBBCodeToHTML(
                """
                [align=center]<iframe width="100%" height="495" src="//player.bilibili.com/player.html?isOutside=true&amp;aid=113990931845617&amp;bvid=BV1BSKLejESd&amp;cid=28355461245&amp;p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>[/align]
                [align=center]APP端请[url=https://www.bilibili.com/video/BV1BSKLejESd/?spm_id_from=333.999.0.0]点击此处[/url]跳转观看[/align]
                期望越大，失望越大！
                留给谷川流用来偷懒的旧短篇已经所剩不多喽
                """
            ),
            """
            <p style="text-align: center;"><iframe width="100%" height="495" src="//player.bilibili.com/player.html?isOutside=true&amp;aid=113990931845617&amp;bvid=BV1BSKLejESd&amp;cid=28355461245&amp;p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe></p><p style="text-align: center;">APP端请<a href="https://www.bilibili.com/video/BV1BSKLejESd/?spm_id_from=333.999.0.0" target="_blank" rel="nofollow external noopener noreferrer">点击此处</a>跳转观看</p>期望越大，失望越大！<br>留给谷川流用来偷懒的旧短篇已经所剩不多喽
            """
        )
    }
    func testHTMLInBBCode3() {
        // 测试输入中包含 HTML 标签 - 应该被正确转义而不是直接渲染
        XCTAssertEqual(
            try renderBBCodeToHTML(
                """
                第二卷的剧情马马虎虎，第三卷实在是看不懂前女友的行为，也是越来越抽象了，感觉所有行为都是党争驱动的<img src=\"https://static.lightnovel.fun/smiley/luck/ls17.GIF\" width=\"50\"/>而且又有学生加入了战场了，又来到了大家喜闻乐见的党政环境，已经没什么第一卷的背德感了，不过从第一卷的跟踪剧情就初见端倪了...<br>我还以为只是因为台版只出道了第三卷，又去搜了一下，似乎亚马逊上也只有三卷，而且还是24年7月更新的，作者到底在干什么，难不成真的没活了吧<img src=\"https://static.lightnovel.fun/smiley/luck/ls1.GIF\" width=\"50\"/>
                """
            ),
            """
            第二卷的剧情马马虎虎，第三卷实在是看不懂前女友的行为，也是越来越抽象了，感觉所有行为都是党争驱动的<img src=\"https://static.lightnovel.fun/smiley/luck/ls17.GIF\" width=\"50\"/>而且又有学生加入了战场了，又来到了大家喜闻乐见的党政环境，已经没什么第一卷的背德感了，不过从第一卷的跟踪剧情就初见端倪了...<br>我还以为只是因为台版只出道了第三卷，又去搜了一下，似乎亚马逊上也只有三卷，而且还是24年7月更新的，作者到底在干什么，难不成真的没活了吧<img src=\"https://static.lightnovel.fun/smiley/luck/ls1.GIF\" width=\"50\"/>
            """
        )
    }

}
