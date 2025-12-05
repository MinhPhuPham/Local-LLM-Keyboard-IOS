//
//  LanguageDetector.swift
//  LLM Local Keyboard
//
//  Detects language from user input to switch models dynamically
//  iOS 15+ compatible
//

import Foundation

/// Language detector for automatic model switching
@available(iOS 15.0, *)
class LanguageDetector {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = LanguageDetector()
    
    /// Japanese character ranges
    private let hiraganaRange: ClosedRange<UInt32> = 0x3040...0x309F
    private let katakanaRange: ClosedRange<UInt32> = 0x30A0...0x30FF
    private let kanjiRange: ClosedRange<UInt32> = 0x4E00...0x9FFF
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Detect language from text
    /// - Parameter text: Input text to analyze
    /// - Returns: Detected language
    func detectLanguage(from text: String) -> KeyboardLanguage {
        guard !text.isEmpty else {
            return .english  // Default to English
        }
        
        // Check for Japanese characters
        if containsJapanese(text) {
            return .japanese
        }
        
        return .english
    }
    
    /// Check if text contains Japanese characters
    /// - Parameter text: Text to check
    /// - Returns: True if contains Japanese characters
    func containsJapanese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let value = scalar.value
            
            if hiraganaRange.contains(value) ||
               katakanaRange.contains(value) ||
               kanjiRange.contains(value) {
                return true
            }
        }
        
        return false
    }
    
    /// Get language distribution in text
    /// - Parameter text: Text to analyze
    /// - Returns: Dictionary with character counts per language
    func getLanguageDistribution(from text: String) -> [String: Int] {
        var japanese = 0
        var english = 0
        var other = 0
        
        for scalar in text.unicodeScalars {
            let value = scalar.value
            
            if hiraganaRange.contains(value) ||
               katakanaRange.contains(value) ||
               kanjiRange.contains(value) {
                japanese += 1
            } else if (0x0041...0x005A).contains(value) ||  // A-Z
                      (0x0061...0x007A).contains(value) {   // a-z
                english += 1
            } else {
                other += 1
            }
        }
        
        return [
            "japanese": japanese,
            "english": english,
            "other": other
        ]
    }
    
    /// Determine if language switch is needed
    /// - Parameters:
    ///   - currentLanguage: Currently active language
    ///   - text: Current input text
    /// - Returns: True if language should be switched
    func shouldSwitchLanguage(
        from currentLanguage: KeyboardLanguage,
        basedOn text: String
    ) -> Bool {
        let detectedLanguage = detectLanguage(from: text)
        return detectedLanguage != currentLanguage
    }
}
