import SwiftUI

enum Demo: String, CaseIterable, Identifiable {
    case fallingApple = "Falling Apple"
    case prism = "Prism & Light"
    case inverseSquare = "Inverse Square Law"
    case cradle = "Newton's Cradle"
    case orbits = "Orbital Mechanics"
    case threeLaws = "Three Laws"
    case colorWheel = "Colour Circle"
    case calculus = "Calculus"
    case projectile = "Projectile Motion"
    case particles = "Particle Gravity"
    case cooling = "Law of Cooling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fallingApple: return "arrow.down.app"
        case .prism: return "rainbow"
        case .inverseSquare: return "dot.radiowaves.right"
        case .cradle: return "circle.grid.3x3"
        case .orbits: return "globe.americas"
        case .threeLaws: return "list.number"
        case .colorWheel: return "circle.hexagongrid"
        case .calculus: return "function"
        case .projectile: return "arrow.up.right"
        case .particles: return "sparkles"
        case .cooling: return "thermometer.medium"
        }
    }

    var subtitle: String {
        switch self {
        case .fallingApple:
            return "The Legend (c. 1666)"
        case .prism:
            return "Opticks (1704)"
        case .inverseSquare:
            return "F \u{221D} 1/r\u{00B2}"
        case .cradle:
            return "Conservation of Momentum"
        case .orbits:
            return "Principia Mathematica (1687)"
        case .threeLaws:
            return "Principia (1687)"
        case .colorWheel:
            return "Opticks (1704)"
        case .calculus:
            return "Method of Fluxions"
        case .projectile:
            return "Laws of Motion"
        case .particles:
            return "Forces & Acceleration"
        case .cooling:
            return "Exponential Decay"
        }
    }

    var description: String {
        switch self {
        case .fallingApple:
            return "According to legend, Newton was inspired to formulate his theory of gravitation when he observed an apple falling from a tree around 1666. This moment led to his realization that the same force pulling the apple toward Earth also keeps the Moon in orbit. The gravitational field visualization shows how every point in space experiences a force directed toward the Earth's center."
        case .prism:
            return "In 1666, Newton used a glass prism to demonstrate that white light is composed of a spectrum of colors. By refracting sunlight, he showed that each color bends at a slightly different angle due to its wavelength, decomposing white light into the visible spectrum. This experiment fundamentally changed our understanding of the nature of light."
        case .inverseSquare:
            return "Newton demonstrated that gravitational force decreases with the square of the distance. At twice the distance, the force is four times weaker; at three times the distance, nine times weaker. This is because the same force spreads over an area that grows as r\u{00B2}. This same law governs light intensity, sound, and electromagnetic radiation."
        case .cradle:
            return "Newton's Cradle demonstrates the conservation of momentum and kinetic energy. When a ball on one end strikes the stationary balls, the force propagates through the line, launching the ball on the opposite end. This elegant device illustrates Newton's Third Law: for every action, there is an equal and opposite reaction."
        case .orbits:
            return "Newton's Law of Universal Gravitation states that every mass attracts every other mass with a force proportional to the product of their masses and inversely proportional to the square of the distance between them: F = G(m\u{2081}m\u{2082})/r\u{00B2}. This law explains planetary orbits, tides, and the motion of celestial bodies."
        case .threeLaws:
            return "Newton's Three Laws of Motion form the foundation of classical mechanics. The First Law (Inertia) states an object at rest stays at rest, and an object in motion stays in motion, unless acted upon by a force. The Second Law defines force as mass times acceleration (F = ma). The Third Law states that every action has an equal and opposite reaction."
        case .colorWheel:
            return "In his 1704 work Opticks, Newton arranged the seven spectral colors (red, orange, yellow, green, blue, indigo, violet) in a circle, creating the first color wheel. He predicted that spinning the wheel rapidly would cause the colors to blend into white, demonstrating that white light contains all colors of the spectrum."
        case .calculus:
            return "Newton developed the method of fluxions (calculus) to describe rates of change and areas under curves. The derivative gives the instantaneous rate of change of a function, while the integral accumulates area. The Fundamental Theorem of Calculus unifies these two operations as inverses of each other."
        case .projectile:
            return "Newton's Second Law, F = ma, governs the motion of projectiles under gravity. An object launched at an angle follows a parabolic trajectory determined by its initial velocity and the constant downward pull of gravity. Without air resistance, the horizontal and vertical motions are independent."
        case .particles:
            return "A particle fountain demonstrating Newton's Second Law in action. Hundreds of particles launch upward and fall back under gravity, colored by their velocity, height, or as a rainbow. Add wind force to see how horizontal forces combine with gravity. Each particle independently obeys F = ma."
        case .cooling:
            return "Newton's Law of Cooling states that the rate of heat loss of a body is proportional to the difference between its temperature and its surroundings: dT/dt = -k(T - T_env). This produces exponential decay toward the ambient temperature, with the cooling rate k depending on the object's properties. Newton published this in 1701."
        }
    }
}
