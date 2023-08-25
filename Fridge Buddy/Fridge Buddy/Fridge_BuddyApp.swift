//
//  Fridge_BuddyApp.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI

@main
struct Fridge_BuddyApp: App {
    var body: some Scene {
        WindowGroup {
          AppView(store: .init(
            initialState: .init(),
            reducer: AppFeature()
          ))
//          QRCodeScannerView()
        }
    }
}
