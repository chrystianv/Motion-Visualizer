import SwiftUI

struct ChallengeListView: View {
    @State private var completedLevels: Set<Int> = []
    private let progress = ChallengeProgress()

    var body: some View {
        NavigationStack {
            List(MotionChallenge.all) { challenge in
                NavigationLink {
                    ChallengeRunView(challenge: challenge)
                } label: {
                    HStack {
                        Text("Level \(challenge.id)")
                        Spacer()
                        Text("\(Int(challenge.duration)) s")
                            .foregroundStyle(.secondary)
                        if completedLevels.contains(challenge.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("Challenges")
            .onAppear {
                completedLevels = progress.completedLevels()
            }
        }
    }
}

struct ChallengeRunView: View {
    @StateObject private var cameraManager: CameraManager
    @StateObject private var runner: ChallengeRunner

    init(challenge: MotionChallenge) {
        _cameraManager = StateObject(wrappedValue: CameraManager())
        _runner = StateObject(wrappedValue: ChallengeRunner(challenge: challenge))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(arSession: cameraManager.arSession)
                    .ignoresSafeArea()

                Image(systemName: "scope")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .position(cameraManager.targetPosition)

                VStack(spacing: 12) {
                    HStack {
                        Text("Level \(runner.challenge.id)")
                        Spacer()
                        Text(String(format: "%.2f m", runner.currentDistance))
                    }
                    .font(.headline)

                    ChallengePlot(
                        challenge: runner.challenge,
                        samples: runner.userPath
                    )
                    .frame(height: 220)

                    HStack {
                        Text(statusText)
                        Spacer()
                        Text(String(format: "%.1f / %.0f s", runner.elapsedTime, runner.challenge.duration))
                    }
                    .font(.subheadline.monospacedDigit())

                    Button(action: primaryAction) {
                        Text(buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCountingDown)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
                .frame(maxHeight: .infinity, alignment: .bottom)

                if case let .countdown(value) = runner.state {
                    Text("\(value)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        cameraManager.updateTargetPosition(value.location)
                    }
            )
            .onAppear {
                cameraManager.startSession()
            }
            .onDisappear {
                runner.cancel()
                cameraManager.stopSession()
            }
            .onReceive(cameraManager.$distanceInMeters) { distance in
                runner.updateDistance(distance)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isCountingDown: Bool {
        if case .countdown = runner.state { return true }
        return false
    }

    private var buttonTitle: String {
        switch runner.state {
        case .ready: "Start"
        case .countdown: "Get Ready"
        case .running: "Stop"
        case .finished: "Try Again"
        }
    }

    private var statusText: String {
        switch runner.state {
        case .ready: "Match the target line"
        case .countdown: "Get ready"
        case .running: "Move with the line"
        case let .finished(result): result.passed ? "Passed · \(result.score)%" : "Score · \(result.score)%"
        }
    }

    private func primaryAction() {
        switch runner.state {
        case .ready, .finished:
            runner.start()
        case .running:
            runner.stop()
        case .countdown:
            break
        }
    }
}

private struct ChallengePlot: View {
    let challenge: MotionChallenge
    let samples: [ChallengeSample]

    var body: some View {
        Canvas { context, size in
            let target = challenge.targetPath()
            var targetPath = Path()
            for (index, point) in target.enumerated() {
                let mapped = map(time: point.x, position: point.y, into: size)
                if index == 0 {
                    targetPath.move(to: mapped)
                } else {
                    targetPath.addLine(to: mapped)
                }
            }
            context.stroke(targetPath, with: .color(.purple), lineWidth: 4)

            var userPath = Path()
            for (index, sample) in samples.enumerated() {
                let mapped = map(time: sample.time, position: sample.position, into: size)
                if index == 0 {
                    userPath.move(to: mapped)
                } else {
                    userPath.addLine(to: mapped)
                }
            }
            context.stroke(userPath, with: .color(.white), style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
        }
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func map(time: Double, position: Double, into size: CGSize) -> CGPoint {
        let x = size.width * time / challenge.duration
        let y = size.height * (1 - min(max(position / 2.6, 0), 1))
        return CGPoint(x: x, y: y)
    }
}
