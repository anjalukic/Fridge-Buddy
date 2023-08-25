//
//  QRScannerView.swift
//  Fridge Buddy
//
//  Created by Anja Lukic on 22.8.23..
//

import Foundation
import SwiftUI
import CodeScanner
import Fuzi

public struct ScannedItem: Identifiable, Equatable {
  public var id = UUID()
  var name: String
  var amount: Float
}

struct QRScannerView: View {
  var onScan: ([ScannedItem]) -> Void
  
  public init(onScan: @escaping ([ScannedItem]) -> Void) {
    self.onScan = onScan
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack {
        Spacer()
        HStack {
          Spacer()
          CodeScannerView(codeTypes: [.qr]) { result in
            self.handleScanResult(result)
          }
          .frame(width: min(geometry.size.width, geometry.size.height) * 0.8, height: min(geometry.size.width, geometry.size.height) * 0.8)
          .background(Color.gray.opacity(0.5))
          .cornerRadius(10)
          .padding()
          Spacer()
        }
        Text("Align your QR code in this window to scan it")
          .fontWeight(.light)
        Spacer()
      }
    }
  }
  
  private func handleScanResult(_ result: Result<ScanResult, ScanError>) {
    guard case .success(let scanResult) = result else {
      self.onScan([])
      return
    }
    self.fetchURLContents(urlString: scanResult.string)
  }
  
  private func fetchURLContents(urlString: String) {
    guard let url = URL(string: urlString) else {
      self.onScan([])
      return
    }
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      guard let data, let contents = String(data: data, encoding: .utf8) else {
        self.onScan([])
        return
      }
      DispatchQueue.main.async {
        guard let content = parsePreTag(contents: contents) else {
          self.onScan([])
          return
        }
        parseContents(contents: content)
      }
    }
    task.resume()
  }
  
  private func parsePreTag(contents: String) -> String? {
    do {
      let document = try HTMLDocument(string: contents)
      
      if let preElement = document.firstChild(xpath: "//pre[starts-with(text(),'============ ФИСКАЛНИ РАЧУН ============')]") {
        return preElement.stringValue
      }
    } catch {
      return nil
    }
    return nil
  }
  
  private func parseContents(contents: String) {
    var items: [ScannedItem] = []
    
    let content = contents.split(separator: "========================================")[1]
      .split(separator: "----------------------------------------")[0]
    
    var lines = content.components(separatedBy: "\r\n")
    lines = Array(lines[2..<lines.count - 1])
    
    for i in stride(from: 0, to: lines.count, by: 2) {
      var trimmedLine = lines[i].components(separatedBy: " ").filter { !$0.isEmpty }.joined(separator: " ")
      var trimmedLine2 = lines[i + 1].components(separatedBy: " ").filter { !$0.isEmpty }[1]
      trimmedLine2 = trimmedLine2.replacingOccurrences(of: ",", with: ".")
      guard let amount = Float(trimmedLine2) else { continue }
      let item = ScannedItem.init(
        name: trimmedLine,
        amount: amount
      )
      items.append(item)
    }
    self.onScan(items)
    return
  }
}
