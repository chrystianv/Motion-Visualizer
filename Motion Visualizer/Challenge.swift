import CoreGraphics
import Foundation

struct MotionChallenge: Identifiable, Equatable {
    let id: Int
    let duration: TimeInterval

    static let all = (1...14).map { level in
        MotionChallenge(
            id: level,
            duration: [7, 8, 13, 14].contains(level) ? 10 : level == 12 ? 4 : 5
        )
    }

    func targetPosition(at time: TimeInterval) -> Double {
        switch id {
        case 1: -0.20 * time + 2.0
        case 2: -0.40 * time + 2.0
        case 3: -0.30 * time + 2.5
        case 4: -0.30 * time + 1.5
        case 5: 0.30 * time
        case 6: 0.50 * time
        case 7:
            time <= 5 ? 0.4 * time : time <= 8 ? 2.0 : -0.4 * time + 5.2
        case 8:
            time <= 3 ? 2.5 : time <= 8 ? -0.5 * time + 4.0 : 0.25 * time - 2.0
        case 9: 0.105 * time * time
        case 10: -0.105 * time * time + time
        case 11: -0.080 * time * time + 2.0
        case 12: 0.125 * time * time - time + 2.0
        case 13: time - 0.1 * time * time
        case 14: 2.5 - time + 0.1 * time * time
        default: 0
        }
    }

    func targetPath(pointCount: Int = 101) -> [CGPoint] {
        guard pointCount > 1 else { return [] }
        return (0..<pointCount).map { index in
            let time = duration * Double(index) / Double(pointCount - 1)
            return CGPoint(x: time, y: targetPosition(at: time))
        }
    }
}

struct ChallengeSample: Equatable {
    let time: TimeInterval
    let position: Double
}

struct ChallengeResult: Equatable {
    let score: Int
    let passed: Bool
    let samples: [ChallengeSample]
}

enum ChallengeScorer {
    static func score(_ samples: [ChallengeSample], for challenge: MotionChallenge) -> ChallengeResult {
        let validSamples = samples.filter {
            $0.time >= 0 && $0.time <= challenge.duration + 0.2 && $0.position.isFinite && $0.position > 0
        }
        guard validSamples.count >= 10 else {
            return ChallengeResult(score: 0, passed: false, samples: validSamples)
        }

        let total = validSamples.reduce(0.0) { partial, sample in
            let error = abs(sample.position - challenge.targetPosition(at: sample.time))
            if error < 0.20 {
                return partial + 1
            }
            if error < 0.30 {
                return partial + (0.30 - error) / 0.10
            }
            return partial
        }
        let score = Int((total / Double(validSamples.count) * 100).rounded())
        return ChallengeResult(score: score, passed: score >= 80, samples: validSamples)
    }
}

final class ChallengeProgress {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isComplete(_ challenge: MotionChallenge) -> Bool {
        defaults.bool(forKey: key(for: challenge))
    }

    func markComplete(_ challenge: MotionChallenge) {
        defaults.set(true, forKey: key(for: challenge))
    }

    func completedLevels() -> Set<Int> {
        Set(MotionChallenge.all.filter(isComplete).map(\.id))
    }

    private func key(for challenge: MotionChallenge) -> String {
        "motionChallenge.\(challenge.id).complete"
    }
}
