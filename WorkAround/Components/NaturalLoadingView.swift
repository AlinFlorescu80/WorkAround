//
//  NaturalLoadingView.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI

struct NaturalLoadingView: View {
    @Binding var isLoading: Bool
    var onAnimationEnd: () -> Void
    
    @State private var tilt = false
    @State private var pulse = false
    @State private var zoomIn = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("WorkAroundIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .saturation(zoomIn ? 0 : 1)
                .scaleEffect(zoomIn ? 100 : (pulse ? 1.15 : 1.05))
                .opacity(zoomIn ? 0 : 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear {
            pulse.toggle()
        }
        .onChange(of: isLoading) { oldValue, newValue in
            if !newValue {
                withAnimation(.easeIn(duration: 0.5)) {
                    zoomIn = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onAnimationEnd()
                }
            }
        }
    }
}
