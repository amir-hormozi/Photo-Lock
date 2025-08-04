//
//  EncryptionError.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation

enum EncryptionError: LocalizedError {
    case decryptionFailed(String)
    case fileWriteFailed(String)
    case removePublicKeyFailed(String)
    case convertTagKeyToDataFailed
    case createAccessControlFailed
    case generateNonceFailed
    case invalidPublicKey(String)
    case encryptionFailed(String)
    case keyCreationFailed(String)
    case publicKeyExtractionFailed
    case keyNotFound(String)
    case invalidFileFormat(String)

    var errorDescription: String? {
        switch self {
        case .decryptionFailed(let error):
            return "❌ Decryption failed: \(error)"
        case .fileWriteFailed(let error):
            return "❌ File write error: \(error)"
        case .removePublicKeyFailed(let error):
            return "❌ Could not remove public key: \(error)"
        case .convertTagKeyToDataFailed:
            return "❌ Failed to convert keyTag to Data"
        case .createAccessControlFailed:
            return "❌ Failed to create access control object"
        case .generateNonceFailed:
            return "❌ Failed to generate nonce"
        case .invalidPublicKey(let error):
            return "❌ Invalid public key: \(error)"
        case .encryptionFailed(let error):
            return "❌ Encryption error: \(error)"
        case .keyCreationFailed(let error):
            return "❌ Key creation failed: \(error)"
        case .publicKeyExtractionFailed:
            return "❌ Failed to extract public key"
        case .keyNotFound(let status):
            return "❌ Private key not found: OSStatus(\(status))"
        case .invalidFileFormat(let reason):
            return "❌ Invalid file format: \(reason)"
        }
    }
}
