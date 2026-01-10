import Foundation
import HealthKit
import Flutter

class HealthKitBridge {
  private let healthStore = HKHealthStore()
  private var glucoseObserver: HKObserverQuery?
  private var weightObserver: HKObserverQuery?
  private var onBackgroundUpdateCallback: (() -> Void)?

  // MARK: - Check Availability

  static func isHealthDataAvailable() -> Bool {
    return HKHealthStore.isHealthDataAvailable()
  }

  // MARK: - Request Authorization

  func requestAuthorization(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    let readTypes: Set<HKObjectType> = [
      HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
      HKObjectType.quantityType(forIdentifier: .insulinDelivery)!,
      HKObjectType.workoutType(),
      HKObjectType.quantityType(forIdentifier: .stepCount)!,
      HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
      HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
      HKObjectType.quantityType(forIdentifier: .bodyMass)!,
      HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
      HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
      HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
    ]

    let writeTypes: Set<HKSampleType> = [
      HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
      HKObjectType.quantityType(forIdentifier: .insulinDelivery)!,
    ]

    healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(success)
        }
      }
    }
  }

  // MARK: - Test Write Permissions

  func testBloodGlucoseWritePermission(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
    let testDate = Date(timeIntervalSince1970: 946684800) // Jan 1, 2000
    let quantity = HKQuantity(unit: HKUnit(from: "mg/dL"), doubleValue: 1.0)

    let sample = HKQuantitySample(
      type: glucoseType,
      quantity: quantity,
      start: testDate,
      end: testDate
    )

    healthStore.save(sample) { success, error in
      if success {
        self.healthStore.delete(sample) { _, _ in
          DispatchQueue.main.async {
            result(true)
          }
        }
      } else {
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }

  func testInsulinWritePermission(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    let insulinType = HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!
    let testDate = Date(timeIntervalSince1970: 946684800) // Jan 1, 2000
    let quantity = HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: 0.1)

    let metadata: [String: Any] = [
      HKMetadataKeyInsulinDeliveryReason: HKInsulinDeliveryReason.bolus.rawValue
    ]

    let sample = HKQuantitySample(
      type: insulinType,
      quantity: quantity,
      start: testDate,
      end: testDate,
      metadata: metadata
    )

    healthStore.save(sample) { success, error in
      if success {
        self.healthStore.delete(sample) { _, _ in
          DispatchQueue.main.async {
            result(true)
          }
        }
      } else {
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }

  // MARK: - Write Blood Glucose

  func writeBloodGlucose(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let value = arguments["value"] as? Double,
          let startTime = arguments["startTime"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }

    let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
    let quantity = HKQuantity(unit: HKUnit(from: "mg/dL"), doubleValue: value)
    let date = Date(timeIntervalSince1970: startTime / 1000.0)

    var metadata: [String: Any]? = nil

    // Add meal time metadata if provided
    if let mealTime = arguments["mealTime"] as? String {
      switch mealTime {
      case "preprandial":
        metadata = [HKMetadataKeyBloodGlucoseMealTime: HKBloodGlucoseMealTime.preprandial.rawValue]
      case "postprandial":
        metadata = [HKMetadataKeyBloodGlucoseMealTime: HKBloodGlucoseMealTime.postprandial.rawValue]
      default:
        break
      }
    }

    let sample = HKQuantitySample(
      type: glucoseType,
      quantity: quantity,
      start: date,
      end: date,
      metadata: metadata
    )

    healthStore.save(sample) { success, error in
      DispatchQueue.main.async {
        if success {
          result(true)
        } else {
          result(FlutterError(
            code: "SAVE_FAILED",
            message: error?.localizedDescription ?? "Failed to save",
            details: nil
          ))
        }
      }
    }
  }

  // MARK: - Write Insulin

  func writeInsulin(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let value = arguments["value"] as? Double,
          let startTime = arguments["startTime"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }

    let insulinType = HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!
    let quantity = HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: value)
    let date = Date(timeIntervalSince1970: startTime / 1000.0)

    // Insulin requires delivery reason metadata
    let reason = arguments["reason"] as? String ?? "bolus"
    let metadata: [String: Any] = [
      HKMetadataKeyInsulinDeliveryReason: reason == "basal"
        ? HKInsulinDeliveryReason.basal.rawValue
        : HKInsulinDeliveryReason.bolus.rawValue
    ]

    let sample = HKQuantitySample(
      type: insulinType,
      quantity: quantity,
      start: date,
      end: date,
      metadata: metadata
    )

    healthStore.save(sample) { success, error in
      DispatchQueue.main.async {
        if success {
          result(true)
        } else {
          result(FlutterError(
            code: "SAVE_FAILED",
            message: error?.localizedDescription ?? "Failed to save",
            details: nil
          ))
        }
      }
    }
  }

  // MARK: - Read Health Data

  func readHealthData(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let typeString = arguments["type"] as? String,
          let startTime = arguments["startTime"] as? Double,
          let endTime = arguments["endTime"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }

    let startDate = Date(timeIntervalSince1970: startTime / 1000.0)
    let endDate = Date(timeIntervalSince1970: endTime / 1000.0)

    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )

    switch typeString {
    case "BLOOD_GLUCOSE":
      readQuantityData(
        type: .quantityType(forIdentifier: .bloodGlucose)!,
        predicate: predicate,
        unit: HKUnit(from: "mg/dL"),
        result: result
      )
    case "INSULIN_DELIVERY":
      readQuantityData(
        type: .quantityType(forIdentifier: .insulinDelivery)!,
        predicate: predicate,
        unit: HKUnit.internationalUnit(),
        result: result
      )
    case "STEPS":
      readQuantityData(
        type: .quantityType(forIdentifier: .stepCount)!,
        predicate: predicate,
        unit: HKUnit.count(),
        result: result
      )
    case "WEIGHT":
      readQuantityData(
        type: .quantityType(forIdentifier: .bodyMass)!,
        predicate: predicate,
        unit: HKUnit.gramUnit(with: .kilo),
        result: result
      )
    case "WATER":
      readQuantityData(
        type: .quantityType(forIdentifier: .dietaryWater)!,
        predicate: predicate,
        unit: HKUnit.literUnit(with: .milli),
        result: result
      )
    case "WORKOUT":
      readWorkouts(predicate: predicate, result: result)
    case "SLEEP":
      readSleep(predicate: predicate, result: result)
    case "MENSTRUATION":
      readMenstruation(predicate: predicate, result: result)
    case "MINDFULNESS":
      readMindfulness(predicate: predicate, result: result)
    default:
      result(FlutterError(code: "INVALID_TYPE", message: "Unsupported type: \(typeString)", details: nil))
    }
  }

  private func readQuantityData(
    type: HKQuantityType,
    predicate: NSPredicate,
    unit: HKUnit,
    result: @escaping FlutterResult
  ) {
    let query = HKSampleQuery(
      sampleType: type,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { _, samples, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        guard let samples = samples as? [HKQuantitySample] else {
          result([])
          return
        }

        let data = samples.map { sample -> [String: Any] in
          // Get source name, fallback to bundle identifier, then "Unknown"
          let source = sample.sourceRevision.source
          var sourceName: String
          if !source.name.isEmpty {
            sourceName = source.name
          } else if !source.bundleIdentifier.isEmpty {
            sourceName = source.bundleIdentifier
          } else {
            sourceName = "Unknown"
          }

          var dict: [String: Any] = [
            "value": sample.quantity.doubleValue(for: unit),
            "startTime": sample.startDate.timeIntervalSince1970 * 1000,
            "endTime": sample.endDate.timeIntervalSince1970 * 1000,
            "unit": unit.unitString,
            "dataSource": sourceName,
          ]

          // Add metadata if exists
          if let metadata = sample.metadata {
            if let mealTime = metadata[HKMetadataKeyBloodGlucoseMealTime] as? Int {
              if mealTime == HKBloodGlucoseMealTime.preprandial.rawValue {
                dict["mealTime"] = "preprandial"
              } else if mealTime == HKBloodGlucoseMealTime.postprandial.rawValue {
                dict["mealTime"] = "postprandial"
              }
            }
            if let reason = metadata[HKMetadataKeyInsulinDeliveryReason] as? Int {
              if reason == HKInsulinDeliveryReason.basal.rawValue {
                dict["reason"] = "basal"
              } else if reason == HKInsulinDeliveryReason.bolus.rawValue {
                dict["reason"] = "bolus"
              }
            }
          }

          return dict
        }

        result(data)
      }
    }

    healthStore.execute(query)
  }

  private func readWorkouts(predicate: NSPredicate, result: @escaping FlutterResult) {
    let query = HKSampleQuery(
      sampleType: HKWorkoutType.workoutType(),
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { _, samples, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        guard let workouts = samples as? [HKWorkout] else {
          result([])
          return
        }

        let data = workouts.map { workout -> [String: Any] in
          let source = workout.sourceRevision.source
          var sourceName: String
          if !source.name.isEmpty {
            sourceName = source.name
          } else if !source.bundleIdentifier.isEmpty {
            sourceName = source.bundleIdentifier
          } else {
            sourceName = "Unknown"
          }

          // Debug log workout details
          // print("[HealthKitBridge] Workout Details:")
          // print("  - Source: \(sourceName)")
          // print("  - Bundle ID: \(source.bundleIdentifier)")
          // print("  - Start: \(workout.startDate)")
          // print("  - Duration: \(workout.duration) seconds")
          // print("  - Activity Type Raw Value: \(workout.workoutActivityType.rawValue)")
          // print("  - Metadata: \(workout.metadata ?? [:])")

          return [
            "startTime": workout.startDate.timeIntervalSince1970 * 1000,
            "endTime": workout.endDate.timeIntervalSince1970 * 1000,
            "workoutActivityType": workout.workoutActivityType.rawValue,
            "duration": workout.duration,
            "totalEnergyBurned": workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
            "totalDistance": workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
            "dataSource": sourceName,
          ]
        }

        result(data)
      }
    }

    healthStore.execute(query)
  }

  private func readSleep(predicate: NSPredicate, result: @escaping FlutterResult) {
    let query = HKSampleQuery(
      sampleType: HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { _, samples, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        guard let samples = samples as? [HKCategorySample] else {
          result([])
          return
        }

        // Filter to only include "inBed" samples
        // inBed represents the total time in bed, which includes all sleep stages
        let sleepSamples = samples.filter { sample in
          let value = sample.value
          // HKCategoryValueSleepAnalysis values:
          // 0 = inBed (iOS 13+)
          // 1 = asleep (deprecated but still used)
          // 2 = awake (iOS 16+)
          // 3 = core (iOS 16+)
          // 4 = deep (iOS 16+)
          // 5 = rem (iOS 16+)

          // Only include inBed (0) - this represents the total sleep session
          return value == 0
        }

        let data = sleepSamples.map { sample -> [String: Any] in
          let source = sample.sourceRevision.source
          var sourceName: String
          if !source.name.isEmpty {
            sourceName = source.name
          } else if !source.bundleIdentifier.isEmpty {
            sourceName = source.bundleIdentifier
          } else {
            sourceName = "Unknown"
          }
          return [
            "startTime": sample.startDate.timeIntervalSince1970 * 1000,
            "endTime": sample.endDate.timeIntervalSince1970 * 1000,
            "value": sample.value,
            "dataSource": sourceName,
          ]
        }

        result(data)
      }
    }

    healthStore.execute(query)
  }

  private func readMenstruation(predicate: NSPredicate, result: @escaping FlutterResult) {
    let query = HKSampleQuery(
      sampleType: HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { _, samples, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        guard let samples = samples as? [HKCategorySample] else {
          result([])
          return
        }

        let data = samples.map { sample -> [String: Any] in
          let source = sample.sourceRevision.source
          var sourceName: String
          if !source.name.isEmpty {
            sourceName = source.name
          } else if !source.bundleIdentifier.isEmpty {
            sourceName = source.bundleIdentifier
          } else {
            sourceName = "Unknown"
          }
          return [
            "startTime": sample.startDate.timeIntervalSince1970 * 1000,
            "endTime": sample.endDate.timeIntervalSince1970 * 1000,
            "value": sample.value,
            "dataSource": sourceName,
          ]
        }

        result(data)
      }
    }

    healthStore.execute(query)
  }

  private func readMindfulness(predicate: NSPredicate, result: @escaping FlutterResult) {
    let query = HKSampleQuery(
      sampleType: HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
    ) { _, samples, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        guard let samples = samples as? [HKCategorySample] else {
          result([])
          return
        }

        let data = samples.map { sample -> [String: Any] in
          let source = sample.sourceRevision.source
          var sourceName: String
          if !source.name.isEmpty {
            sourceName = source.name
          } else if !source.bundleIdentifier.isEmpty {
            sourceName = source.bundleIdentifier
          } else {
            sourceName = "Unknown"
          }
          return [
            "startTime": sample.startDate.timeIntervalSince1970 * 1000,
            "endTime": sample.endDate.timeIntervalSince1970 * 1000,
            "value": sample.value,
            "dataSource": sourceName,
          ]
        }

        result(data)
      }
    }

    healthStore.execute(query)
  }

  // MARK: - Fetch Daily Activity Statistics (Steps and Distance)

  func fetchDailyActivity(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let startTime = arguments["startTime"] as? Double,
          let endTime = arguments["endTime"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }

    let startDate = Date(timeIntervalSince1970: startTime / 1000.0)
    let endDate = Date(timeIntervalSince1970: endTime / 1000.0)

    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

    // Create anchor date (start of day for the start date)
    var calendar = Calendar.current
    calendar.timeZone = TimeZone.current
    let anchorDate = calendar.startOfDay(for: startDate)

    // Create interval components (1 day)
    let interval = DateComponents(day: 1)

    // Create predicate
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )

    var dailySteps: [String: Int] = [:]
    var dailyDistance: [String: Double] = [:]

    let group = DispatchGroup()

    // Query steps
    group.enter()
    let stepsQuery = HKStatisticsCollectionQuery(
      quantityType: stepType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: anchorDate,
      intervalComponents: interval
    )

    stepsQuery.initialResultsHandler = { query, collection, error in
      defer { group.leave() }

      if let error = error {
        print("[HealthKitBridge] Error fetching steps: \(error.localizedDescription)")
        return
      }

      guard let collection = collection else {
        print("[HealthKitBridge] No steps collection returned")
        return
      }

      collection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
        if let sum = statistics.sumQuantity() {
          let steps = Int(sum.doubleValue(for: HKUnit.count()))
          let dateKey = self.formatDateKey(statistics.startDate)
          dailySteps[dateKey] = steps
        }
      }
    }

    // Query distance
    group.enter()
    let distanceQuery = HKStatisticsCollectionQuery(
      quantityType: distanceType,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: anchorDate,
      intervalComponents: interval
    )

    distanceQuery.initialResultsHandler = { query, collection, error in
      defer { group.leave() }

      if let error = error {
        print("[HealthKitBridge] Error fetching distance: \(error.localizedDescription)")
        return
      }

      guard let collection = collection else {
        print("[HealthKitBridge] No distance collection returned")
        return
      }

      collection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
        if let sum = statistics.sumQuantity() {
          let distanceKm = sum.doubleValue(for: HKUnit.meterUnit(with: .kilo))
          let dateKey = self.formatDateKey(statistics.startDate)
          dailyDistance[dateKey] = distanceKm
        }
      }
    }

    healthStore.execute(stepsQuery)
    healthStore.execute(distanceQuery)

    group.notify(queue: .main) {
      // Combine results
      var allDates = Set(dailySteps.keys)
      allDates.formUnion(dailyDistance.keys)

      let data: [[String: Any]] = allDates.map { dateKey in
        return [
          "date": dateKey,
          "steps": dailySteps[dateKey] ?? 0,
          "distanceKm": dailyDistance[dateKey] ?? 0.0,
        ]
      }

      result(data)
    }
  }

  private func formatDateKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
  }

  // MARK: - Delete Health Data

  func deleteBloodGlucose(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let timestamp = arguments["timestamp"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing timestamp", details: nil))
      return
    }

    let date = Date(timeIntervalSince1970: timestamp / 1000.0)
    let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!

    // Create predicate to find samples at the exact timestamp
    // Allow 1 second tolerance for matching
    let startDate = date.addingTimeInterval(-1)
    let endDate = date.addingTimeInterval(1)
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )

    let query = HKSampleQuery(
      sampleType: glucoseType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "QUERY_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
        return
      }

      guard let samples = samples, !samples.isEmpty else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "NOT_FOUND",
            message: "No blood glucose sample found at timestamp",
            details: nil
          ))
        }
        return
      }

      // Filter to find the sample that matches our app as source
      let ourBundleId = Bundle.main.bundleIdentifier ?? ""
      let samplesToDelete = samples.filter { sample in
        let source = sample.sourceRevision.source
        return source.bundleIdentifier == ourBundleId
      }

      if samplesToDelete.isEmpty {
        // If no samples from our app, delete the closest sample
        if let closestSample = samples.min(by: { sample1, sample2 in
          abs(sample1.startDate.timeIntervalSince(date)) < abs(sample2.startDate.timeIntervalSince(date))
        }) {
          self.deleteSamples([closestSample], result: result)
        } else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "NOT_FOUND",
              message: "No matching sample found",
              details: nil
            ))
          }
        }
      } else {
        // Delete all samples from our app at this timestamp
        self.deleteSamples(samplesToDelete, result: result)
      }
    }

    healthStore.execute(query)
  }

  func deleteInsulinDelivery(arguments: [String: Any], result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    guard let timestamp = arguments["timestamp"] as? Double else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing timestamp", details: nil))
      return
    }

    let date = Date(timeIntervalSince1970: timestamp / 1000.0)
    let insulinType = HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!

    // Create predicate to find samples at the exact timestamp
    // Allow 1 second tolerance for matching
    let startDate = date.addingTimeInterval(-1)
    let endDate = date.addingTimeInterval(1)
    let predicate = HKQuery.predicateForSamples(
      withStart: startDate,
      end: endDate,
      options: .strictStartDate
    )

    let query = HKSampleQuery(
      sampleType: insulinType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "QUERY_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
        return
      }

      guard let samples = samples, !samples.isEmpty else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "NOT_FOUND",
            message: "No insulin delivery sample found at timestamp",
            details: nil
          ))
        }
        return
      }

      // Filter to find the sample that matches our app as source
      let ourBundleId = Bundle.main.bundleIdentifier ?? ""
      let samplesToDelete = samples.filter { sample in
        let source = sample.sourceRevision.source
        return source.bundleIdentifier == ourBundleId
      }

      if samplesToDelete.isEmpty {
        // If no samples from our app, delete the closest sample
        if let closestSample = samples.min(by: { sample1, sample2 in
          abs(sample1.startDate.timeIntervalSince(date)) < abs(sample2.startDate.timeIntervalSince(date))
        }) {
          self.deleteSamples([closestSample], result: result)
        } else {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "NOT_FOUND",
              message: "No matching sample found",
              details: nil
            ))
          }
        }
      } else {
        // Delete all samples from our app at this timestamp
        self.deleteSamples(samplesToDelete, result: result)
      }
    }

    healthStore.execute(query)
  }

  private func deleteSamples(_ samples: [HKSample], result: @escaping FlutterResult) {
    healthStore.delete(samples) { success, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "DELETE_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        } else if success {
          result(true)
        } else {
          result(FlutterError(
            code: "DELETE_FAILED",
            message: "Failed to delete samples",
            details: nil
          ))
        }
      }
    }
  }

  // MARK: - Background Observer

  /// 백그라운드 데이터 업데이트 콜백 설정
  func setBackgroundUpdateCallback(_ callback: @escaping () -> Void) {
    self.onBackgroundUpdateCallback = callback
  }

  /// 백그라운드 옵저버 시작 - 혈당과 체중 데이터를 모니터링
  func startBackgroundObserver(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "UNAVAILABLE", message: "HealthKit not available", details: nil))
      return
    }

    // 혈당 옵저버 설정
    setupGlucoseObserver()

    // 체중 옵저버 설정
    setupWeightObserver()

    print("[HealthKitBridge] Background observers started")
    result(true)
  }

  /// 백그라운드 옵저버 중지
  func stopBackgroundObserver(result: @escaping FlutterResult) {
    if let observer = glucoseObserver {
      healthStore.stop(observer)
      glucoseObserver = nil
      print("[HealthKitBridge] Glucose observer stopped")
    }

    if let observer = weightObserver {
      healthStore.stop(observer)
      weightObserver = nil
      print("[HealthKitBridge] Weight observer stopped")
    }

    result(true)
  }

  private func setupGlucoseObserver() {
    guard let glucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
      print("[HealthKitBridge] Failed to get blood glucose type")
      return
    }

    // 기존 옵저버가 있다면 중지
    if let existingObserver = glucoseObserver {
      healthStore.stop(existingObserver)
    }

    // 새 옵저버 쿼리 생성
    let query = HKObserverQuery(sampleType: glucoseType, predicate: nil) { [weak self] query, completionHandler, error in
      guard let self = self else {
        completionHandler()
        return
      }

      if let error = error {
        print("[HealthKitBridge] Glucose observer error: \(error.localizedDescription)")
        completionHandler()
        return
      }

      print("[HealthKitBridge] Glucose data updated - triggering callback")

      // Flutter 콜백 호출
      DispatchQueue.main.async {
        self.onBackgroundUpdateCallback?()
      }

      // iOS에 백그라운드 작업 완료 알림
      completionHandler()
    }

    glucoseObserver = query
    healthStore.execute(query)

    // 백그라운드 delivery 활성화
    healthStore.enableBackgroundDelivery(for: glucoseType, frequency: .immediate) { success, error in
      if let error = error {
        print("[HealthKitBridge] Failed to enable glucose background delivery: \(error.localizedDescription)")
      } else if success {
        print("[HealthKitBridge] Glucose background delivery enabled")
      }
    }
  }

  private func setupWeightObserver() {
    guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
      print("[HealthKitBridge] Failed to get body mass type")
      return
    }

    // 기존 옵저버가 있다면 중지
    if let existingObserver = weightObserver {
      healthStore.stop(existingObserver)
    }

    // 새 옵저버 쿼리 생성
    let query = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] query, completionHandler, error in
      guard let self = self else {
        completionHandler()
        return
      }

      if let error = error {
        print("[HealthKitBridge] Weight observer error: \(error.localizedDescription)")
        completionHandler()
        return
      }

      print("[HealthKitBridge] Weight data updated - triggering callback")

      // Flutter 콜백 호출
      DispatchQueue.main.async {
        self.onBackgroundUpdateCallback?()
      }

      // iOS에 백그라운드 작업 완료 알림
      completionHandler()
    }

    weightObserver = query
    healthStore.execute(query)

    // 백그라운드 delivery 활성화
    healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { success, error in
      if let error = error {
        print("[HealthKitBridge] Failed to enable weight background delivery: \(error.localizedDescription)")
      } else if success {
        print("[HealthKitBridge] Weight background delivery enabled")
      }
    }
  }
}
