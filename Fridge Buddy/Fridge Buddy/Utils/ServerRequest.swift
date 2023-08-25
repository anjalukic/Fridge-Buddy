//
//  ServerRequests.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 20.8.23..
//

import Foundation

struct ServerRequest {
  static func post(json: [String: Any], url: URL) async -> Result<Bool, FridgeSharingClient.FridgeSharingError> {
    do {
      // Serialize the JSON data
      let jsonData = try JSONSerialization.data(withJSONObject: json)
      
      // Create the HTTP request
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = jsonData
      
      _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
          if let error = error {
            print("Error: \(error)")
            continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.postingError)
            return
          } else if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
              continuation.resume(returning: true)
              return
            } else {
              print("Request failed with status code: \(response.statusCode)")
              continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.postingError)
              return
            }
          }
        }
        task.resume()
      }
    } catch {
      return .failure(.postingError)
    }
    return .success(true)
  }
  
  static func get(url: URL) async -> Result<[String: Any], FridgeSharingClient.FridgeSharingError> {
    let request = URLRequest(url: url)
    
    let responseDict = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String: Any], Error>) in
      let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
          print("Error: \(error)")
          continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.readingError)
          return
        }
        if let data = data, let response = response as? HTTPURLResponse {
          if response.statusCode == 200 {
            guard
              let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
              continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.readingError)
              return
            }
            continuation.resume(returning: responseDict)
            return
          } else {
            print("Request failed with status code: \(response.statusCode)")
            continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.readingError)
            return
          }
        }
      }
      task.resume()
    }
    guard let responseDict else { return .failure(.readingError) }
    return .success(responseDict)
  }
  
  static func flushToilet(url: URL) async -> Result<Bool, FridgeSharingClient.FridgeSharingError> {
    let request = URLRequest(url: url)
    do {
      let _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
          if let error = error {
            print("Error: \(error)")
            continuation.resume(throwing: error)
            return
          }
          if let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
              continuation.resume(returning: true)
              return
            } else {
              print("Request failed with status code: \(response.statusCode)")
              continuation.resume(throwing: FridgeSharingClient.FridgeSharingError.flushingError)
              return
            }
          }
        }
        task.resume()
      }
    } catch {
      return .failure(.flushingError)
    }
    return .success(true)
  }
}
