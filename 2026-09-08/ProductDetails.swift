//
//  ProductDetails.swift
//  SwiftUIDemo
//
//  Created by user301577 on 9/8/26.
//

import SwiftUI

struct ProductDetails: View {

var product: Product

var body: some View {
    @Bindable var prodBinding = product
    
    VStack {
        Text("Product Details")
            .font(.largeTitle)
            .fontWeight(.bold)
            Text("Product ID: \(product.id)")
                .font(Font.title)
                .padding(20)
        Text("Product Number: \(product.productNumber)")
                .font(Font.title)
                .padding(20)
        Text("Product Color: \(product.color)")
                .font(Font.title)
                .padding(20)
            Text("Listing Price: $\(String(format: "%.2f", product.listPrice))")
                .font(Font.title)
                .padding(20)
    }
    .padding()
}

}

#Preview {
ContentView()
}
