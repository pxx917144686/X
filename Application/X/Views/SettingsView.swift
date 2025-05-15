import SwiftUI

struct SettingsView: View {
    @ObservedObject var logStore: LogStore
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("关于")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("作者: pxx917144686")
                            .font(.body)
                        
                        Link("GitHub: pxx917144686/X_ZH",
                             destination: URL(string: "https://github.com/pxx917144686/X_ZH/tree/main")!)
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("日志")) {
                    Button("清除日志") {
                        logStore.clear()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("设置")
        }
    }
}