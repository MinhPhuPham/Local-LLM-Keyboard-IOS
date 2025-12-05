//
//  PredictionEngine.swift
//  LLM Local Keyboard
//
//  Core prediction engine with top-K selection and caching
//  Optimized for iOS 15+ with <100ms latency target
//

import Foundation
import CoreML

/// Represents a text suggestion
struct Suggestion: Equatable {
    let text: String
    var score: Double
    
    static func == (lhs: Suggestion, rhs: Suggestion) -> Bool {
        return lhs.text == rhs.text
    }
}

/// Main prediction engine for the keyboard
@available(iOS 15.0, *)
class PredictionEngine {
    
    // MARK: - Properties
    
    /// Maximum number of suggestions to return
    private let maxSuggestions: Int
    
    /// Current language model
    private var currentModel: MLModel?
    
    /// Current language
    private var currentLanguage: KeyboardLanguage
    
    /// LRU cache for frequent predictions
    private let cache: LRUCache<String, [Suggestion]>
    
    /// User dictionary manager
    private let dictionaryManager: UserDictionaryManager
    
    /// Prediction timeout (milliseconds)
    private let predictionTimeout: TimeInterval = 0.05  // 50ms
    
    // MARK: - Initialization
    
    init(
        language: KeyboardLanguage = .english,
        maxSuggestions: Int = 30,
        cacheCapacity: Int = 100
    ) {
        self.currentLanguage = language
        self.maxSuggestions = maxSuggestions
        self.cache = LRUCache(capacity: cacheCapacity)
        self.dictionaryManager = UserDictionaryManager.shared
        
        // Load initial model
        loadModel(for: language)
    }
    
    // MARK: - Public Methods
    
    /// Get predictions for the given input
    /// - Parameters:
    ///   - input: User's current input text
    ///   - completion: Completion handler with suggestions
    func getPredictions(
        for input: String,
        completion: @escaping ([Suggestion]) -> Void
    ) {
        // Validate input
        guard !input.isEmpty else {
            completion([])
            return
        }
        
        // Check cache first
        if let cached = cache.get(input) {
            completion(cached)
            return
        }
        
        // Get predictions asynchronously
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            let predictions = self.predictSync(input: input)
            
            // Cache result
            self.cache.set(input, predictions)
            
            // Return on main thread
            DispatchQueue.main.async {
                completion(predictions)
            }
        }
    }
    
    /// Switch to a different language model
    func switchLanguage(to language: KeyboardLanguage) {
        guard language != currentLanguage else { return }
        
        currentLanguage = language
        cache.clear()  // Clear cache when switching languages
        loadModel(for: language)
    }
    
    /// Notify engine that user selected a suggestion
    func userDidSelect(_ suggestion: Suggestion, for input: String) {
        // Learn from user selection
        dictionaryManager.recordSelection(
            word: suggestion.text,
            input: input
        )
    }
    
    // MARK: - Private Methods
    
    /// Load model for specified language
    private func loadModel(for language: KeyboardLanguage) {
        ModelLoader.shared.loadModel(for: language) { [weak self] result in
            switch result {
            case .success(let model):
                self?.currentModel = model
                print("✅ Loaded \(language.rawValue) model")
            case .failure(let error):
                print("❌ Failed to load model: \(error.localizedDescription)")
            }
        }
    }
    
    /// Synchronous prediction (internal use)
    private func predictSync(input: String) -> [Suggestion] {
        guard let model = currentModel else {
            return []
        }
        
        // Get base predictions from model
        let basePredictions = getModelPredictions(input: input, model: model)
        
        // Apply dictionary boosting
        let boostedPredictions = applyDictionaryBoost(
            basePredictions,
            input: input
        )
        
        // Select top-K
        let topK = selectTopK(boostedPredictions, k: maxSuggestions)
        
        return topK
    }
    
    /// Get predictions from CoreML model
    private func getModelPredictions(
        input: String,
        model: MLModel
    ) -> [Suggestion] {
        // TODO: Implement actual CoreML prediction
        // This is a placeholder that returns mock data
        
        // For now, return some basic predictions
        // In production, this would:
        // 1. Tokenize input
        // 2. Run model inference
        // 3. Decode output tokens
        // 4. Return top predictions with scores
        
        return generateMockPredictions(for: input)
    }
    
    /// Generate mock predictions (placeholder)
    private func generateMockPredictions(for input: String) -> [Suggestion] {
        // This is temporary - replace with actual model predictions
        let mockSuffixes = ["", "ing", "ed", "s", "ly", "er", "est"]
        
        return mockSuffixes.map { suffix in
            Suggestion(
                text: input + suffix,
                score: Double.random(in: 0.5...1.0)
            )
        }
    }
    
    /// Apply user dictionary boosting to predictions
    private func applyDictionaryBoost(
        _ predictions: [Suggestion],
        input: String
    ) -> [Suggestion] {
        let dictionary = dictionaryManager.getCustomDictionary()
        
        var boosted = predictions.map { pred -> Suggestion in
            var suggestion = pred
            
            // Exact match in dictionary
            if let wordInfo = dictionary[pred.text] {
                // Frequency boost
                let frequencyBoost = log(Double(wordInfo.frequency + 1)) * 0.3
                
                // Recency boost
                let daysSinceUsed = Date().timeIntervalSince(wordInfo.lastUsed) / 86400
                let recencyBoost = max(0, 1.0 - daysSinceUsed / 30) * 0.2
                
                suggestion.score += frequencyBoost + recencyBoost
            }
            
            // Prefix match boost
            if pred.text.hasPrefix(input) {
                if dictionary.keys.contains(where: { $0.hasPrefix(input) }) {
                    suggestion.score += 0.1
                }
            }
            
            return suggestion
        }
        
        // Add dictionary words not in base predictions
        for (word, info) in dictionary {
            if word.hasPrefix(input) && !predictions.contains(where: { $0.text == word }) {
                let score = log(Double(info.frequency + 1)) * 0.5
                boosted.append(Suggestion(text: word, score: score))
            }
        }
        
        return boosted
    }
    
    /// Select top-K suggestions using min-heap
    private func selectTopK(_ predictions: [Suggestion], k: Int) -> [Suggestion] {
        guard predictions.count > k else {
            return predictions.sorted { $0.score > $1.score }
        }
        
        // Use min-heap for efficient top-K selection
        var heap = MinHeap<Suggestion>(maxSize: k) { $0.score < $1.score }
        
        for prediction in predictions {
            heap.insert(prediction)
        }
        
        // Extract and sort descending
        return heap.extractAll().sorted { $0.score > $1.score }
    }
}
