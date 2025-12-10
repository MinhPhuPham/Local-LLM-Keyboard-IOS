//
//  Tokenizer.swift
//  custom-keyboard-ios
//
//  Created by Phu Pham on 10/12/25.
//

import Foundation

class Tokenizer {
    private var vocabMap: [String: Int] = [:]
    private var reverseVocabMap: [Int: String] = [:]
    let vocabSize: Int
    
    init?() {
        // Load vocabulary
        guard let vocabPath = Bundle.main.path(forResource: "tokenizer", ofType: "vocab") else {
            print("Tokenizer vocab not found")
            return nil
        }
        
        do {
            let vocabContent = try String(contentsOfFile: vocabPath, encoding: .utf8)
            let lines = vocabContent.components(separatedBy: .newlines)
            
            for (index, line) in lines.enumerated() {
                let parts = line.components(separatedBy: "\t")
                if parts.count >= 1 {
                    let token = parts[0]
                    vocabMap[token] = index
                    reverseVocabMap[index] = token
                }
            }
            
            vocabSize = vocabMap.count
        } catch {
            print("Error loading vocab: \(error)")
            return nil
        }
    }
    
    func encode(_ text: String) -> [Int] {
        // Simplified tokenization
        // In production, use SentencePiece library or implement BPE
        let words = text.lowercased().components(separatedBy: .whitespaces)
        return words.compactMap { word in
            // Simple hash-based encoding (replace with proper SentencePiece)
            abs(word.hashValue % vocabSize)
        }
    }
    
    func decode(_ ids: [Int]) -> String {
        // Simplified decoding
        return ids.compactMap { reverseVocabMap[$0] }.joined(separator: " ")
    }
}
