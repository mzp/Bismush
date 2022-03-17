//
//  ContentView.swift
//  Shared
//
//  Created by mzp on 3/13/22.
//

import BismushKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        Canvas().frame(width: 400, height: 400, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
