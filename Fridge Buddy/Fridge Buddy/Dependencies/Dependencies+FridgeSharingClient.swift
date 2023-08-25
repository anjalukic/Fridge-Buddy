//
//  Dependencies+FridgeSharingClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 19.8.23..
//

import Foundation
import ComposableArchitecture


enum FridgeSharingClientKey: DependencyKey {
  static let defaultValue: FridgeSharingClient = .init(
    createConnection: { email in .success(UUID()) },
    getConnection: { .success(UUID()) },
    removeConnection: { .success(true) },
    getConnectedEmails: { .success([]) },
    uploadFridge: { .success(true) },
    checkIfUpdateNeeded: { .success(nil) },
    downloadFridge: { url in .success(true) }
  )
  
  static var liveValue: FridgeSharingClient = .init(
    createConnection: { sharingEmail in
      // get this user's email
      guard let userEmail = Self.getUserEmail() else { return .failure(.notLoggedInError) }
      
      // read all connections from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var connections = fridgesInfo["connections"] as? [String: String]
      else { return .failure(.readingError) }
      
      // check if the other user is already sharing with someone else
      guard connections[sharingEmail] == nil else { return .failure(.userAlreadyHasConnection) }
      
      // check if user's email already has a connection, or create a new one
      let connectionId = connections[userEmail] ?? UUID().uuidString
      
      // flush the toilet to delete the old value on the server
      let flushResult = await ServerRequest.flushToilet(url: Self.flushToiletURL)
      guard case .success = flushResult else {
        return .failure(FridgeSharingClient.FridgeSharingError.flushingError)
      }
      
      // save the new connection to server
      connections[userEmail] = connectionId
      connections[sharingEmail] = connectionId
      fridgesInfo["connections"] = connections
      let postResult = await ServerRequest.post(json: fridgesInfo, url: Self.postSharedFridgesURL)
      guard case .success = postResult else { return .failure(.postingError) }
      
      // save the connection locally
      let defaults = UserDefaults.standard
      defaults.set(connectionId, forKey: "connection")
      
      guard let id = UUID(uuidString: connectionId) else { return .failure(.readingError) }
      return .success(id)
    },
    
    getConnection: {
      guard let userEmail = Self.getUserEmail() else { return .failure(.notLoggedInError) }
      
      // check if there's a locally saved connection
      let defaults = UserDefaults.standard
      if
        let connectionIdString = defaults.string(forKey: "connection"),
        let connectionId = UUID(uuidString: connectionIdString)
      { return .success(connectionId) }
      
      // read the connections from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var connections = fridgesInfo["connections"] as? [String: String]
      else { return .failure(.readingError) }
      
      guard let connectionId = connections[userEmail] else { return .success(nil) }
      guard let id = UUID(uuidString: connectionId) else { return .failure(.readingError) }
      
      // save the connection locally
      defaults.set(connectionId, forKey: "connection")
      defaults.removeObject(forKey: "dbLastUpdated")
      
      return .success(id)
    },
    
    removeConnection: {
      guard let userEmail = Self.getUserEmail() else { return .failure(.notLoggedInError) }
      
      let defaults = UserDefaults.standard
      guard let connectionIdString = defaults.string(forKey: "connection") else { return .failure(.noConnectionError) }
      
      // read the connections from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var connections = fridgesInfo["connections"] as? [String: String]
      else { return .failure(.readingError) }
      
      // flush the toilet to delete the old value on the server
      let flushResult = await ServerRequest.flushToilet(url: Self.flushToiletURL)
      guard case .success = flushResult else {
        return .failure(FridgeSharingClient.FridgeSharingError.flushingError)
      }
      
      // save the new value on server
      connections = connections.filter { (email, id) in id != connectionIdString }
      fridgesInfo["connections"] = connections
      let postResult = await ServerRequest.post(json: fridgesInfo, url: Self.postSharedFridgesURL)
      guard case .success = postResult else { return .failure(.postingError) }
      
      // remove the connection locally
      defaults.removeObject(forKey: "connection")
      defaults.removeObject(forKey: "dbLastUpdated")
      
      return .success(true)
    },
    
    getConnectedEmails: {
      guard let userEmail = Self.getUserEmail() else { return .failure(.notLoggedInError) }
      
      // read the connections from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var connections = fridgesInfo["connections"] as? [String: String]
      else { return .failure(.readingError) }
      
      guard let connectionId = connections[userEmail] else { return .success([]) }
      
      var emails: [String] = connections.filter { (email, id) in id == connectionId && email != userEmail }.keys.map { $0 }
      
      return .success(emails)
    },
    
    uploadFridge: {
      let dbPath = DatabaseClientKey.liveValue.getDatabaseURL()
      
      // check if there's a saved connection
      let defaults = UserDefaults.standard
      guard let connectionIdString = defaults.string(forKey: "connection") else { return .failure(.noConnectionError) }
      
      // upload file to server
      let uploadResult = await Self.uploadDBFile(dbPath: dbPath)
      guard case .success(let uploadedFileURL) = uploadResult else {
        return .failure(FridgeSharingClient.FridgeSharingError.dbUploadError)
      }
      
      // read the sharedFridgesInfo from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var fridges = fridgesInfo["fridges"] as? [String: [String: String]]
      else { return .failure(.readingError) }
      
      // add the link to newly uploaded fridge
      var fridgeInfo: [String: String] = [:]
      fridgeInfo["link"] = uploadedFileURL.absoluteString
      let lastUpdated = Date().toString()
      fridgeInfo["lastUpdated"] = lastUpdated
      defaults.set(lastUpdated, forKey: "dbLastUpdated")
      
      // flush the toilet to delete the old value on the server
      let flushResult = await ServerRequest.flushToilet(url: Self.flushToiletURL)
      guard case .success = flushResult else {
        return .failure(FridgeSharingClient.FridgeSharingError.flushingError)
      }
      
      // update values for fridges info
      fridges[connectionIdString] = fridgeInfo
      fridgesInfo["fridges"] = fridges
      
      // post the new value of fridges info
      let postResult = await ServerRequest.post(json: fridgesInfo, url: Self.postSharedFridgesURL)
      guard case .success = postResult else {
        return .failure(FridgeSharingClient.FridgeSharingError.postingError)
      }
      return .success(true)
    },
    
    checkIfUpdateNeeded: {
      // check if there's a saved connection
      let defaults = UserDefaults.standard
      guard let connectionIdString = defaults.string(forKey: "connection") else { return .failure(.noConnectionError) }
      
      // read the sharedFridgesInfo from the server
      let result = await ServerRequest.get(url: Self.getSharedFridgesURL)
      guard
        case .success(let fridgesDict) = result,
        var fridgesInfo = fridgesDict as? [String: [String: Any]],
        var fridges = fridgesInfo["fridges"] as? [String: [String: String]]
      else { return .failure(.readingError) }
      
      guard let fridgeInfo = fridges[connectionIdString] else { return .success(nil) }
      guard
        let link = fridgeInfo["link"],
        let url = URL(string: link),
        let lastUpdated = fridgeInfo["lastUpdated"]
      else { return .failure(.readingError) }
      
      guard let lastUpdatedLocal = defaults.string(forKey: "dbLastUpdated") else { return .success(url) }
      
      guard
        let lastUpdateTime = lastUpdated.toDate(),
          let lastLocalUpdateTime = lastUpdatedLocal.toDate()
      else { return .failure(.readingError)}
      
      if lastUpdateTime > lastLocalUpdateTime { return .success(url) }
      return .success(nil)
    },
    
    downloadFridge: { url in
      let result = await Self.downloadDBFile(url: url)
      guard case .success(let newDatabaseURL) = result else { return .failure(.dbDownloadError) }
      let loadResult = await DatabaseClientKey.liveValue.loadNewDatabase(newDatabaseURL)
      guard case .success = loadResult else { return .failure(.dbDownloadError) }
      
      // set local last updated time
      let defaults = UserDefaults.standard
      let lastUpdated = Date().toString()
      defaults.set(lastUpdated, forKey: "dbLastUpdated")
      
      return .success(true)
    }
  )
}

