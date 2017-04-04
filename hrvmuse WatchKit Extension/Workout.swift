//
//  Workout.swift
//  hrvmuse
//
//  Created by René van Mil on 31-03-17.
//

import WatchKit
import HealthKit

class Workout: NSObject, HKWorkoutSessionDelegate {
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    
    var heartRateQuery: HKQuery?
    let heartRateUnit = HKUnit(from: "count/min")
    
    var previousTimestamp: Int64 = 0
    
    override init() {
        super.init()
        requestAuthorizationForHealth()
    }
    
    func start() {
        guard session == nil else {
            print("workout already running")
            return
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .indoor
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
        } catch {
            fatalError("unable to create the workout session")
        }
        session!.delegate = self
        healthStore.start(session!)
    }
    
    func stop() {
        guard session != nil else {
            print("workout not running")
            return
        }
        healthStore.end(session!)
    }
    
    func handleWorkoutRunning(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            heartRateQuery = query
            healthStore.execute(query)
        } else {
            print("create heart rate query failed")
        }
    }
    
    func handleWorkoutEnded(_ date : Date) {
        guard heartRateQuery != nil else {
            print("heart rate query not available")
            return
        }
        healthStore.stop(heartRateQuery!)
        session = nil
    }
    
    // MARK: - Heart Rate Query
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        guard let heartRateQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            return nil
        }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        let heartRateQuery = HKAnchoredObjectQuery(type: heartRateQuantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            self.updateHeartRate(sampleObjects)
        }
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        guard let sample = heartRateSamples.first else {
            return
        }
        let value = sample.quantity.doubleValue(for: heartRateUnit)
        let hr = String(UInt16(value))
        
        let currentTimestamp = currentTimeMillis()
        let diff = (previousTimestamp == 0) ? 0 : currentTimestamp - previousTimestamp
        print(diff, " ms - ", hr, " bpm")
        previousTimestamp = currentTimestamp
    }
    
    func currentTimeMillis() -> Int64 {
        var darwinTime : timeval = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&darwinTime, nil)
        return (Int64(darwinTime.tv_sec) * 1000) + Int64(darwinTime.tv_usec / 1000)
    }
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workout failed")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("workout event")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("workout state change")
        switch toState {
        case .running:
            print("workout running")
            handleWorkoutRunning(date)
        case .paused:
            print("workout paused")
        case .notStarted:
            print("workout not started")
        case .ended:
            print("workout ended")
            handleWorkoutEnded(date)
        }
    }

    // MARK: - HealthKit
    
    func requestAuthorizationForHealth() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        // Due to privacy reasons we cannot check whether the permission to read the health data is already granted, so we simply always request authorization.
        // The user will only be presented with the permissions view the first time this is called.
        healthStore.requestAuthorization(toShare: nil, read: Set([heartRateType])) { (granted, error) in
            if (error != nil) {
                print("request authorization for health failed")
            } else {
                if (granted) {
                    // Authorization granted
                    print("request authorization for health granted")
                } else {
                    // Authorization denied
                    print("request authorization for health denied")
                }
            }
        }
    }

}
