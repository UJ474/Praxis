import SwiftUI

struct ConnectionSettingsView: View {
    @ObservedObject var store: DesktopStore
    @AppStorage("apiBaseURL") private var baseURL = ""
    @AppStorage("apiToken") private var token = ""
    @State private var status = ""
    var body: some View {
        Form {
            Section("Backend connection") {
                TextField("https://your-app.up.railway.app", text: $baseURL).textFieldStyle(.roundedBorder)
                SecureField("API token", text: $token).textFieldStyle(.roundedBorder)
                HStack { Button("Test connection") { Task { status = await store.verifyConnection() } }.buttonStyle(EditorialButtonStyle()); if !status.isEmpty { Text(status).foregroundStyle(status == "Connected" ? .green : .red) } }
            }
            Section("Schedule") { Text("The server carries unfinished tasks at 12:05 AM Monday and checks Gmail hourly each Thursday from 6 AM to 11 PM, in Asia/Kolkata. Railway variables can change both time zones.").font(.footnote).foregroundStyle(.secondary) }
        }.formStyle(.grouped).frame(width: 500).padding().navigationTitle("3-2-1 Settings")
    }
}
