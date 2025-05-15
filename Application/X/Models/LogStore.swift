//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import Foundation
import SwiftUI

class LogStore: ObservableObject {
    @Published var messages: [String] = []
    
    func append(message: String) {
        messages.append(message)
    }
    
    func clear() {
        messages.removeAll()
    }
    
    func clearMessages() {
        clear()
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
