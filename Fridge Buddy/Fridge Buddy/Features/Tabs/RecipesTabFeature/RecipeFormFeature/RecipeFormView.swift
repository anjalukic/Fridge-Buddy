//
//  RecipeFormView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 10.8.23..
//

import Foundation
import SwiftUI
import ComposableArchitecture

public struct RecipeFormView: View {
  private let store: StoreOf<RecipeFormFeature>
  @State private var groceryItem: GroceryItem?
  @State private var amount = 1.0
  @State private var unitId: String = Unit.pcs.id
  @State private var stepDescription: String = ""
  @State private var stepTime: Int?
  
  public init(store: StoreOf<RecipeFormFeature>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Form {
        Section("Name") {
          self.name
        }
        Section {
          HStack {
            ImageSaverView(data: viewStore.binding(\.$recipe.image))
            if viewStore.state.recipe.image != nil {
              Button { viewStore.send(.didTapRemoveImage) } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
              .buttonStyle(.plain)
            }
          }
        }
        Section("Ingredients") {
          self.ingredients
        }
        Section("Instructions") {
          self.instructions
        }
        Section {
          self.yieldAmount
        }
      }
      .navigationTitle(viewStore.isEditing ? "Editing \(viewStore.recipe.name)" : "Adding new recipe")
      .navigationBarItems(trailing: Button("Done", action: { viewStore.send(.didTapDone) }))
    }
  }
  
  private var name: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      TextField("Name", text: viewStore.binding(\.$recipe.name))
    }
  }
  
  private var ingredients: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        ForEach(viewStore.recipeItems) { recipeItem in
          HStack {
            ItemView(name: recipeItem.name, amount: recipeItem.amount, unitName: recipeItem.unit)
              .foregroundColor(.black)
            Button {
              viewStore.send(.didTapRemoveRecipeItem(recipeItem.id))
            } label: {
              Image(systemName: "trash").foregroundColor(.red)
            }
          }
        }
        
        HStack(alignment: .top) {
          SearchBarListView<GroceryItem>(
            listItems: .init(viewStore.groceryItems),
            placeholderText: "Add new ingredient",
            onSelect: { self.groceryItem = $0 },
            onCommit: { _ in }
          )
          
          TextField("Amount", value: self.$amount, format: .number)
            .keyboardType(.decimalPad)
          
          Picker("", selection: self.$unitId) {
            ForEach(Unit.startingUnits) { unit in
              Text(unit.name)
                .tag(unit.id)
            }
          }
          .pickerStyle(.menu)
          
          Button {
            if let groceryItem {
              viewStore.send(.didTapAddRecipeItem(groceryItem, amount: self.amount, unitId: unitId))
              self.amount = 1.0
              self.unitId = Unit.pcs.id
              self.groceryItem = nil
            }
          } label: {
            Image(systemName: "checkmark")
          }
          .disabled(self.groceryItem == nil)
        }
      }
      .buttonStyle(.bordered)
    }
  }
  
  private var instructions: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        ForEach(viewStore.recipeSteps) { recipeStep in
          HStack {
            Text("\(recipeStep.index + 1)")
              .font(.system(size: 16, weight: .semibold))
              .padding(.trailing, 6)
            Text(recipeStep.description)
              .frame(maxWidth: .infinity, alignment: .leading)
          
            if let time = recipeStep.timerDuration {
              Image(systemName: "timer")
              Text("\(time.description)")
            }
            
            Button {
              viewStore.send(.didTapRemoveRecipeStep(recipeStep.id))
            } label: {
              Image(systemName: "trash").foregroundColor(.red)
            }
          }
        }
        
        HStack(alignment: .top) {
          Text("\(viewStore.recipeSteps.count + 1)")
            .font(.system(size: 16, weight: .semibold))
            .padding(.trailing, 6)
          TextField("Description", text: self.$stepDescription, prompt: Text("Add a step"))
          TextField("Add time", value: self.$stepTime, format: .number)
            .keyboardType(.decimalPad)
          Text("mins")
          Button {
            viewStore.send(.didTapAddRecipeStep(description: self.stepDescription, timeInMins: self.stepTime))
            self.stepDescription = ""
            self.stepTime = nil
          } label: {
            Image(systemName: "checkmark")
          }
          .disabled(self.stepDescription.isEmpty)
        }
      }
      .buttonStyle(.bordered)
    }
  }
  
  private var yieldAmount: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack {
        Text("Yields")
        TextField("how many", value: viewStore.binding(\.$recipe.yieldAmount), format: .number)
          .keyboardType(.decimalPad)
        Text("servings")
      }
    }
  }
}
