//
//  JSONLoader.swift
//  EsimDemo
//
//  Created by Swarajmeet Singh on 05/09/25.
//

import Foundation

class JSONLoader: ObservableObject {
    @Published var esimResponse: ESIMResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadESIMData() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "sample_esim_data", withExtension: "json") else {
            errorMessage = "Could not find sample_esim_data.json file"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            esimResponse = try decoder.decode(ESIMResponse.self, from: data)
        } catch {
            errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
