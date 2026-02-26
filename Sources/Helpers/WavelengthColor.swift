import SwiftUI

/// Converts a wavelength in nanometers (380-780) to an approximate RGB color.
/// Based on Dan Bruton's algorithm for visible spectrum approximation.
func colorForWavelength(_ wavelength: Double) -> Color {
    let w = wavelength
    var r: Double = 0
    var g: Double = 0
    var b: Double = 0

    if w >= 380 && w < 440 {
        r = -(w - 440) / (440 - 380)
        g = 0
        b = 1
    } else if w >= 440 && w < 490 {
        r = 0
        g = (w - 440) / (490 - 440)
        b = 1
    } else if w >= 490 && w < 510 {
        r = 0
        g = 1
        b = -(w - 510) / (510 - 490)
    } else if w >= 510 && w < 580 {
        r = (w - 510) / (580 - 510)
        g = 1
        b = 0
    } else if w >= 580 && w < 645 {
        r = 1
        g = -(w - 645) / (645 - 580)
        b = 0
    } else if w >= 645 && w <= 780 {
        r = 1
        g = 0
        b = 0
    }

    // Intensity falloff at edges of visible spectrum
    var intensity: Double = 1.0
    if w >= 380 && w < 420 {
        intensity = 0.3 + 0.7 * (w - 380) / (420 - 380)
    } else if w > 700 && w <= 780 {
        intensity = 0.3 + 0.7 * (780 - w) / (780 - 700)
    }

    r *= intensity
    g *= intensity
    b *= intensity

    return Color(red: r, green: g, blue: b)
}

/// Returns the index of refraction for a given wavelength using Cauchy's equation.
/// Models the dispersion of crown glass.
func refractiveIndex(wavelength: Double) -> Double {
    let lambdaMicrons = wavelength / 1000.0  // Convert nm to microns
    // Cauchy coefficients for crown glass
    let a = 1.5220
    let b = 0.00459
    return a + b / (lambdaMicrons * lambdaMicrons)
}

/// Spectral wavelengths for the visible spectrum, evenly spaced
let spectralWavelengths: [Double] = stride(from: 380.0, through: 700.0, by: 5.0).map { $0 }

/// Named spectral colors with their approximate wavelengths
let namedColors: [(name: String, wavelength: Double)] = [
    ("Red", 680),
    ("Orange", 610),
    ("Yellow", 580),
    ("Green", 530),
    ("Blue", 470),
    ("Indigo", 435),
    ("Violet", 400)
]
