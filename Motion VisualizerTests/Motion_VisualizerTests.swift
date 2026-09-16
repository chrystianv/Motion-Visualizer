import XCTest
@testable import Motion_Visualizer

final class Motion_VisualizerTests: XCTestCase {
    func testCatalogContainsFourteenLevels() {
        XCTAssertEqual(MotionChallenge.all.map(\.id), Array(1...14))
    }

    func testLongLevelsUseTenSeconds() {
        let durations = Dictionary(uniqueKeysWithValues: MotionChallenge.all.map { ($0.id, $0.duration) })
        XCTAssertEqual(durations[7], 10)
        XCTAssertEqual(durations[8], 10)
        XCTAssertEqual(durations[13], 10)
        XCTAssertEqual(durations[14], 10)
    }

    func testLevelSevenPiecewiseCurve() throws {
        let challenge = try XCTUnwrap(MotionChallenge.all.first { $0.id == 7 })
        XCTAssertEqual(challenge.targetPosition(at: 5), 2, accuracy: 0.0001)
        XCTAssertEqual(challenge.targetPosition(at: 8), 2, accuracy: 0.0001)
        XCTAssertEqual(challenge.targetPosition(at: 10), 1.2, accuracy: 0.0001)
    }

    func testExactPathPasses() throws {
        let challenge = try XCTUnwrap(MotionChallenge.all.first)
        let samples = (0..<50).map { index in
            let time = challenge.duration * Double(index) / 49
            return ChallengeSample(time: time, position: challenge.targetPosition(at: time))
        }
        let result = ChallengeScorer.score(samples, for: challenge)
        XCTAssertEqual(result.score, 100)
        XCTAssertTrue(result.passed)
    }

    func testDistantPathFails() throws {
        let challenge = try XCTUnwrap(MotionChallenge.all.first)
        let samples = (0..<50).map { index in
            let time = challenge.duration * Double(index) / 49
            return ChallengeSample(time: time, position: challenge.targetPosition(at: time) + 0.5)
        }
        let result = ChallengeScorer.score(samples, for: challenge)
        XCTAssertEqual(result.score, 0)
        XCTAssertFalse(result.passed)
    }
}
