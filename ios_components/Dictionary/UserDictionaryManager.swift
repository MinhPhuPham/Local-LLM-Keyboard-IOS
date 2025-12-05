//
//  UserDictionaryManager.swift
//  LLM Local Keyboard
//
//  Manages user dictionary with frequency tracking and learning
//  Supports iOS 15+ with App Group sharing
//

import Foundation

/// Word information stored in user dictionary
struct WordInfo: Codable {
    let word: String
    let reading: String?
    var frequency: Int
    var lastUsed: Date
    let source: DictionarySource
    
    enum DictionarySource: String, Codable {
        case userAdded
        case learned
        case imported
    }
}

/// Manages user dictionary for personalized predictions
@available(iOS 15.0, *)
class UserDictionaryManager {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = UserDictionaryManager()
    
    /// App Group identifier for sharing between app and keyboard extension
    private let appGroupIdentifier = "group.com.keyboard.llm"
    
    /// Dictionary file name
    private let dictionaryFileName = "custom_dictionary.json"
    
    /// In-memory dictionary cache
    private var dictionaryCache: [String: WordInfo]?
    
    /// Queue for thread-safe dictionary access
    private let dictionaryQueue = DispatchQueue(
        label: "com.keyboard.dictionary",
        attributes: .concurrent
    )
    
    // MARK: - Initialization
    
    private init() {
        // Load dictionary into cache
        loadDictionary()
    }
    
    // MARK: - Public Methods
    
    /// Get the custom dictionary
    func getCustomDictionary() -> [String: WordInfo] {
        return dictionaryQueue.sync {
            if let cache = dictionaryCache {
                return cache
            }
            
            // Load if not cached
            loadDictionary()
            return dictionaryCache ?? [:]
        }
    }
    
    /// Add a word to the custom dictionary
    func addWord(
        _ word: String,
        reading: String? = nil,
        source: WordInfo.DictionarySource = .userAdded
    ) {
        dictionaryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var dict = self.getCustomDictionary()
            
            if dict[word] != nil {
                // Word already exists, increment frequency
                dict[word]?.frequency += 1
                dict[word]?.lastUsed = Date()
            } else {
                // Add new word
                dict[word] = WordInfo(
                    word: word,
                    reading: reading,
                    frequency: 1,
                    lastUsed: Date(),
                    source: source
                )
            }
            
            self.dictionaryCache = dict
            self.saveDictionary(dict)
        }
    }
    
    /// Record a user selection (for learning)
    func recordSelection(word: String, input: String) {
        dictionaryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var dict = self.getCustomDictionary()
            
            if var wordInfo = dict[word] {
                // Update existing word
                wordInfo.frequency += 1
                wordInfo.lastUsed = Date()
                dict[word] = wordInfo
            } else {
                // Learn new word
                dict[word] = WordInfo(
                    word: word,
                    reading: nil,
                    frequency: 1,
                    lastUsed: Date(),
                    source: .learned
                )
            }
            
            self.dictionaryCache = dict
            self.saveDictionary(dict)
        }
    }
    
    /// Remove a word from the dictionary
    func removeWord(_ word: String) {
        dictionaryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var dict = self.getCustomDictionary()
            dict.removeValue(forKey: word)
            
            self.dictionaryCache = dict
            self.saveDictionary(dict)
        }
    }
    
    /// Clear the entire dictionary
    func clearDictionary() {
        dictionaryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.dictionaryCache = [:]
            self.saveDictionary([:])
        }
    }
    
    /// Import dictionary from external source
    func importDictionary(_ words: [String: WordInfo]) {
        dictionaryQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var dict = self.getCustomDictionary()
            
            // Merge imported words
            for (word, info) in words {
                dict[word] = info
            }
            
            self.dictionaryCache = dict
            self.saveDictionary(dict)
        }
    }
    
    /// Export dictionary to external format (CSV)
    func exportToCSV() -> String {
        let dict = getCustomDictionary()
        
        var csv = "word,reading,frequency,lastUsed,source\n"
        
        for (_, info) in dict.sorted(by: { $0.value.frequency > $1.value.frequency }) {
            let reading = info.reading ?? ""
            let dateFormatter = ISO8601DateFormatter()
            let lastUsed = dateFormatter.string(from: info.lastUsed)
            
            csv += "\(info.word),\(reading),\(info.frequency),\(lastUsed),\(info.source.rawValue)\n"
        }
        
        return csv
    }
    
    // MARK: - Private Methods
    
    /// Get the dictionary file URL
    private func getDictionaryURL() -> URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            print("⚠️ App Group container not found")
            return nil
        }
        
        return containerURL.appendingPathComponent(dictionaryFileName)
    }
    
    /// Load dictionary from disk
    private func loadDictionary() {
        guard let url = getDictionaryURL() else {
            dictionaryCache = [:]
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dict = try decoder.decode([String: WordInfo].self, from: data)
            dictionaryCache = dict
        } catch {
            // File doesn't exist or is corrupted, start fresh
            dictionaryCache = [:]
        }
    }
    
    /// Save dictionary to disk
    private func saveDictionary(_ dictionary: [String: WordInfo]) {
        guard let url = getDictionaryURL() else {
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(dictionary)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to save dictionary: \(error)")
        }
    }
    
    /// Get dictionary statistics
    func getStatistics() -> [String: Any] {
        let dict = getCustomDictionary()
        
        let totalWords = dict.count
        let totalFrequency = dict.values.reduce(0) { $0 + $1.frequency }
        let avgFrequency = totalWords > 0 ? Double(totalFrequency) / Double(totalWords) : 0
        
        let sourceBreakdown = dict.values.reduce(into: [:]) { counts, info in
            counts[info.source.rawValue, default: 0] += 1
        }
        
        return [
            "totalWords": totalWords,
            "totalUsage": totalFrequency,
            "averageFrequency": avgFrequency,
            "sourceBreakdown": sourceBreakdown
        ]
    }
}
