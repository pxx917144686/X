//
//  ExperimentalView.swift
//  X
//
//  Created by pxx917144686 on 2025/05/15.
//

import SwiftUI

struct LogsView: View {
    var logStore: LogStore
    var statusText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("执行日志")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(statusText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                    )
                    .foregroundColor(.white)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // 修正ForEach的使用方式，logs是[String]类型
                    ForEach(0..<logStore.logs.count, id: \.self) { index in
                        Text(logStore.logs[index])
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(getLogColor(logStore.logs[index]))
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var statusColor: Color {
        if statusText.contains("失败") {
            return .red
        } else if statusText.contains("成功") || statusText.contains("完成") {
            return .green
        } else if statusText.contains("执行") {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func getLogColor(_ message: String) -> Color {
        if message.contains("[+]") || message.contains("成功") {
            return .green
        } else if message.contains("[-]") || message.contains("失败") || message.contains("错误") {
            return .red
        } else if message.contains("[*]") {
            return .blue
        } else {
            return .primary
        }
    }
}

// 添加一个简单的LogView用于实验视图
struct LogView: View {
    var logStore: LogStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<logStore.logs.count, id: \.self) { index in
                    Text(logStore.logs[index])
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
}
