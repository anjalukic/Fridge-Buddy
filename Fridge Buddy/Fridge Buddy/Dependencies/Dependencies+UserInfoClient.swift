//
//  Dependencies+UserInfoClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 20.8.23..
//

import Foundation
import ComposableArchitecture


enum UserInfoClientKey: DependencyKey {
  static let defaultValue: UserInfoClient = .init(
    getUserInfo: { return .guest },
    loginUser: { _, _ in return .success(true) },
    registerUser: { _, _, _ in return .success(true) },
    logoutUser: {}
  )
  
  static var liveValue: UserInfoClient = .init(
    getUserInfo: {
      let defaults = UserDefaults.standard
      guard
        let userInfo = defaults.dictionary(forKey: "userInfo") as? [String: String],
        let username = userInfo["username"],
        let email = userInfo["email"]
      else {
        return .guest
      }
      return .loggedIn(username: username, email: email)
    },
    loginUser: { username, password in
      let usersResult = await ServerRequest.get(url: Self.getUsersURL)
      guard
        case .success(let usersDict) = usersResult,
        let users = usersDict as? [String: [String: String]]
      else {
        return .failure(.readingError)
      }
      guard
        let userInfo = users[username],
        let fetchedPassword = userInfo["password"],
        let email = userInfo["email"],
        password == fetchedPassword
      else {
        return .failure(.wrongUsernameOrPasswordError)
      }
      
      // save user info locally
      Self.saveUserInfoToDefaults(username: username, email: email)
      return .success(true)
    },
    registerUser: { username, email, password in
      // fetch all users
      let usersResult = await ServerRequest.get(url: Self.getUsersURL)
      guard
        case .success(let usersDict) = usersResult,
        var users = usersDict as? [String: [String: String]]
      else {
        return .failure(.readingError)
      }
      
      // check if username or email is taken
      guard users[username] == nil else { return .failure(.usernameTakenError) }
      let emails = users.compactMap { (_, userInfo) in userInfo["email"] }
      guard !emails.contains(email) else { return .failure(.emailTakenError) }
      
      // prepare new users data
      users[username] = ["email": email, "password": password]
      
      // flush the toilet to delete the old value on the server
      let flushResult = await ServerRequest.flushToilet(url: Self.flushToiletURL)
      guard case .success = flushResult else {
        return .failure(.flushingError)
      }
      
      // post the new users value
      let postResult = await ServerRequest.post(json: users, url: Self.postUsersURL)
      guard case .success = postResult else { return .failure(.postingError) }
      
      // save user info locally
      Self.saveUserInfoToDefaults(username: username, email: email)
      return .success(true)
    },
    logoutUser: {
      Self.saveUserInfoToDefaults(username: nil, email: nil)
      
      let defaults = UserDefaults.standard
      defaults.removeObject(forKey: "dbLastUpdated")
      defaults.removeObject(forKey: "connection")
    }
  )
}

extension DependencyValues {
  var userInfoClient: UserInfoClient {
    get { self[UserInfoClientKey.self] }
    set { self[UserInfoClientKey.self] = newValue }
  }
}

extension UserInfoClientKey {
  fileprivate static var getUsersURL = URL(string: "https://ptsv3.com/t/FridgeBuddyUsers/d/0")!
  fileprivate static var postUsersURL = URL(string: "https://ptsv3.com/t/FridgeBuddyUsers/edit/")!
  fileprivate static var flushToiletURL = URL(string: "https://ptsv3.com/t/\(String.usersToilet)/flush_all/")!
  
  fileprivate static func saveUserInfoToDefaults(username: String?, email: String?) {
    let defaults = UserDefaults.standard
    
    guard let username, let email else {
      let userInfo: [String: String] = [:]
      defaults.set(userInfo, forKey: "userInfo")
      return
    }
    
    let saveUserInfo = ["username": username, "email": email]
    defaults.set(saveUserInfo, forKey: "userInfo")
  }
}

extension UserInfoClient {
  public enum UserInfoError: Error {
    case readingError
    case postingError
    case wrongUsernameOrPasswordError
    case usernameTakenError
    case emailTakenError
    case flushingError
  }
}

fileprivate extension String {
  static let usersToilet = "FridgeBuddyUsers"
}
