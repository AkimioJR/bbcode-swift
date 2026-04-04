#if os(iOS)
  import WebKit
  import SwiftUI

  /// 行内 WebView
  /// 相比 WKWebView，InlineWebView 不带滚动条
  /// 且高度根据内容自动调整，适合在 SwiftUI 中嵌入 HTML 内容
  /// 内容比较多时，建议外层包裹 ScrollView 来支持整体滚动
  class InlineWebView: WKWebView {

    init(frame: CGRect) {
      let prefs = WKWebpagePreferences()
      prefs.allowsContentJavaScript = true
      let config = WKWebViewConfiguration()
      config.defaultWebpagePreferences = prefs
      super.init(frame: frame, configuration: config)
      self.scrollView.bounces = false
      self.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
      self.scrollView.isScrollEnabled = false
      return self.scrollView.contentSize
    }
  }

  extension InlineWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript(
        "document.readyState",
        completionHandler: { (_, _) in
          webView.invalidateIntrinsicContentSize()
        })
    }
  }

  struct WebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> InlineWebView {
      return InlineWebView(frame: .zero)
    }

    func updateUIView(_ uiView: InlineWebView, context: Context) {
      uiView.loadHTMLString(html, baseURL: nil)
    }
  }

  #Preview {
    let html = """
      <!doctype html>
      <html>

      <head>
        <meta charset="utf-8">
        <meta name='viewport' content='width=device-width, shrink-to-fit=YES' initial-scale='1.0' maximum-scale='1.0'
          minimum-scale='1.0' user-scalable='no'>
        <style type="text/css">
          /* 根变量配置：自动适配系统深色/浅色模式 */
          :root {
            color-scheme: light dark;
          }

          img {
            max-width: 100%; /* 最大宽度100% → 永远不会超出屏幕/容器宽度 */
            height: auto; /* 高度自动 → 保持图片原始比例，不变形拉伸 */
          }

          /* 列表项：最后一个li下方增加间距，排版更松散 */
          li:last-child {
            margin-bottom: 1em;
          }

          /* 链接样式 */
          a {
            color: #0084B4; /* 设置颜色 */
            text-decoration: none; /* 去掉下划线 */
          }

         /****************************************************************************
          * 马赛克遮罩文字（hover 显示）
          * 默认背景色和文字色一致，隐藏内容；鼠标悬停显示白色文字
          ***************************************************************************/
          span.mask {
            background-color: #555;
            color: #555;
            border-radius: 2px;
            box-shadow: #555 0 0 5px;
            -webkit-transition: all .5s linear;
            /* 平滑过渡动画 */
          }

          /* 鼠标悬浮在马赛克文字上时，显示文字 */
          span.mask:hover {
            color: #FFF;
          }

          /* 代码块样式：边框、圆角、内边距、滚动条 */
          pre code {
            border: 1px solid #EEE;
            border-radius: 0.5em;
            padding: 1em;
            display: block;
            overflow: auto;
          }

          /* 引用块样式：文字颜色偏灰 */
          blockquote {
            display: inline-block;
            color: #666;
          }

          /* 引用块左侧引号 */
          blockquote:before {
            content: open-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: -0.5em;
            color: #CCC;
            font-size: 1em;
          }

          /* 引用块右侧引号 */
          blockquote:after {
            content: close-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: 0.5em;
            color: #CCC;
            font-size: 1em;
          }
        </style>
      </head>

      <body>
        我是<strong>粗体字</strong><br>我是<em>斜体字</em><br>我是<u>下划线文字</u><br>我是<del>删除线文字</del><br><p style="text-align: center;">居中文字</p><p style="text-align: left;">居左文字</p><p style="text-align: right;">居右文字</p>我是<span class="mask">马赛克文字</span>我是<span style="color: red;">彩</span><span style="color: green;">色</span><span style="color: blue;">的</span><span style="color: orange;">哟</span><br><span style="font-size: 10px;">不同</span><span style="font-size: 14px;">大小的</span><span style="font-size: 18px;">文字</span>效果也可实现<br>Bangumi 番组计划: <a href="https://chii.in/" target="_blank" rel="nofollow external noopener noreferrer">https://chii.in/</a><br>带文字说明的网站链接：<a href="https://chii.in" target="_blank" rel="nofollow external noopener noreferrer">Bangumi 番组计划</a><br>存放于其他网络服务器的图片：<img src="https://chii.in/img/ico/bgm88-31.gif" rel="noreferrer" referrerpolicy="no-referrer" alt="" />代码片段：<div class="code"><pre><code>print(&quot;Hello, World!&quot;)</code></pre></div><div class="quote"><blockquote>引用的片段</blockquote></div>(bgm38) (bgm24)<br>[photo=104569]4b/d1/873244_3p4I7.jpg[/photo]<br>[subject=12]&#12385;&#12355;&#12391;&#12363;&#12369;&#12427;[/subject]<br>[user=873244]五月雨[/user]</p><p>传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，<em>后被我们的本须和秀树发现，<del>并抱<u>回家</u></del></em>。<span style="color: red;">由于开始时唧只会<strong>&#39;唧，唧&#39;</strong>的这样叫</span>，所以秀树为其取名 &#39;唧&#39; <span class="mask">TV版第二话「<del>&#12385;&#12355;&#12391;&#12363;&#12369;&#12427;</del>」</span>时发现小唧本身并没有安OS，不过因为拥有&#8220;学习程式&#8221;，所以可以通过对话和教导让她&#8216;成长&#8217;起来 (bgm38)。</p><p>ruby测试1：<ruby>朝<rp>(</rp><rt>&#12354;&#12373;</rt><rp>)</rp></ruby>ruby测试2:<ruby>&#12354;&#12356;&#12358;&#12360;&#12362;<rp>(</rp><rt>a i u e o</rt><rp>)</rp></ruby><br>「诶。那就<ruby>怪物指名<rp>(</rp><rt>&#12490;&#12531;&#12472;&#12515;&#12514;&#12531;&#12472;&#12515;</rt><rp>)</rp></ruby>，<ruby>僵尸感染派对<rp>(</rp><rt>&#12478;&#12531;&#12363;&#12414;&#12497;&#8212;&#12486;&#12451;&#8212;</rt><rp>)</rp></ruby>和UNO吧。」（注：这几个游戏的平均游戏时长都在10分钟之内。）<br><img src="https://res.lightnovel.fun/recom/547ab9485bccf42ce89a2e7d0179d203.jpg?m=blixhTqqgXFPldam-Itw0Q&amp;t=1774346959" rel="noreferrer" referrerpolicy="no-referrer" alt="" />
      </body>

      </html>
      """

    ScrollView {
      WebView(html: html)
        .padding(.horizontal, 8)
    }
    .ignoresSafeArea()
  }
#endif
