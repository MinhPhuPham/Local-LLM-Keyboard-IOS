//
//  ModelLoader.swift
//  LLM Local Keyboard
//
//  Handles loading, decryption, and initialization of compressed language models
//  Supports iOS 15+
//

import Foundation
import CoreML

/// Errors that can occur during model loading
enum ModelLoadError: Error {
    case modelNotFound
    case decryptionFailed
    case decompressionFailed
    case coreMLLoadFailed
    case unsupportedLanguage
    
    var localizedDescription: String {
        switch self {
        case .modelNotFound:
            return "Model file not found"
        case .decryptionFailed:
            return "Failed to decrypt model"
        case .decompressionFailed:
            return "Failed to decompress model"
        case .coreMLLoadFailed:
            return "Failed to load CoreML model"
        case .unsupportedLanguage:
            return "Unsupported language"
        }
    }
}

/// Language options for the keyboard
enum KeyboardLanguage: String {
    case english = "english"
    case japanese = "japanese"
}

/// Manages loading and caching of language models
@available(iOS 15.0, *)
class ModelLoader {
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = ModelLoader()
    
    /// Currently loaded models (cached)
    private var loadedModels: [KeyboardLanguage: MLModel] = [:]
    
    /// Model loading queue (background)
    private let loadingQueue = DispatchQueue(
        label: "com.keyboard.modelloader",
        qos: .userInitiated
    )
    
    /// Model configuration
    private let modelConfig: MLModelConfiguration = {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine  // Use Neural Engine when available
        config.allowLowPrecisionAccumulationOnGPU = true  // Better performance
        return config
    }()
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton
        setupMemoryWarningObserver()
    }
    
    // MARK: - Public Methods
    
    /// Load a model for the specified language
    /// - Parameters:
    ///   - language: Language to load
    ///   - completion: Completion handler with result
    func loadModel(
        for language: KeyboardLanguage,
        completion: @escaping (Result<MLModel, ModelLoadError>) -> Void
    ) {
        // Check if already loaded
        if let cachedModel = loadedModels[language] {
            completion(.success(cachedModel))
            return
        }
        
        // Load asynchronously
        loadingQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                let model = try self.loadModelSync(for: language)
                
                // Cache the model
                DispatchQueue.main.async {
                    self.loadedModels[language] = model
                    completion(.success(model))
                }
            } catch let error as ModelLoadError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.coreMLLoadFailed))
                }
            }
        }
    }
    
    /// Synchronously load a model (internal use)
    private func loadModelSync(for language: KeyboardLanguage) throws -> MLModel {
        // Get model URL
        guard let modelURL = getModelURL(for: language) else {
            throw ModelLoadError.modelNotFound
        }
        
        // Check if model is encrypted
        let isEncrypted = modelURL.pathExtension == "encrypted"
        
        var finalURL = modelURL
        
        if isEncrypted {
            // Decrypt model
            guard let decryptedData = try? decryptModel(at: modelURL) else {
                throw ModelLoadError.decryptionFailed
            }
            
            // Save to temporary location
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(language.rawValue)_temp.mlmodelc")
            
            try? decryptedData.write(to: tempURL)
            finalURL = tempURL
        }
        
        // Load CoreML model
        do {
            let model = try MLModel(contentsOf: finalURL, configuration: modelConfig)
            return model
        } catch {
            print("CoreML load error: \(error)")
            throw ModelLoadError.coreMLLoadFailed
        }
    }
    
    /// Unload a specific model to free memory
    func unloadModel(for language: KeyboardLanguage) {
        loadedModels.removeValue(forKey: language)
    }
    
    /// Unload all models
    func unloadAllModels() {
        loadedModels.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Get the URL for a model file
    private func getModelURL(for language: KeyboardLanguage) -> URL? {
        // Try to find in main bundle
        let modelName = "\(language.rawValue)_model"
        
        // Check for encrypted version first
        if let url = Bundle.main.url(
            forResource: modelName,
            withExtension: "mlmodelc.encrypted"
        ) {
            return url
        }
        
        // Check for unencrypted version
        if let url = Bundle.main.url(
            forResource: modelName,
            withExtension: "mlmodelc"
        ) {
            return url
        }
        
        return nil
    }
    
    /// Decrypt an encrypted model file
    private func decryptModel(at url: URL) throws -> Data {
        // Load encrypted data
        let encryptedData = try Data(contentsOf: url)
        
        // Decrypt using ModelEncryption
        let decryptedData = try ModelEncryption.decrypt(encryptedData)
        
        return decryptedData
    }
    
    /// Setup memory warning observer
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// Handle memory warnings by unloading models
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning - unloading models")
        unloadAllModels()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Model Encryption

/// Handles model encryption and decryption
struct ModelEncryption {
    
    /// Obfuscated encryption key (XOR with app-specific values)
    /// WARNING: This is a basic implementation. For production, use more secure key storage
    private static let keyMaterial: [UInt8] = [
        0x1A ^ 0x42, 0x2B ^ 0x13, 0x3C ^ 0x24, 0x4D ^ 0x35,
        0x5E ^ 0x46, 0x6F ^ 0x57, 0x70 ^ 0x68, 0x81 ^ 0x79,
        0x92 ^ 0x8A, 0xA3 ^ 0x9B, 0xB4 ^ 0xAC, 0xC5 ^ 0xBD,
        0xD6 ^ 0xCE, 0xE7 ^ 0xDF, 0xF8 ^ 0xE0, 0x09 ^ 0xF1,
        0x1A ^ 0x02, 0x2B ^ 0x13, 0x3C ^ 0x24, 0x4D ^ 0x35,
        0x5E ^ 0x46, 0x6F ^ 0x57, 0x70 ^ 0x68, 0x81 ^ 0x79,
        0x92 ^ 0x8A, 0xA3 ^ 0x9B, 0xB4 ^ 0xAC, 0xC5 ^ 0xBD,
        0xD6 ^ 0xCE, 0xE7 ^ 0xDF, 0xF8 ^ 0xE0, 0x09 ^ 0xF1,
    ]
    
    /// Decrypt encrypted model data
    static func decrypt(_ encryptedData: Data) throws -> Data {
        // For iOS 15+, use CryptoKit
        if #available(iOS 15.0, *) {
            return try decryptWithCryptoKit(encryptedData)
        } else {
            throw ModelLoadError.decryptionFailed
        }
    }
    
    /// Decrypt using CryptoKit (iOS 15+)
    @available(iOS 15.0, *)
    private static func decryptWithCryptoKit(_ encryptedData: Data) throws -> Data {
        import CryptoKit
        
        // Create symmetric key from key material
        let keyData = Data(keyMaterial)
        let key = SymmetricKey(data: keyData)
        
        // Decrypt using AES-GCM
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    /// Encrypt model data (for build-time encryption)
    @available(iOS 15.0, *)
    static func encrypt(_ data: Data) throws -> Data {
        import CryptoKit
        
        let keyData = Data(keyMaterial)
        let key = SymmetricKey(data: keyData)
        
        // Generate random nonce
        let nonce = AES.GCM.Nonce()
        
        // Encrypt using AES-GCM
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        return sealedBox.combined!
    }
}
