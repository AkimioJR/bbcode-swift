import BBCodeParser
import Benchmark
import Foundation

let benchmarks: @Sendable () -> Void = {
    Benchmark("Sync Render HTML") { benchmark throws in
        // 准备工作
        guard
            let resourceURL = Bundle.module.url(
                forResource: "benchmark",
                withExtension: "bbcode"
            )
        else {
            fatalError("failed to find test resource benchmark.bbcode")
        }

        let bbcodeString = try String(contentsOf: resourceURL, encoding: .utf8)

        // 测量
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let html = try renderBBCodeToHTML(bbcodeString)
            blackHole(html)
        }
        benchmark.stopMeasurement()
    }

    // Benchmark("Async Render HTML") { benchmark async throws in
    //     // 准备工作
    //     guard
    //         let resourceURL = Bundle.module.url(
    //             forResource: "benchmark",
    //             withExtension: "bbcode"
    //         )
    //     else {
    //         fatalError("无法找到测试资源文件 benchmark.bbcode")
    //     }

    //     guard let bbcodeString = try? String(contentsOf: resourceURL, encoding: .utf8) else {
    //         fatalError("无法读取 benchmark.bbcode 文件内容")
    //     }

    //     guard let node = try? parseBBCodeForHTML(bbcodeString) else {
    //         fatalError("解析 benchmark.bbcode 失败")
    //     }

    //     // 预热
    //     let _ = await renderBBNodeToHTML(node)

    //     // 测量
    //     benchmark.startMeasurement()
    //     for _ in benchmark.scaledIterations {
    //         let html = await renderBBNodeToHTML(node)
    //         blackHole(html)
    //     }
    //     benchmark.stopMeasurement()
    // }
}
