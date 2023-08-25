//
//  UserInfoClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 20.8.23..
//

import Foundation

public struct UserInfoClient {
  public var getUserInfo: () -> User
  public var loginUser: (_ username: String, _ password: String) async -> Result<Bool, UserInfoError>
  public var registerUser: (_ username: String, _ email: String, _ password: String) async -> Result<Bool, UserInfoError>
  public var logoutUser: () -> Void
}

public enum User: Equatable {
  case loggedIn(username: String, email: String)
  case guest
}
