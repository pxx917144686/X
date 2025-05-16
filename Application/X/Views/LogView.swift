//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // 修改这里，使用logStore.logs而不是logStore.messages
                ForEach(logStore.logs, id: \.self) { message in
                    Text(message)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("日志")
        .toolbar {
            Button("清除") {
                logStore.clear()
            }
        }
    }
}
