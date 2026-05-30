import CometransCore
import SwiftUI

struct AIProviderSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Default Provider") {
                Picker("Provider", selection: Binding(
                    get: { settings.selectedProvider },
                    set: { settings.selectedProvider = $0 }
                )) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                Text("Cometrans will use this provider when any shortcut is triggered.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