extension DependencyValues {
  var fridgeSharingClient: FridgeSharingClient {
    get { self[FridgeSharingClientKey.self] }
    set { self[FridgeSharingClientKey.self] = newValue }
  }
}

extension FridgeSharingClientKey {
  fileprivate static var getSharedFridgesURL = URL(string: "https://ptsv3.com/t/FridgeBuddySharedFridges/d/0")!
  fileprivate static var postSharedFridgesURL = URL(string: "https://ptsv3.com/t/FridgeBuddySharedFridges/edit/")!
  fileprivate static var flushToiletURL = URL(string: "https://ptsv3.com/t/\(String.sharedFridgesToilet)/flush_all/")!
  
  fileprivate static func getUserEmail() -> String? {
    // get this user's email
    let user = UserInfoClientKey.liveValue.getUserInfo()
    guard case .loggedIn(username: _, email: let userEmail) = user else { return nil }
    return userEmail
  }
  
  fileprivate static func uploadDBFile(dbPath: URL) async -> Result<URL, FridgeSharingClient.FridgeSharingError> {
    let apiUrl = URL(string: "https://api.bytescale.com/v2/accounts/FW25bd7/uploads/form_data")!
    let token = "public_FW25bd75noriMetYrb4JYMzpihNq"
    let txtFileName = "fridgeBuddyDB.txt"
    
    // Read the contents of the SQLite file
    guard let sqliteData = try? Data(contentsOf: dbPath) else {
      print("Error reading SQLite file.")
      return .failure(.dbUploadError)
    }
    
    // Write the SQLite data to a text file
    guard let txtFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(txtFileName)
    else {
      print("Error creating text file.")
      return .failure(.dbUploadError)
    }
    
    do {
      try sqliteData.write(to: txtFilePath)
    } catch {
      print("Error writing SQLite data to text file: \(error)")
      return .failure(.dbUploadError)
    }
    
    var request = URLRequest(url: apiUrl)
    request.httpMethod = "POST"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    let boundaryPrefix = "--\(boundary)\r\n"
    let boundarySuffix = "--\(boundary)--\r\n"
    
    var body = Data()
    
    body.append(boundaryPrefix.data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(txtFileName)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: text/plain\r\n\r\n".data(using: .utf8)!)
    
    if let txtData = try? Data(contentsOf: txtFilePath) {
      body.append(txtData)
    } else {
      print("Error reading text file.")
      return .failure(.dbUploadError)
    }
    
    body.append("\r\n".data(using: .utf8)!)
    body.append(boundarySuffix.data(using: .utf8)!)
    
    let uploadedFileURL = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
      let task = URLSession.shared.uploadTask(with: request, from: body) { (data, response, error) in
        if let error = error {
          print("Error: \(error)")
          continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.dbUploadError)
          return
        }
        
        if
          let data = data,
          let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let files = response["files"] as? [[String: Any]],
          let file = files.first,
          let url = file["fileUrl"] as? String
        {
          print("File uploaded to: \(url)")
          continuation.resume(returning: url)
          return
        }
      }
      task.resume()
    }
    guard let uploadedFileURL else { return .failure(.dbUploadError) }
    return .success(URL(string: uploadedFileURL)!)
  }
  
  fileprivate static func downloadDBFile(url: URL) async -> Result<URL, FridgeSharingClient.FridgeSharingError> {
    let sqliteFileName = "fridgeBuddyDB_\(UUID.init()).sqlite"
    
    let downloadedFileURL = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
      URLSession.shared.downloadTask(with: url) { (tempLocalURL, _, error) in
        if let error = error {
          print("Error downloading file: \(error)")
          continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.dbDownloadError)
          return
        }
        
        guard let tempLocalURL = tempLocalURL else {
          print("Error: No temporary URL provided.")
          continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.dbDownloadError)
          return
        }
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let destinationURL = documentsDirectory.appendingPathComponent(sqliteFileName)
        
        do {
          try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
          print("File downloaded to: \(destinationURL.absoluteString)")
          continuation.resume(returning: destinationURL)
          return
        } catch {
          print("Error moving downloaded file: \(error)")
          continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.dbDownloadError)
          return
        }
      }.resume()
    }
    guard let downloadedFileURL else {
      return .failure(.dbDownloadError)
    }
    return .success(downloadedFileURL)
  }
}

extension FridgeSharingClient {
  public enum FridgeSharingError: Error {
    case dbUploadError
    case dbDownloadError
    case postingError
    case readingError
    case flushingError
    case dbLoadError
    case notLoggedInError
    case userAlreadyHasConnection
    case noConnectionError
  }
}

fileprivate extension String {
  static let sharedFridgesToilet = "FridgeBuddySharedFridges"
}
