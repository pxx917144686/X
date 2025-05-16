//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct LogView: View {
    @ObservedObject var logStore = LogStore.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // 确保LogStore有正确的属性名
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
