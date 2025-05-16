//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import Foundation
import SwiftUI

// 保留这一个统一的LogStore实现
class LogStore: ObservableObject {
    @Published var logs: [String] = []
    
    // 添加单例，便于全局访问
    static let shared = LogStore()
    
    func append(message: String) {
        DispatchQueue.main.async {
            self.logs.append("\(self.formattedDate()): \(message)")
            print(message)
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

// 日志视图组件
struct LogDisplayView: View {
    @Binding var logMessages: [String]
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("操作日志")
                    .font(.caption.bold())
                
                Spacer()
                
                Button(action: {
                    logStore.clear()
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logMessages.reversed(), id: \.self) { message in
                        Text(message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal, 8)
    }
}
