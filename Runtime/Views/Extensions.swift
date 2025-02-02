//
//  Extensions.swift
//  Runtime
//
//  Created by ned on 02/02/25.
//

import SwiftUI

extension Duration {
    var inSeconds: Int {
        let v = components
        let milli = Double(v.seconds) * 1000 + Double(v.attoseconds) * 1e-15
        return Int((milli / 1000.0).rounded())
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
