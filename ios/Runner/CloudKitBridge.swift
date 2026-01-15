import Foundation
import CloudKit
import Flutter

class CloudKitBridge {
  private let container = CKContainer(identifier: "iCloud.com.jogunism.glubutler")
  private let privateDatabase: CKDatabase

  // CloudKit record type names
  private static let DiaryEntryRecordType = "DiaryEntry"
  private static let DiaryFileRecordType = "DiaryFile"

  init() {
    privateDatabase = container.privateCloudDatabase
  }

  // MARK: - Check Availability

  func isAvailable(result: @escaping FlutterResult) {
    // CloudKit is always available on iOS
    result(true)
  }

  func isUserSignedIn(result: @escaping FlutterResult) {
    container.accountStatus { accountStatus, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "ERROR",
            message: "Failed to check iCloud account status",
            details: error.localizedDescription
          ))
          return
        }

        result(accountStatus == .available)
      }
    }
  }

  // MARK: - Get User Record ID

  func getUserRecordID(result: @escaping FlutterResult) {
    container.fetchUserRecordID { recordID, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "CLOUDKIT_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
          return
        }

        if let recordID = recordID {
          result(recordID.recordName)
        } else {
          result(FlutterError(
            code: "NO_USER",
            message: "CloudKit user not available",
            details: nil
          ))
        }
      }
    }
  }

  // MARK: - Get iCloud Documents Path

  func getICloudDocumentsPath(result: @escaping FlutterResult) {
    if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
      // Create Documents directory if it doesn't exist
      do {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        result(url.path)
      } catch {
        result(FlutterError(
          code: "CREATE_DIR_FAILED",
          message: "Failed to create iCloud Documents directory",
          details: error.localizedDescription
        ))
      }
    } else {
      result(FlutterError(
        code: "NO_ICLOUD",
        message: "iCloud is not available",
        details: nil
      ))
    }
  }

  // MARK: - Save Diary Entry

  func saveDiaryEntry(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let entryData = arguments["entry"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing entry data", details: nil))
      return
    }

    guard let id = entryData["id"] as? String,
          let content = entryData["content"] as? String,
          let timestampStr = entryData["timestamp"] as? String,
          let createdAtStr = entryData["createdAt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required fields", details: nil))
      return
    }

    let recordID = CKRecord.ID(recordName: id)

    // Fetch existing record first, or create new one
    privateDatabase.fetch(withRecordID: recordID) { existingRecord, error in
      let record: CKRecord

      if let existingRecord = existingRecord {
        // Update existing record
        record = existingRecord
      } else {
        // Create new record
        record = CKRecord(recordType: CloudKitBridge.DiaryEntryRecordType, recordID: recordID)
      }

      // Set fields
      record["id"] = id as CKRecordValue
      record["content"] = content as CKRecordValue

      // Store as String (CloudKit schema already set to String)
      record["timestamp"] = timestampStr as CKRecordValue
      record["createdAt"] = createdAtStr as CKRecordValue

      // Store hasMealDetected as Int (0 or 1)
      let hasMealDetected = entryData["hasMealDetected"] as? Bool ?? false
      record["hasMealDetected"] = (hasMealDetected ? 1 : 0) as CKRecordValue

      // Save the record
      self.privateDatabase.save(record) { savedRecord, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "SAVE_FAILED",
              message: "Failed to save diary entry",
              details: error.localizedDescription
            ))
          }
          return
        }

        // Save files if any
        if let files = entryData["files"] as? [[String: Any]], !files.isEmpty {
          self.saveDiaryFiles(files: files, diaryId: id) { success, error in
            DispatchQueue.main.async {
              if let error = error {
                result(FlutterError(
                  code: "SAVE_FILES_FAILED",
                  message: "Diary saved but files failed",
                  details: error.localizedDescription
                ))
              } else {
                result(true)
              }
            }
          }
        } else {
          DispatchQueue.main.async {
            result(true)
          }
        }
      }
    }
  }

  // MARK: - Save Diary Files

  private func saveDiaryFiles(files: [[String: Any]], diaryId: String, completion: @escaping (Bool, Error?) -> Void) {
    let group = DispatchGroup()
    var saveError: Error?

    for fileData in files {
      group.enter()

      guard let fileId = fileData["id"] as? String,
            let filePath = fileData["filePath"] as? String,
            let createdAtStr = fileData["createdAt"] as? String else {
        group.leave()
        continue
      }

      let recordID = CKRecord.ID(recordName: fileId)

      // Fetch existing record first, or create new one
      privateDatabase.fetch(withRecordID: recordID) { existingRecord, error in
        let record: CKRecord

        if let existingRecord = existingRecord {
          // Update existing record
          record = existingRecord
        } else {
          // Create new record
          record = CKRecord(recordType: CloudKitBridge.DiaryFileRecordType, recordID: recordID)
        }

        // Set fields
        record["id"] = fileId as CKRecordValue
        record["diaryId"] = diaryId as CKRecordValue
        record["filePath"] = filePath as CKRecordValue

        // Store as Date (CloudKit schema set to DATE/TIME)
        // Truncate microseconds to milliseconds (ISO8601DateFormatter only supports 3 decimal places)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func truncateToMilliseconds(_ dateString: String) -> String {
          // 2026-01-15T19:19:00.840899 -> 2026-01-15T19:19:00.840Z
          if let dotIndex = dateString.lastIndex(of: "."),
             let nextIndex = dateString.index(dotIndex, offsetBy: 4, limitedBy: dateString.endIndex) {
            return String(dateString[..<nextIndex]) + "Z"
          }
          return dateString + "Z"
        }

        let truncatedCreatedAt = truncateToMilliseconds(createdAtStr)
        if let createdAtDate = dateFormatter.date(from: truncatedCreatedAt) {
          record["createdAt"] = createdAtDate as CKRecordValue
        }

        // Optional fields
        if let latitude = fileData["latitude"] as? Double {
          record["latitude"] = latitude as CKRecordValue
        }
        if let longitude = fileData["longitude"] as? Double {
          record["longitude"] = longitude as CKRecordValue
        }
        if let capturedAtStr = fileData["capturedAt"] as? String {
          let truncatedCapturedAt = truncateToMilliseconds(capturedAtStr)
          if let capturedAtDate = dateFormatter.date(from: truncatedCapturedAt) {
            record["capturedAt"] = capturedAtDate as CKRecordValue
          }
        }
        if let fileSize = fileData["fileSize"] as? Int {
          record["fileSize"] = fileSize as CKRecordValue
        }

        // Save image as CKAsset if file exists
        let fileURL = URL(fileURLWithPath: filePath)
        if FileManager.default.fileExists(atPath: filePath) {
          let asset = CKAsset(fileURL: fileURL)
          record["imageAsset"] = asset
        }

        self.privateDatabase.save(record) { savedRecord, error in
          if let error = error {
            saveError = error
          }
          group.leave()
        }
      }
    }

    group.notify(queue: .main) {
      completion(saveError == nil, saveError)
    }
  }

  // MARK: - Fetch Diary Entries

  func fetchDiaryEntries(arguments: [String: Any], result: @escaping FlutterResult) {
    // Query for records where id field exists (all records should have an id)
    let predicate = NSPredicate(format: "id != %@", "")
    let query = CKQuery(recordType: CloudKitBridge.DiaryEntryRecordType, predicate: predicate)

    privateDatabase.perform(query, inZoneWith: nil) { records, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "FETCH_FAILED",
            message: "Failed to fetch diary entries",
            details: error.localizedDescription
          ))
        }
        return
      }

      guard let records = records else {
        DispatchQueue.main.async {
          result([])
        }
        return
      }

      // Convert records to JSON
      let dateFormatter = ISO8601DateFormatter()
      let entries = records.compactMap { record -> [String: Any]? in
        guard let id = record["id"] as? String,
              let content = record["content"] as? String,
              let timestampDate = record["timestamp"] as? Date,
              let createdAtDate = record["createdAt"] as? Date else {
          return nil
        }

        return [
          "id": id,
          "content": content,
          "timestamp": dateFormatter.string(from: timestampDate),
          "createdAt": dateFormatter.string(from: createdAtDate),
          "files": [] // Files will be fetched separately if needed
        ]
      }

      DispatchQueue.main.async {
        result(entries)
      }
    }
  }

  // MARK: - Fetch Diary Files for Entry

  func fetchDiaryFiles(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let diaryId = arguments["diaryId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing diaryId", details: nil))
      return
    }

    let predicate = NSPredicate(format: "diaryId == %@", diaryId)
    let query = CKQuery(recordType: CloudKitBridge.DiaryFileRecordType, predicate: predicate)
    // Note: Don't use sortDescriptors until fields are marked as Sortable in CloudKit Console

    privateDatabase.perform(query, inZoneWith: nil) { records, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "FETCH_FAILED",
            message: "Failed to fetch diary files",
            details: error.localizedDescription
          ))
        }
        return
      }

      guard let records = records else {
        DispatchQueue.main.async {
          result([])
        }
        return
      }

      // Convert records to JSON
      let dateFormatter = ISO8601DateFormatter()
      let files = records.compactMap { record -> [String: Any]? in
        guard let id = record["id"] as? String,
              let diaryId = record["diaryId"] as? String,
              let filePath = record["filePath"] as? String,
              let createdAtDate = record["createdAt"] as? Date else {
          return nil
        }

        var fileData: [String: Any] = [
          "id": id,
          "diaryId": diaryId,
          "filePath": filePath,
          "createdAt": dateFormatter.string(from: createdAtDate)
        ]

        // Optional fields
        if let latitude = record["latitude"] as? Double {
          fileData["latitude"] = latitude
        }
        if let longitude = record["longitude"] as? Double {
          fileData["longitude"] = longitude
        }
        // Handle both Date (new) and String (old) for capturedAt
        if let capturedAtDate = record["capturedAt"] as? Date {
          fileData["capturedAt"] = dateFormatter.string(from: capturedAtDate)
        } else if let capturedAtString = record["capturedAt"] as? String {
          fileData["capturedAt"] = capturedAtString
        }
        if let fileSize = record["fileSize"] as? Int {
          fileData["fileSize"] = fileSize
        }

        // Download image asset if available
        if let asset = record["imageAsset"] as? CKAsset,
           let assetURL = asset.fileURL {
          fileData["cloudAssetURL"] = assetURL.path
        }

        return fileData
      }

      DispatchQueue.main.async {
        result(files)
      }
    }
  }

  // MARK: - Delete Diary Entry

  func deleteDiaryEntry(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let entryId = arguments["entryId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing entryId", details: nil))
      return
    }

    let recordID = CKRecord.ID(recordName: entryId)

    // First delete associated files
    deleteDiaryFiles(diaryId: entryId) { filesDeleted, error in
      // Then delete the diary entry
      self.privateDatabase.delete(withRecordID: recordID) { _, error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(
              code: "DELETE_FAILED",
              message: "Failed to delete diary entry",
              details: error.localizedDescription
            ))
          } else {
            result(true)
          }
        }
      }
    }
  }

  // MARK: - Delete Diary Files

  private func deleteDiaryFiles(diaryId: String, completion: @escaping (Bool, Error?) -> Void) {
    let predicate = NSPredicate(format: "diaryId == %@", diaryId)
    let query = CKQuery(recordType: CloudKitBridge.DiaryFileRecordType, predicate: predicate)

    privateDatabase.perform(query, inZoneWith: nil) { records, error in
      if let error = error {
        completion(false, error)
        return
      }

      guard let records = records, !records.isEmpty else {
        completion(true, nil)
        return
      }

      // Delete all file records
      let recordIDs = records.map { $0.recordID }
      let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

      deleteOperation.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
        if let error = error {
          completion(false, error)
        } else {
          completion(true, nil)
        }
      }

      self.privateDatabase.add(deleteOperation)
    }
  }

  // MARK: - Sync on Startup

  func syncOnStartup(result: @escaping FlutterResult) {
    // Check if user is signed in first
    container.accountStatus { accountStatus, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "ERROR",
            message: "Failed to check account status",
            details: error.localizedDescription
          ))
        }
        return
      }

      guard accountStatus == .available else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "NOT_SIGNED_IN",
            message: "User not signed in to iCloud",
            details: nil
          ))
        }
        return
      }

      // Fetch all diary entries from CloudKit
      // Use a predicate that queries on a queryable field instead of NSPredicate(value: true)
      // Query for records where id field exists (all records should have an id)
      let predicate = NSPredicate(format: "id != %@", "")
      let query = CKQuery(recordType: CloudKitBridge.DiaryEntryRecordType, predicate: predicate)

      self.privateDatabase.perform(query, inZoneWith: nil) { records, error in
        if let error = error {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "SYNC_FAILED",
              message: "Failed to sync from CloudKit",
              details: error.localizedDescription
            ))
          }
          return
        }

        guard let records = records, !records.isEmpty else {
          DispatchQueue.main.async {
            result([])
          }
          return
        }

        // Fetch files for each diary entry
        let group = DispatchGroup()
        var entriesWithFiles: [[String: Any]] = []
        let dateFormatter = ISO8601DateFormatter()

        for record in records {
          guard let id = record["id"] as? String,
                let content = record["content"] as? String else {
            continue
          }

          // Handle both Date (new) and String (old) for timestamp
          let timestamp: String
          if let timestampDate = record["timestamp"] as? Date {
            timestamp = dateFormatter.string(from: timestampDate)
          } else if let timestampString = record["timestamp"] as? String {
            timestamp = timestampString
          } else {
            continue
          }

          // Handle both Date (new) and String (old) for createdAt
          let createdAt: String
          if let createdAtDate = record["createdAt"] as? Date {
            createdAt = dateFormatter.string(from: createdAtDate)
          } else if let createdAtString = record["createdAt"] as? String {
            createdAt = createdAtString
          } else {
            continue
          }

          // Parse hasMealDetected (Int64 in CloudKit, convert to Bool for Dart)
          let hasMealDetected = (record["hasMealDetected"] as? Int64 ?? 0) != 0

          let entryDict: [String: Any] = [
            "id": id,
            "content": content,
            "timestamp": timestamp,
            "createdAt": createdAt,
            "hasMealDetected": hasMealDetected
          ]

          group.enter()

          // Fetch files for this diary entry
          self.fetchFilesForDiary(diaryId: id) { files in
            var mutableEntry = entryDict
            mutableEntry["files"] = files as [[String: Any]]
            entriesWithFiles.append(mutableEntry)
            group.leave()
          }
        }

        group.notify(queue: .main) {
          result(entriesWithFiles)
        }
      }
    }
  }

  // MARK: - Helper: Fetch Files for Diary

  private func fetchFilesForDiary(diaryId: String, completion: @escaping ([[String: Any]]) -> Void) {
    let predicate = NSPredicate(format: "diaryId == %@", diaryId)
    let query = CKQuery(recordType: CloudKitBridge.DiaryFileRecordType, predicate: predicate)

    privateDatabase.perform(query, inZoneWith: nil) { records, error in
      if let error = error {
        completion([])
        return
      }

      guard let records = records else {
        completion([])
        return
      }

      // Download images from CKAsset
      let group = DispatchGroup()
      var downloadedFiles: [[String: Any]] = []

      let dateFormatter = ISO8601DateFormatter()

      for record in records {
        guard let fileId = record["id"] as? String,
              let diaryId = record["diaryId"] as? String,
              let filePath = record["filePath"] as? String else {
          continue
        }

        // Generate new local path for this device (ignore the old path from CloudKit)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        let fileName = (filePath as NSString).lastPathComponent
        let newFilePath = "\(documentsPath)/diary/\(fileName)"

        // Handle both Date (new) and String (old) for createdAt
        let createdAt: String
        if let createdAtDate = record["createdAt"] as? Date {
          createdAt = dateFormatter.string(from: createdAtDate)
        } else if let createdAtString = record["createdAt"] as? String {
          createdAt = createdAtString
        } else {
          continue
        }

        var fileData: [String: Any] = [
          "id": fileId,
          "diaryId": diaryId,
          "filePath": newFilePath,  // Use new local path
          "createdAt": createdAt
        ]

        // Optional fields
        if let latitude = record["latitude"] as? Double {
          fileData["latitude"] = latitude
        }
        if let longitude = record["longitude"] as? Double {
          fileData["longitude"] = longitude
        }
        // Handle both Date (new) and String (old) for capturedAt
        if let capturedAtDate = record["capturedAt"] as? Date {
          fileData["capturedAt"] = dateFormatter.string(from: capturedAtDate)
        } else if let capturedAtString = record["capturedAt"] as? String {
          fileData["capturedAt"] = capturedAtString
        }
        if let fileSize = record["fileSize"] as? Int {
          fileData["fileSize"] = fileSize
        }

        // Download image from CKAsset if available
        if let asset = record["imageAsset"] as? CKAsset,
           let assetURL = asset.fileURL {
          group.enter()

          // Copy from CKAsset to new local path
          let destinationURL = URL(fileURLWithPath: newFilePath)
          do {
            // Create directory if needed
            let directory = destinationURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

            // Copy file (overwrite if exists)
            if FileManager.default.fileExists(atPath: newFilePath) {
              try FileManager.default.removeItem(atPath: newFilePath)
            }
            try FileManager.default.copyItem(at: assetURL, to: destinationURL)

            downloadedFiles.append(fileData)
          } catch {
            // Still add file data even if download fails
            downloadedFiles.append(fileData)
          }

          group.leave()
        } else {
          // No asset, just add the metadata
          downloadedFiles.append(fileData)
        }
      }

      group.notify(queue: .main) {
        completion(downloadedFiles)
      }
    }
  }

  // MARK: - Delete All CloudKit Data (Development Only)

  func deleteAllCloudKitData(result: @escaping FlutterResult) {
    let group = DispatchGroup()
    var errors: [Error] = []

    // Delete all DiaryEntry records
    group.enter()
    let diaryPredicate = NSPredicate(format: "id != %@", "")
    let diaryQuery = CKQuery(recordType: CloudKitBridge.DiaryEntryRecordType, predicate: diaryPredicate)

    privateDatabase.perform(diaryQuery, inZoneWith: nil) { records, error in
      if let error = error {
        errors.append(error)
        group.leave()
        return
      }

      guard let records = records, !records.isEmpty else {
        group.leave()
        return
      }

      let recordIDs = records.map { $0.recordID }
      let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

      deleteOperation.modifyRecordsResultBlock = { result in
        switch result {
        case .success:
          break
        case .failure(let error):
          errors.append(error)
        }
        group.leave()
      }

      self.privateDatabase.add(deleteOperation)
    }

    // Delete all DiaryFile records
    group.enter()
    let filePredicate = NSPredicate(format: "id != %@", "")
    let fileQuery = CKQuery(recordType: CloudKitBridge.DiaryFileRecordType, predicate: filePredicate)

    privateDatabase.perform(fileQuery, inZoneWith: nil) { records, error in
      if let error = error {
        errors.append(error)
        group.leave()
        return
      }

      guard let records = records, !records.isEmpty else {
        group.leave()
        return
      }

      let recordIDs = records.map { $0.recordID }
      let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)

      deleteOperation.modifyRecordsResultBlock = { result in
        switch result {
        case .success:
          break
        case .failure(let error):
          errors.append(error)
        }
        group.leave()
      }

      self.privateDatabase.add(deleteOperation)
    }

    group.notify(queue: .main) {
      if errors.isEmpty {
        result(true)
      } else {
        result(FlutterError(
          code: "DELETE_FAILED",
          message: "Failed to delete some records",
          details: errors.map { $0.localizedDescription }.joined(separator: ", ")
        ))
      }
    }
  }
}
