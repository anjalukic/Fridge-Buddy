//
//  ImageSaverView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 25.8.23..
//

import SwiftUI
import UIKit

struct ImageSaverView: View {
  @Binding private var selectedImageData: Data?
  @State private var isImagePickerPresented = false
  
  public init(data: Binding<Data?>) {
    self._selectedImageData = data
  }
  
  var body: some View {
    HStack {
      if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
        Image(uiImage: uiImage)
          .resizable()
          .scaledToFit()
          .frame(width: 46, height: 46)
      }
      Button(self.selectedImageData == nil ? "Select an image" : "Change image") {
        isImagePickerPresented.toggle()
      }
    }
    .sheet(isPresented: $isImagePickerPresented) {
      ImagePicker(selectedImageData: $selectedImageData)
    }
  }
}

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var selectedImageData: Data?
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .photoLibrary
    imagePicker.delegate = context.coordinator
    return imagePicker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let uiImage = info[.originalImage] as? UIImage {
        if let imageData = uiImage.jpegData(compressionQuality: 1.0) {
          parent.selectedImageData = imageData
        }
      }
      
      picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
