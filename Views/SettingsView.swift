import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @State private var tempUrl: String = ""
    @State private var tempToken: String = ""
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(theme.text)

                LabeledContent("SilverBullet URL") {
                    TextField("https://example.sb", text: $tempUrl)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("API Token") {
                    SecureField("Token", text: $tempToken)
                        .textFieldStyle(.roundedBorder)
                }

                LabeledContent("Theme") {
                    Picker("", selection: Binding(
                        get: { appState.theme },
                        set: { appState.theme = $0 }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                }

                LabeledContent("Font") {
                    Picker("", selection: Binding(
                        get: { appState.fontFamily },
                        set: { appState.fontFamily = $0 }
                    )) {
                        Text("System").tag("System")
                        ForEach(AppFont.availableFamilies, id: \.self) { family in
                            Text(family).tag(family)
                        }
                    }
                }

                LabeledContent("Font Size") {
                    HStack {
                        Slider(value: Binding(
                            get: { appState.fontSize },
                            set: { appState.fontSize = $0 }
                        ), in: 8...32, step: 1)
                        Text("\(Int(appState.fontSize))pt")
                            .font(.caption)
                            .foregroundStyle(theme.textMuted)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                LabeledContent("Opacity") {
                    HStack {
                        Slider(value: Binding(
                            get: { appState.opacity },
                            set: { appState.opacity = $0 }
                        ), in: 0.1...1.0, step: 0.01)
                        Text("\(Int(appState.opacity * 100))%")
                            .font(.caption)
                            .foregroundStyle(theme.textMuted)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                LabeledContent("Live Preview") {
                    Toggle("", isOn: Binding(
                        get: { appState.livePreviewEnabled },
                        set: { appState.livePreviewEnabled = $0 }
                    ))
                }

                HStack {
                    Button("Test Connection") {
                        Task { await testConnection() }
                    }
                    .disabled(isTesting)

                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.contains("successful") ? theme.success : theme.error)
                    }

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
        }
        .foregroundStyle(theme.text)
        .frame(width: 420, height: 400)
        .background(theme.bg)
        .onAppear {
            tempUrl = appState.sbUrl
            tempToken = appState.sbToken
        }
        .onChange(of: tempUrl) { _, newValue in
            appState.sbUrl = newValue
        }
        .onChange(of: tempToken) { _, newValue in
            appState.sbToken = newValue
        }
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        guard !tempUrl.isEmpty, !tempToken.isEmpty else {
            testResult = "URL and token required"
            return
        }
        let client = SbClient(baseURL: tempUrl, token: tempToken)
        do {
            _ = try await client.testConnection()
            testResult = "Connection successful"
        } catch {
            testResult = error.localizedDescription
        }
    }
}