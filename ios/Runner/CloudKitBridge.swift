import Foundation
import CloudKit
import Flutter

class CloudKitBridge {
  private let container = CKContainer.default()
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

    // Create or fetch existing record
    let recordID = CKRecord.ID(recordName: id)
    let record = CKRecord(recordType: CloudKitBridge.DiaryEntryRecordType, recordID: recordID)

    // Set fields
    record["id"] = id as CKRecordValue
    record["content"] = content as CKRecordValue
    record["timestamp"] = timestampStr as CKRecordValue
    record["createdAt"] = createdAtStr as CKRecordValue

    // Save the record
    privateDatabase.save(record) { savedRecord, error in
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
      let record = CKRecord(recordType: CloudKitBridge.DiaryFileRecordType, recordID: recordID)

      // Set fields
      record["id"] = fileId as CKRecordValue
      record["diaryId"] = diaryId as CKRecordValue
      record["filePath"] = filePath as CKRecordValue
      record["createdAt"] = createdAtStr as CKRecordValue

      // Optional fields
      if let latitude = fileData["latitude"] as? Double {
        record["latitude"] = latitude as CKRecordValue
      }
      if let longitude = fileData["longitude"] as? Double {
        record["longitude"] = longitude as CKRecordValue
      }
      if let capturedAtStr = fileData["capturedAt"] as? String {
        record["capturedAt"] = capturedAtStr as CKRecordValue
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

      privateDatabase.save(record) { _, error in
        if let error = error {
          saveError = error
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(saveError == nil, saveError)
    }
  }

  // MARK: - Fetch Diary Entries

  func fetchDiaryEntries(arguments: [String: Any], result: @escaping FlutterResult) {
    let query = CKQuery(recordType: CloudKitBridge.DiaryEntryRecordType, predicate: NSPredicate(value: true))
    query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

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
      let entries = records.compactMap { record -> [String: Any]? in
        guard let id = record["id"] as? String,
              let content = record["content"] as? String,
              let timestamp = record["timestamp"] as? String,
              let createdAt = record["createdAt"] as? String else {
          return nil
        }

        return [
          "id": id,
          "content": content,
          "timestamp": timestamp,
          "createdAt": createdAt,
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
    query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

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
      let files = records.compactMap { record -> [String: Any]? in
        guard let id = record["id"] as? String,
              let diaryId = record["diaryId"] as? String,
              let filePath = record["filePath"] as? String,
              let createdAt = record["createdAt"] as? String else {
          return nil
        }

        var fileData: [String: Any] = [
          "id": id,
          "diaryId": diaryId,
          "filePath": filePath,
          "createdAt": createdAt
        ]

        // Optional fields
        if let latitude = record["latitude"] as? Double {
          fileData["latitude"] = latitude
        }
        if let longitude = record["longitude"] as? Double {
          fileData["longitude"] = longitude
        }
        if let capturedAt = record["capturedAt"] as? String {
          fileData["capturedAt"] = capturedAt
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
    guard let id = arguments["id"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
      return
    }

    let recordID = CKRecord.ID(recordName: id)

    // First delete associated files
    deleteDiaryFiles(diaryId: id) { filesDeleted, error in
      if let error = error {
        print("[CloudKitBridge] Warning: Failed to delete files: \(error.localizedDescription)")
      }

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
      let query = CKQuery(recordType: CloudKitBridge.DiaryEntryRecordType, predicate: NSPredicate(value: true))
      query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

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

        guard let records = records else {
          DispatchQueue.main.async {
            result([])
          }
          return
        }

        // Convert records to JSON
        let entries = records.compactMap { record -> [String: Any]? in
          guard let id = record["id"] as? String,
                let content = record["content"] as? String,
                let timestamp = record["timestamp"] as? String,
                let createdAt = record["createdAt"] as? String else {
            return nil
          }

          return [
            "id": id,
            "content": content,
            "timestamp": timestamp,
            "createdAt": createdAt,
            "files": []
          ]
        }

        DispatchQueue.main.async {
          print("[CloudKitBridge] Synced \(entries.count) diary entries from CloudKit")
          result(entries)
        }
      }
    }
  }
}
