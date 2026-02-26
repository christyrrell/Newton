# Newton

A native macOS application featuring **8 interactive physics demonstrations** inspired by the work of Sir Isaac Newton. Built with SwiftUI and Canvas rendering, running natively on Apple Silicon.

## Demonstrations

### 1. The Falling Apple
The legendary moment that sparked Newton's theory of gravitation. Features a gravitational field visualization with directional arrows, a bouncing apple with adjustable Earth mass, and force vector display. Click or press Space to drop the apple.

### 2. Prism & Light Dispersion
Newton's famous 1666 experiment decomposing white light through a glass prism. Uses Snell's Law with wavelength-dependent refractive indices (Cauchy's equation) to accurately model how different colors of light refract at different angles. Adjustable prism angle and beam position.

### 3. Inverse Square Law
Interactive visualization of how gravitational (and light) intensity decreases with the square of distance. Features animated expanding wavefronts, area panels showing force spreading, and a real-time graph comparing 1/r^2 vs 1/r falloff curves.

### 4. Newton's Cradle
Classic conservation of momentum demonstration with 5 chrome-rendered pendulum balls. Includes preset configurations (1-ball, 2-ball, 3-ball, opposing), drag interaction, V-string rendering, and an energy conservation readout. Physics uses substep integration for stability.

### 5. Orbital Mechanics
N-body gravitational simulation implementing Newton's Law of Universal Gravitation (F = Gm1m2/r^2). Three presets:
- **Solar System**: Sun with Mercury through Jupiter
- **Binary Star**: Two co-orbiting stars with a circumbinary planet
- **Lagrange Points**: Sun-Earth system with L4/L5 Trojan objects

Features orbital trails, velocity vectors, adjustable time scale, and a background star field.

### 6. Three Laws of Motion
Tabbed demonstration of all three Newtonian laws:
- **First Law (Inertia)**: A puck on a frictionless vs. rough surface
- **Second Law (F = ma)**: Adjustable force and mass with real-time acceleration display
- **Third Law (Action-Reaction)**: Elastic collision with visible force arrows

### 7. Calculus (Method of Fluxions)
Interactive function plotter with derivative and integral visualization. Four selectable functions (x^2, sin(x), x^3-x, Gaussian). Features:
- Draggable tangent line showing instantaneous slope
- Derivative curve overlay
- Riemann sum integral visualization with adjustable rectangle count

### 8. Projectile Motion
Launch projectiles at configurable angles and speeds under gravity. Displays theoretical range, max height, and flight time. Compare trajectories with and without air resistance. Toggle the optimal 45-degree reference arc.

## Building & Running

**Requirements:**
- macOS 15 (Sequoia) or later
- Swift 5.10+ / Xcode 16+
- Apple Silicon or Intel Mac

```bash
# Clone and build
git clone https://github.com/christyrrell/Newton.git
cd Newton
swift build

# Run
swift run
```

Or build a release:
```bash
swift build -c release
.build/release/Newton
```

## Architecture

```
Newton/
  Package.swift              # Swift Package Manager manifest
  Sources/
    NewtonApp.swift          # @main App entry point
    ContentView.swift        # NavigationSplitView with sidebar
    Models/
      Demo.swift             # Demo enum with metadata and descriptions
    Views/
      FallingAppleView.swift   # Gravitational field + falling apple
      PrismView.swift          # Light dispersion through a prism
      InverseSquareView.swift  # 1/r^2 law visualization
      CradleView.swift         # Newton's Cradle pendulums
      OrbitsView.swift         # N-body orbital simulation
      ThreeLawsView.swift      # All three laws of motion
      CalculusView.swift       # Derivatives and integrals
      ProjectileView.swift     # Projectile trajectory simulator
    Helpers/
      WavelengthColor.swift  # Visible spectrum color mapping
```

All demos use SwiftUI `Canvas` for high-performance 2D rendering at 60fps. Physics simulations run on the main thread using `TimelineView` for animation timing. No external dependencies.

## Physics & Math

The simulations implement real physics:

- **Snell's Law**: n1 sin(theta1) = n2 sin(theta2) with Cauchy dispersion
- **Universal Gravitation**: F = G * m1 * m2 / r^2
- **Pendulum Dynamics**: angular acceleration = -g/L * sin(theta)
- **Elastic Collisions**: conservation of momentum and kinetic energy
- **Projectile Motion**: R = v0^2 * sin(2*theta) / g
- **Numerical Integration**: midpoint Riemann sums for area under curves
- **N-body Simulation**: direct force summation with softened potential

## Credits

Built entirely by [Claude Opus 4.6](https://www.anthropic.com/claude) as an autonomous creative coding project.

Inspired by the work of **Sir Isaac Newton** (1643-1727), whose contributions to mathematics, optics, and physics laid the foundations of modern science.
