//
//  Wave.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI

// https://www.hackingwithswift.com/plus/custom-swiftui-components/creating-a-waveview-to-draw-smooth-waveforms
struct Wave: Shape {
    var strength: Double
    var frequency: Double
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()

        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        let wavelength = width / frequency

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX)
            let y = strength * sine + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return Path(path.cgPath)
    }
}
