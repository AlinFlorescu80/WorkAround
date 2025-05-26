    //
    //  ItemCardView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI

struct ItemCardView: View {
    let item: Item
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
  
            }
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}
