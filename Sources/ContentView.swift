import SwiftUI

struct ContentView: View {
    @State private var selectedDemo: Demo? = .fallingApple

    var body: some View {
        NavigationSplitView {
            List(Demo.allCases, selection: $selectedDemo) { demo in
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(demo.rawValue)
                            .font(.headline)
                        Text(demo.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: demo.icon)
                        .foregroundStyle(.blue)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Newton")
            .listStyle(.sidebar)
        } detail: {
            if let demo = selectedDemo {
                DemoDetailView(demo: demo)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Select a demonstration")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct DemoDetailView: View {
    let demo: Demo
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
            // Demo view
            Group {
                switch demo {
                case .fallingApple:
                    FallingAppleView()
                case .prism:
                    PrismView()
                case .inverseSquare:
                    InverseSquareView()
                case .cradle:
                    CradleView()
                case .orbits:
                    OrbitsView()
                case .calculus:
                    CalculusView()
                case .projectile:
                    ProjectileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Info bar
            if showInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text(demo.rawValue)
                        .font(.headline)
                    Text(demo.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showInfo.toggle()
                    }
                } label: {
                    Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                }
                .help("About this demonstration")
            }
        }
        .navigationTitle(demo.rawValue)
        .navigationSubtitle(demo.subtitle)
    }
}
