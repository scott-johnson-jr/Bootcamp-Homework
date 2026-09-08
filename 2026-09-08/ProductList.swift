//
//  ProductList.swift
//  SwiftUIDemo
//
//  Created by user301577 on 9/8/26.
//
import SwiftUI

struct ProductList: View {
    
    @State private var products: [Product] = []
    
    var body: some View {
        NavigationStack {
            List(products) { prod in
                NavigationLink(value: prod) {
                    Text("\(prod.name) - \(prod.color)")
                }
            }
            .navigationTitle("Products")
            .navigationDestination(for: Product.self) {
                selectedItem in
                ProductDetails(product: selectedItem)
            }

        }
        .task {
            loadData()
        }
        
    }
    
    func loadData() {
        
    products = [
        Product(id: 001, name: "Product 1", productNumber: "P001", color: "Green", listPrice: 10.00),
        Product(id: 002, name: "Product 2", productNumber: "P001", color: "Yellow", listPrice: 15.00),
        Product(id: 003, name: "Product 3", productNumber: "P003", color: "Red", listPrice: 20.00),
        Product(id: 004, name: "Product 4", productNumber: "P004", color: "Gold", listPrice: 500.00)
]}
    
}

