//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import Foundation
import SwiftUI

// 移除之前的类定义，统一使用这一个实现
class LogStore: ObservableObject {
    @Published var logs: [String] = []
    static let shared = LogStore()
    
    func append(message: String) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            let logEntry = "[\(timestamp)] \(message)"
            print(logEntry)
            self.logs.append(logEntry)
            
            // 限制日志数量避免内存占用过多
            if self.logs.count > 1000 {
                self.logs.removeFirst(500)
            }
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
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
