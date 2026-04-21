//
//  BBCodeWebView.swift
//  BBCode
//
//  Created by 秋澪 on 2026/4/4.
//

import BBCodeParser
import SwiftUI

public struct BBCodeWebView: View {
  let bbcode: String?
  @State private var htmlContent: String? = nil
  @State private var isConverting: Bool = false

  public init(_ bbcode: String?) {
    self.bbcode = bbcode
  }

  public var body: some View {
    Group {
      if isConverting {
        ProgressView()
        // } else if let html = htmlContent, bbcode != nil {
        //   WebView(html: html)
      } else {
        Text("没有内容可显示")
          .bold()
          .font(.title3)
      }
    }
    // 当 bbcode 的值发生变化时，触发异步任务
    .task(id: bbcode) {
      await processBBCode()
    }
  }

  private func processBBCode() async {
    guard let bbcode = bbcode else {  // 如果输入为空，清空内容并重置状态
      htmlContent = nil
      isConverting = false
      return
    }

    isConverting = true  // 开始转换，显示 ProgressView

    let convertedHTML = await generateHTML(from: bbcode)

    // 转换完成，如果不检查 Task.isCancelled，SwiftUI 的 .task(id:)
    // 也会在底层处理，但为了更严谨，我们可以确保任务未被取消才更新 UI
    if !Task.isCancelled {
      htmlContent = convertedHTML
      isConverting = false
    }
  }
}

func generateHTML(from bbcode: String) async -> String {
  // 使用 Task.detached 彻底脱离主线程 (MainActor) 上下文
  return await Task.detached(priority: .high) {
    let body: String
    do {
      body = try renderBBCodeToHTML(bbcode)
    } catch {
      // 解析失败时返回一个简单的错误提示 HTML
      body = "<p style='color:red;'>BBCode 解析失败: \(error.localizedDescription)</p>"
    }

    return """
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
        \(body)
      </body>

      </html>
      """
  }.value
}

#Preview {
  @Previewable @State var currentValue: String? = nil

  let example = """
    我是[b]粗体字[/b]
    我是[i]斜体字[/i]
    我是[u]下划线文字[/u]
    我是[s]删除线文字[/s]
    [center]居中文字[/center]
    [left]居左文字[/left]
    [right]居右文字[/right]
    我是[mask]马赛克文字[/mask]
    我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]
    [size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现
    Bangumi 番组计划: [url]https://chii.in/[/url]
    带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]
    存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]
    代码片段：[code]print("Hello, World!")[/code]
    [quote]引用的片段[/quote]
    (bgm38) (bgm24)
    [photo=104569]4b/d1/873244_3p4I7.jpg[/photo]
    [subject=12]ちぃでかける[/subject]
    [user=873244]五月雨[/user]

    传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，[i]后被我们的本须和秀树发现，[s]并抱[u]回家[/u][/s][/i]。[color=red]由于开始时唧只会[b]'唧，唧'[/b]的这样叫[/color]，所以秀树为其取名 '唧' [mask]TV版第二话「[s]ちぃでかける[/s]」[/mask]时发现小唧本身并没有安OS，不过因为拥有“学习程式”，所以可以通过对话和教导让她‘成长’起来 (bgm38)。

    ruby测试1：[ruby=あさ]朝[/ruby]ruby测试2:[ruby=a i u e o]あいうえお[/ruby]
    「诶。那就[ruby=ナンジャモンジャ]怪物指名[/ruby]，[ruby=ゾンかまパ—ティ—]僵尸感染派对[/ruby]和UNO吧。」（注：这几个游戏的平均游戏时长都在10分钟之内。）
    [img]https://res.lightnovel.fun/recom/547ab9485bccf42ce89a2e7d0179d203.jpg?m=blixhTqqgXFPldam-Itw0Q&t=1774346959[/img]
    """

  ScrollView {
    Picker("内容切换", selection: $currentValue) {
      Text("Nil (加载)").tag(String?.none)
      Text("BBCode 内容").tag(String?.some(example))
    }
    .pickerStyle(.segmented)
    .padding()

    // 主体视图
    BBCodeWebView(currentValue)
  }
}
