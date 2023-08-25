//
//  RecipeView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 13.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct InteractiveCookingView: View {
  private let store: StoreOf<InteractiveCookingFeature>
  private let horizontalPadding: CGFloat = 16
  
  public init(store: StoreOf<InteractiveCookingFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        TitleWithBackButtonView(title: "Cooking \(viewStore.recipe.name)", didTapBack: { viewStore.send(.didTapBack) })
        self.cookingSteps
          .padding(.horizontal, self.horizontalPadding)
      }
    }
  }
  
  private var cookingSteps: some View {
    ScrollView {
      WithViewStore(self.store, observe: { $0.recipeStepsInfo }) { viewStore in
        ForEach(viewStore.state, id: \.index) { recipeStep in
          VStack {
            Text("Step \(recipeStep.index + 1)\(recipeStep.isDone ? "  \u{2713}" : "")")
              .font(.system(size: 20, weight: .semibold))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.bottom, 4)
              .foregroundColor(recipeStep.isDone ? .green : .black)
            
            if  !recipeStep.isDone {
              Text(recipeStep.description)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
              self.buttons(for: recipeStep)
            }
          }
          Spacer().frame(height: 16)
        }
      }
    }
  }
  
  private func buttons(for recipeStep: InteractiveCookingFeature.State.RecipeStepInfo) -> some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack {
        if let timerDuration = recipeStep.timerDuration {
          Button {
            viewStore.send(.didTapTimer(recipeStep.index))
          } label: {
            HStack {
              recipeStep.isTimerOn ? Image(systemName: "pause.fill") : Image(systemName: "timer")
              Text(recipeStep.timerDescription)
            }
            .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        
        Button {
          viewStore.send(.didTapDoneWithStep(recipeStep.index))
        } label: {
          Text("\u{2713}")
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
