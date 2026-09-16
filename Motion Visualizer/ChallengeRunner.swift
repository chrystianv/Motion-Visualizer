import Combine
import Foundation
import UIKit

@MainActor
final class ChallengeRunner: ObservableObject {
    enum State: Equatable {
        case ready
        case countdown(Int)
        case running
        case finished(ChallengeResult)
    }

    @Published private(set) var state: State = .ready
    @Published private(set) var elapsedTime: TimeInterval = 0
    @Published private(set) var userPath: [ChallengeSample] = []
    @Published private(set) var currentDistance: Double = 0

    let challenge: MotionChallenge

    private let progress: ChallengeProgress
    private var countdownTask: Task<Void, Never>?
    private var timer: Timer?
    private var startTime: Date?
    private var depthBuffer: [Double] = []

    init(challenge: MotionChallenge, progress: ChallengeProgress = ChallengeProgress()) {
        self.challenge = challenge
        self.progress = progress
    }

    func updateDistance(_ distance: Float) {
        let value = Double(distance)
        guard value.isFinite && value > 0 && value <= 10 else { return }
        currentDistance = value
        depthBuffer.append(value)
        if depthBuffer.count > 3 {
            depthBuffer.removeFirst()
        }
    }

    func start() {
        cancelTimers()
        elapsedTime = 0
        userPath = []
        depthBuffer = []
        countdownTask = Task { [weak self] in
            for value in stride(from: 3, through: 1, by: -1) {
                guard let self, !Task.isCancelled else { return }
                state = .countdown(value)
                try? await Task.sleep(for: .seconds(1))
            }
            guard let self, !Task.isCancelled else { return }
            beginRun()
        }
    }

    func stop() {
        cancelTimers()
        elapsedTime = 0
        userPath = []
        state = .ready
    }

    func cancel() {
        cancelTimers()
    }

    private func beginRun() {
        startTime = Date()
        state = .running
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }

    private func sample() {
        guard state == .running, let startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
        if !depthBuffer.isEmpty {
            let position = depthBuffer.reduce(0, +) / Double(depthBuffer.count)
            userPath.append(ChallengeSample(time: min(elapsedTime, challenge.duration), position: position))
        }
        if elapsedTime >= challenge.duration {
            finish()
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        elapsedTime = challenge.duration
        let result = ChallengeScorer.score(userPath, for: challenge)
        if result.passed {
            progress.markComplete(challenge)
        }
        state = .finished(result)
        UINotificationFeedbackGenerator().notificationOccurred(result.passed ? .success : .error)
    }

    private func cancelTimers() {
        countdownTask?.cancel()
        countdownTask = nil
        timer?.invalidate()
        timer = nil
        startTime = nil
    }
}
