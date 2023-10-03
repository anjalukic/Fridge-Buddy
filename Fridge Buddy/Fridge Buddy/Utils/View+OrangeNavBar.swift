//
//  NavigationBar+Orange.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 29.8.23..
//

import Foundation
import SwiftUI

struct OrangeNavBar: ViewModifier {
  
  init() {
    let backgroundColor: UIColor = .init(Color.init("AppetiteRed"))
    let titleColor: UIColor = .init(Color.white)
    let coloredAppearance = UINavigationBarAppearance()
    coloredAppearance.configureWithTransparentBackground()
    coloredAppearance.backgroundColor = backgroundColor
    coloredAppearance.titleTextAttributes = [.foregroundColor: titleColor]
    coloredAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
    let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
    buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
    coloredAppearance.buttonAppearance = buttonAppearance
    coloredAppearance.backButtonAppearance = buttonAppearance
    
    UINavigationBar.appearance().standardAppearance = coloredAppearance
    UINavigationBar.appearance().compactAppearance = coloredAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
  }
  
  func body(content: Content) -> some View {
    content
      .navigationBarTitleDisplayMode(.inline)
  }
}

extension View {
  func setupNavBar() -> some View {
    modifier(OrangeNavBar())
  }
}
