//
//  RecipeFeature.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 13.8.23..
//

import Foundation
import AVFoundation
import ComposableArchitecture

public struct InteractiveCookingFeature: ReducerProtocol {
  public struct State: Equatable {
    public let recipe: Recipe
    public var recipeStepsInfo: [RecipeStepInfo]
    
    public init(recipe: Recipe, recipeSteps: IdentifiedArrayOf<RecipeStep>) {
      self.recipe = recipe
      let recipeSteps = recipeSteps.sorted(by: { a, b in a.index < b.index })
      self.recipeStepsInfo = recipeSteps.map {
        return .init(
          timerDuration: $0.timerDuration,
          timeLeft: $0.timerDuration,
          description: $0.description,
          index: $0.index
        )
      }
    }
  }
  
  public enum Action: Equatable {
    case didTapBack
    case didTapDoneWithStep(Int)
    case didTapTimer(Int)
    case didTickTimer(Int)
    case dependency(DependencyAction)
    case delegate(DelegateAction)
    
    public enum DependencyAction: Equatable {
    }
    
    public enum DelegateAction: Equatable {
    }
  }
  
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.continuousClock) var clock
  @Dependency(\.mainQueue) var mainQueue
  
  public var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapBack:
        return .run { _ in await self.dismiss(animation: .default) }
        
      case .didTapDoneWithStep(let index):
        state.recipeStepsInfo[index].isDone = true
        return .cancel(id: index)
        
      case .didTapTimer(let index):
        guard state.recipeStepsInfo[index].timerDuration != nil else { fatalError("Tried to start timer for step without one") }
        if state.recipeStepsInfo[index].isTimerOn {
          state.recipeStepsInfo[index].isTimerOn = false
          return .cancel(id: index)
        }
        state.recipeStepsInfo[index].isTimerOn = true
        return .run { send in
          await withTaskCancellation(id: index, cancelInFlight: true) {
            for await _ in clock.timer(interval: .seconds(1)) {
              await send(.didTickTimer(index))
            }
          }
        }
        
      case .didTickTimer(let index):
        guard var timeLeft = state.recipeStepsInfo[index].timeLeft else { return .none }
        timeLeft = timeLeft - 1
        state.recipeStepsInfo[index].timeLeft = timeLeft
        if timeLeft == 0 {
          // TODO: play a sound when a timer ends
          return .cancel(id: index)
        }
        return .none

      case .dependency(let dependencyAction):
        return self.handleDependencyAction(dependencyAction, state: &state)
        
      case .delegate:
        // handled in the higher level reducer
        return .none
      }
    }
  }
}

extension InteractiveCookingFeature {
  private func handleDependencyAction(_ action: Action.DependencyAction, state: inout State) -> EffectTask<Action> {
    switch action {
    }
  }
}

extension InteractiveCookingFeature.State {
  public struct RecipeStepInfo: Equatable {
    var isDone: Bool
    var isTimerOn: Bool
    var timerDuration: TimeInterval?
    var timeLeft: TimeInterval?
    var description: String
    var index: Int
    
    init(
      isDone: Bool = false,
      isTimerOn: Bool = false,
      timerDuration: TimeInterval? = nil,
      timeLeft: TimeInterval? = nil,
      description: String,
      index: Int
    ) {
      self.isDone = isDone
      self.isTimerOn = isTimerOn
      self.timerDuration = timerDuration
      self.timeLeft = timeLeft
      self.description = description
      self.index = index
    }
    
    var timerDescription: String {
      guard let timeLeft = self.timeLeft else { return "" }
      return timeLeft.description
    }
  }
}
