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
                // 使用logs属性而不是messages
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
