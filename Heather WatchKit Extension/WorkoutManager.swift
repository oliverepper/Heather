//
//  WorkoutController.swift
//  Heather WatchKit Extension
//
//  Created by Oliver Epper on 05.10.20.
//

import Foundation
import HealthKit
import os.log
import Combine

final class WorkoutManager: NSObject, ObservableObject {
    @Published var heartRate = 0
    @Published var elapsedSeconds = 0
    @Published var elapsedTime = ""
    @Published var isRunning: Bool? = nil

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var cancellables = Set<AnyCancellable>()

    // Timer
    private var start = Date()
    private var accumulatedTime = 0

    private let timeIntervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .dropAll
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()

    private func setupTimer() {
        os_log("Setup Timer")
        start = Date()
        Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.elapsedSeconds = self.incrementElapsedTime()
                self.elapsedTime = self.timeIntervalFormatter.string(from: TimeInterval(self.elapsedSeconds)) ?? ""
            }.store(in: &cancellables)
    }

    func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { sucess, error in
            if let error = error {
                os_log("Error: %@", error.localizedDescription)
                return
            }
            os_log("Authorization granted")
        }
    }

    func startWorkout() {
        os_log("Starting workout")
        isRunning = true
        setupTimer()
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            os_log("%@", error.localizedDescription)
        }

        session?.delegate = self
        builder?.delegate = self

        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        session?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { (success, error) in
            if let e = error {
                os_log("%@", e.localizedDescription)
            }
        }
    }

    func pauseWorkout() {
        os_log("Pause workout")
        isRunning = false
        session?.pause()
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        accumulatedTime = elapsedSeconds
    }

    func resumeWorkout() {
        os_log("Resume workout")
        isRunning = true
        setupTimer()
        session?.resume()
    }
    
    func endWorkout() {
        os_log("End workout")
        if let _ = isRunning {
            session?.end()
            cancellables.forEach { cancellable in
                cancellable.cancel()
            }
        }
        isRunning = nil
    }

    func update(_ stats: HKStatistics?) {
        os_log("Updating stats")
        guard let stats = stats else { return }
        switch stats.quantityType {
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = stats.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
            guard let heartRate = value else { return }
            DispatchQueue.main.async {
                self.heartRate = Int(heartRate)
            }
        default:
            return
        }
    }

    private lazy var configuration: HKWorkoutConfiguration = {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        return config
    }()

    private func incrementElapsedTime() -> Int {
        let runningTime = Int(-1 * self.start.timeIntervalSinceNow)
        return self.accumulatedTime + runningTime
    }

    private func resetWorkout() {
        DispatchQueue.main.async {
            self.elapsedTime = ""
            self.elapsedSeconds = 0
            self.heartRate = 0
        }
    }
}


extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .notStarted:
            os_log("Not started")
        case .prepared:
            os_log("Prepared")
        case .running:
            os_log("Running")
        case .paused:
            os_log("Paused")
        case .ended:
            os_log("Ended")
            builder?.endCollection(withEnd: Date()) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    self.resetWorkout()
                }
            }
        case .stopped:
            os_log("Stopped")
        default:
            fatalError("Unknown state")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        os_log("Error: %@", error.localizedDescription)
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            let stats = workoutBuilder.statistics(for: quantityType)
            update(stats)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
