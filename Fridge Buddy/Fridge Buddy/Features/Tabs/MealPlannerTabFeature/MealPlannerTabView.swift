//
//  MealPlannerTabView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 23.5.23..
//

import SwiftUI
import ComposableArchitecture

public struct MealPlannerTabView: View {
  private let store: StoreOf<MealPlannerTabFeature>

  public init(store: StoreOf<MealPlannerTabFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      self.calendar
        .padding(16)
        .alert(self.store.scope(state: \.alert?.alertState, action: { .alert($0) }), dismiss: .didDismiss)
        .sheet(
          store: self.store.scope(state: \.$recipesList, action: { .recipesList($0) })
        ) { store in
          RecipesListView(store: store)
        }
        .onAppear {
          viewStore.send(.onAppear)
        }
    }
  }
  
  private var calendar: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 8) {
        DatePicker(
          selection: viewStore.binding(get: { $0.selectedDate }, send: { .didChangeSelectedDate($0) }),
          in: Date()...Date() + TimeInterval(fromDays: 13),
          displayedComponents: [.date]
        ) {}
          .datePickerStyle(.compact)
          .clipped()
          .labelsHidden()
          .padding(.vertical, 16)
        
        ForEach(PlannedMeal.Meal.allCases) { mealType in
          HStack(spacing: 6) {
            Text("\(mealType.title):")
            if let meal = viewStore.state.mealForSelectedDate(mealType: mealType) {
              HStack {
                Button { viewStore.send(.didTapChangeMeal(mealType)) } label: {
                  Text(meal.recipeName)
                }
                Button { viewStore.send(.didTapDeleteMeal(mealType)) } label: {
                  Image(systemName: "trash")
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
              }
            } else {
              Button { viewStore.send(.didTapAddNewMeal(mealType)) } label: {
                Image(systemName: "plus")
              }
            }
            Spacer()
          }
        }
        
        Spacer()
      }
      .buttonStyle(.bordered)
    }
  }
}

extension MealPlannerTabFeature.State.Alert {
  fileprivate var alertState: AlertState<MealPlannerTabFeature.Action.AlertAction> {
    switch self {
    case .confirmDeletion(let meal):
      return .init(
        title: .init("Do you really want to delete?"),
        message: .init("\(meal.mealType.title) on \(meal.date.formattedDate()) : \(meal.recipeName)"),
        primaryButton: .destructive(.init("Delete"), action: .send(.didTapConfirmDeletion)),
        secondaryButton: .cancel(.init("Cancel"), action: .send(.didTapCancelDeletion))
      )
    }
  }
}

