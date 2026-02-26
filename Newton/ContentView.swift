import SwiftUI

struct ContentView: View {
    @State private var selectedDemo: Demo? = .fallingApple

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDemo) {
                ForEach(Demo.allCases) { demo in
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
                            .frame(width: 20)
                    }
                    .padding(.vertical, 4)
                    .tag(demo)
                }
            }
            .navigationTitle("Newton")
            .listStyle(.sidebar)
        } detail: {
            if let demo = selectedDemo {
                DemoDetailView(demo: demo)
                    .id(demo)
            } else {
                WelcomeView()
            }
        }
        .onAppear {
            // Ensure window is properly sized
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "apple.logo")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Newton")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Text("Interactive Physics Demonstrations")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Select a demonstration from the sidebar")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DemoDetailView: View {
    let demo: Demo
    @State private var showInfo = false

    var body: some View {
        VStack(spacing: 0) {
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
                case .threeLaws:
                    ThreeLawsView()
                case .colorWheel:
                    ColorWheelView()
                case .calculus:
                    CalculusView()
                case .projectile:
                    ProjectileView()
                case .particles:
                    ParticleGravityView()
                case .cooling:
                    CoolingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showInfo {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: demo.icon)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(demo.rawValue)
                            .font(.headline)
                        Text(demo.description)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showInfo.toggle()
                    }
                } label: {
                    Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                }
                .help("About this demonstration (i)")
                .keyboardShortcut("i", modifiers: [])
            }
        }
        .navigationTitle(demo.rawValue)
        .navigationSubtitle(demo.subtitle)
    }
}
