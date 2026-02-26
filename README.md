# Newton

A native macOS application featuring **11 interactive physics demonstrations** inspired by the work of Sir Isaac Newton. Built entirely with SwiftUI and Canvas rendering, running natively on Apple Silicon with zero external dependencies.

## Demonstrations

### 1. The Falling Apple
The legendary moment that sparked Newton's theory of gravitation. Features a gravitational field visualization with directional arrows, a bouncing apple with adjustable Earth mass, force vector display, and a stick-figure Newton sitting under the tree. Click or press Space to drop the apple.

### 2. Prism & Light Dispersion
Newton's famous 1666 experiment decomposing white light through a glass prism. Uses Snell's Law with wavelength-dependent refractive indices (Cauchy's equation) to accurately model how different colors of light refract at different angles. Adjustable prism angle and beam position with labeled spectrum output.

### 3. Inverse Square Law
Interactive visualization of how gravitational (and light) intensity decreases with the square of distance. Features animated expanding wavefronts, area panels showing how force spreads, and a real-time graph comparing 1/r^2 vs 1/r falloff curves.

### 4. Newton's Cradle
Classic conservation of momentum demonstration with 5 chrome-rendered pendulum balls. Includes preset configurations (1-ball, 2-ball, 3-ball, opposing), drag interaction, V-shape strings, metallic ball shading, and an energy conservation readout. Physics uses substep integration for stability.

### 5. Orbital Mechanics
N-body gravitational simulation implementing Newton's Law of Universal Gravitation. Three presets:
- **Solar System**: Sun with Mercury through Jupiter
- **Binary Star**: Two co-orbiting stars with a circumbinary planet
- **Lagrange Points**: Sun-Earth system with L4/L5 Trojan asteroids

Features orbital trails, velocity vectors, adjustable time scale, and a deterministic star field background.

### 6. Three Laws of Motion
Tabbed demonstration of all three Newtonian laws:
- **First Law (Inertia)**: A puck on a frictionless vs. rough surface
- **Second Law (F = ma)**: Adjustable force and mass with real-time acceleration calculation
- **Third Law (Action-Reaction)**: Elastic collision with visible equal-and-opposite force arrows

### 7. Newton's Colour Circle
Newton's 1704 arrangement of the seven spectral colors into the first color wheel. Spin the wheel to see colors merge toward white, demonstrating that white light is a combination of all spectral colors. Features wavelength labels, adjustable speed, and sector display.

### 8. Calculus (Method of Fluxions)
Interactive function plotter with derivative and integral visualization. Four selectable functions (x^2, sin(x), x^3-x, Gaussian). Features:
- Draggable tangent line showing instantaneous slope
- Derivative curve overlay (dashed orange)
- Riemann sum integral visualization with adjustable rectangle count (2-100)

### 9. Projectile Motion
Launch projectiles at configurable angles and speeds under gravity. Displays theoretical range, max height, and flight time. Compare trajectories with and without air resistance. Toggle the optimal 45-degree reference arc. Each launch gets a unique color for easy comparison.

### 10. Particle Gravity
A particle fountain demonstrating F = ma with hundreds of simultaneous particles. Particles launch upward and fall under adjustable gravity, with optional wind force. Three color modes: velocity-based, height-based, or rainbow. Toggle velocity vectors to see acceleration in action.

### 11. Law of Cooling
Newton's Law of Cooling: T(t) = T_env + (T_0 - T_env) * e^(-kt). Real-time exponential decay graph with temperature-colored data points, a thermometer visualization, and adjustable parameters (initial temperature, room temperature, cooling rate k). Optional linear cooling comparison shows why exponential decay is the correct model.

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

Or build a release for better performance:
```bash
swift build -c release
.build/release/Newton
```

## Controls

- **Sidebar**: Click any demo to switch between demonstrations
- **Info Panel**: Press `i` or click the info button to show/hide the description panel
- Each demo has its own interactive controls in the bottom bar

## Architecture

```
Newton/
  Package.swift                # Swift Package Manager manifest
  Sources/
    NewtonApp.swift            # @main App entry point
    ContentView.swift          # NavigationSplitView with sidebar
    Models/
      Demo.swift               # Demo enum with metadata and descriptions
    Views/
      FallingAppleView.swift     # Gravitational field + falling apple
      PrismView.swift            # Light dispersion through a prism
      InverseSquareView.swift    # 1/r^2 law visualization
      CradleView.swift           # Newton's Cradle pendulums
      OrbitsView.swift           # N-body orbital simulation
      ThreeLawsView.swift        # All three laws of motion
      ColorWheelView.swift       # Newton's colour circle
      CalculusView.swift         # Derivatives and integrals
      ProjectileView.swift       # Projectile trajectory simulator
      ParticleGravityView.swift  # Particle fountain with gravity
      CoolingView.swift          # Exponential cooling curve
    Helpers/
      WavelengthColor.swift    # Visible spectrum color + refraction
```

All demos use SwiftUI `Canvas` for high-performance 2D rendering at 60fps. Physics simulations run using `TimelineView` for animation timing. No external dependencies required.

## Physics & Math

The simulations implement real physics:

| Law/Equation | Formula | Used In |
|---|---|---|
| Snell's Law | n1 sin(theta1) = n2 sin(theta2) | Prism |
| Cauchy's Equation | n(lambda) = A + B/lambda^2 | Prism |
| Universal Gravitation | F = G * m1 * m2 / r^2 | Orbits, Falling Apple |
| Inverse Square Law | F proportional to 1/r^2 | Inverse Square |
| Pendulum Dynamics | alpha = -g/L * sin(theta) | Cradle |
| Elastic Collision | m1*v1 + m2*v2 = m1*v1' + m2*v2' | Cradle, Three Laws |
| Newton's Second Law | F = ma | Three Laws, Particles |
| Projectile Motion | R = v0^2 * sin(2*theta) / g | Projectile |
| Numerical Integration | Midpoint Riemann sums | Calculus |
| Exponential Decay | T(t) = T_env + (T0 - T_env) * e^(-kt) | Cooling |

## Credits

Built entirely by [Claude Opus 4.6](https://www.anthropic.com/claude) as an autonomous creative coding project demonstrating native macOS development with SwiftUI.

Inspired by **Sir Isaac Newton** (1643-1727), whose contributions to mathematics, optics, and physics laid the foundations of modern science.

> *"If I have seen further, it is by standing on the shoulders of giants."*
> -- Isaac Newton, 1675
