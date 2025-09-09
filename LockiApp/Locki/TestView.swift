//
//  TestView.swift
//  Locki
//
//  Created by Derek Hu on 7/31/25.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.14, blue: 0.21)
                .ignoresSafeArea()
            
            VStack {
                Text("Test Preview")
                    .foregroundStyle(.white)
                    .font(.title)
                
                Button("Test Button") {
                    print("Test")
                }
                .foregroundStyle(.white)
                .padding()
                .background(.blue)
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    TestView()
}
