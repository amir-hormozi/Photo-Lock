//
//  KeyStorage.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation

protocol KeyStorage {
    func savePublicKeyToFile(data: Data) throws
}

extension KeyStorage {
    func getPublicKeyLink() throws -> URL {
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            throw EncryptionError.fileWriteFailed("Could not find document directory.")
        }
        return documentDirectory
    }
    
    func savePublicKeyToFile(data: Data) throws {
        let base64 = data.base64EncodedString(options: .lineLength64Characters)
        let pemString = """
        -----BEGIN PUBLIC KEY-----
        \(base64)
        -----END PUBLIC KEY-----
        """
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            throw EncryptionError.fileWriteFailed("Could not find document directory.")
        }
        
        let fileURL = documentDirectory.appendingPathComponent("public_key.pem")
        do {
            try pemString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw EncryptionError.fileWriteFailed(error.localizedDescription)
        }
    }
    
    func saveEncryptedData(data: Data, toFile fileName: String) throws {
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw EncryptionError.fileWriteFailed("Could not find document directory.")
        }
        
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print(fileURL.path)
        } catch {
            throw EncryptionError.fileWriteFailed(error.localizedDescription)
        }
    }
}
