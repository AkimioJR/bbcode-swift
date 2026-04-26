import BBCodeParser
import Benchmark
import Foundation

let benchmarks: @Sendable () -> Void = {
    Benchmark("Parse BBCode") { benchmark throws in
        guard
            let resourceURL = Bundle.module.url(
                forResource: "benchmark",
                withExtension: "bbcode"
            )
        else {
            fatalError("failed to find test resource benchmark.bbcode")
        }

        let bbcodeString = try String(contentsOf: resourceURL, encoding: .utf8)

        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let node = try BBCode().parse(bbcodeString)
            blackHole(node)
        }
        benchmark.stopMeasurement()
    }
}
