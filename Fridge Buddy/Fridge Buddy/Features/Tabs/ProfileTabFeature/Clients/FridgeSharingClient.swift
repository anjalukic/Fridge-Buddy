//
//  FridgeSharingClient.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 10.8.23..
//

import Foundation

public struct FridgeSharingClient {
  public var createConnection: (_ withEmail: String) async -> Result<UUID, FridgeSharingError>
  public var getConnection: () async -> Result<UUID?, FridgeSharingError>
  public var removeConnection: () async -> Result<Bool, FridgeSharingError>
  public var getConnectedEmails: () async -> Result<[String], FridgeSharingError>
  public var uploadFridge: () async -> Result<Bool, FridgeSharingError>
  public var checkIfUpdateNeeded: () async -> Result<URL?, FridgeSharingError>
  public var downloadFridge: (_ fromURL: URL) async -> Result<Bool, FridgeSharingError>
}
