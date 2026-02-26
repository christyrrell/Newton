import SwiftUI

enum Demo: String, CaseIterable, Identifiable {
    case prism = "Prism & Light"
    case cradle = "Newton's Cradle"
    case orbits = "Orbital Mechanics"
    case calculus = "Calculus"
    case projectile = "Projectile Motion"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .prism: return "rainbow"
        case .cradle: return "circle.grid.3x3"
        case .orbits: return "globe.americas"
        case .calculus: return "function"
        case .projectile: return "arrow.up.right"
        }
    }

    var subtitle: String {
        switch self {
        case .prism:
            return "Opticks (1704)"
        case .cradle:
            return "Conservation of Momentum"
        case .orbits:
            return "Principia Mathematica (1687)"
        case .calculus:
            return "Method of Fluxions"
        case .projectile:
            return "Laws of Motion"
        }
    }

    var description: String {
        switch self {
        case .prism:
            return "In 1666, Newton used a glass prism to demonstrate that white light is composed of a spectrum of colors. By refracting sunlight, he showed that each color bends at a slightly different angle due to its wavelength, decomposing white light into the visible spectrum. This experiment fundamentally changed our understanding of the nature of light."
        case .cradle:
            return "Newton's Cradle demonstrates the conservation of momentum and kinetic energy. When a ball on one end strikes the stationary balls, the force propagates through the line, launching the ball on the opposite end. This elegant device illustrates Newton's Third Law: for every action, there is an equal and opposite reaction."
        case .orbits:
            return "Newton's Law of Universal Gravitation states that every mass attracts every other mass with a force proportional to the product of their masses and inversely proportional to the square of the distance between them: F = G(m\u{2081}m\u{2082})/r\u{00B2}. This law explains planetary orbits, tides, and the motion of celestial bodies."
        case .calculus:
            return "Newton developed the method of fluxions (calculus) to describe rates of change and areas under curves. The derivative gives the instantaneous rate of change of a function, while the integral accumulates area. The Fundamental Theorem of Calculus unifies these two operations as inverses of each other."
        case .projectile:
            return "Newton's Second Law, F = ma, governs the motion of projectiles under gravity. An object launched at an angle follows a parabolic trajectory determined by its initial velocity and the constant downward pull of gravity. Without air resistance, the horizontal and vertical motions are independent."
        }
    }
}
