//
//  KeyboardAIModel.swift
//  custom-keyboard-ios
//
//  Created by Phu Pham on 10/12/25.
//
import Foundation
import CoreML

class KeyboardAIModel {
    private let model: KeyboardAI
    private let tokenizer: Tokenizer
    private let vocabSize: Int
    
    init?() {
        // Load Core ML model
        // Note: Xcode compiles .mlpackage to .mlmodelc
        // Use compiledModelURL or load directly by class name
        do {
            // Option 1: Load by configuration (recommended)
            let config = MLModelConfiguration()
            self.model = try KeyboardAI(configuration: config)
            
            // Option 2: If Option 1 fails, try loading from bundle
            // guard let modelURL = Bundle.main.url(forResource: "KeyboardAI", withExtension: "mlmodelc"),
            //       let model = try? KeyboardAI(contentsOf: modelURL) else {
            //     print("Failed to load Core ML model")
            //     return nil
            // }
            // self.model = model
        } catch {
            print("Failed to load Core ML model: \(error)")
            return nil
        }
        
        // Load tokenizer
        guard let tokenizer = Tokenizer() else {
            print("Failed to load tokenizer")
            return nil
        }
        self.tokenizer = tokenizer
        
        // Read vocab size from metadata
        if let infoPath = Bundle.main.path(forResource: "model_info", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: infoPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let vocab = json["vocab_size"] as? Int {
            self.vocabSize = vocab
        } else {
            self.vocabSize = 100 // Default
        }
    }
    
    func predict(text: String, topK: Int = 5) -> [String] {
        // Tokenize input
        let tokenIds = tokenizer.encode(text)
        guard !tokenIds.isEmpty else { return [] }
        
        // Take last 50 tokens (model's max sequence length)
        let input = Array(tokenIds.suffix(50))
        
        // Pad to fixed length if needed
        var paddedInput = input
        while paddedInput.count < 50 {
            paddedInput.insert(0, at: 0) // Pad with 0
        }
        
        // Convert to MLMultiArray
        guard let inputArray = try? MLMultiArray(shape: [1, 50], dataType: .int32) else {
            return []
        }
        
        for (i, tokenId) in paddedInput.enumerated() {
            inputArray[i] = NSNumber(value: tokenId)
        }
        
        // Run inference
        guard let output = try? model.prediction(input_ids: inputArray) else {
            return []
        }
        
        // Get logits from output
        let logits = output.logits
        
        // Extract last token's predictions
        let lastTokenStart = (paddedInput.count - 1) * vocabSize
        var scores: [(index: Int, score: Float)] = []
        
        for i in 0..<vocabSize {
            let score = logits[lastTokenStart + i].floatValue
            scores.append((index: i, score: score))
        }
        
        // Get top-K
        let topScores = scores.sorted { $0.score > $1.score }.prefix(topK)
        
        // Convert to words
        return topScores.map { tokenizer.decode([$0.index]) }
    }
}
