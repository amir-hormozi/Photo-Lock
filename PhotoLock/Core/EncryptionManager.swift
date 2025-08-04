//
//  EncryptionManager.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation
import Security
import CryptoKit

final class EncryptionManager: EncryptionProtocol, KeyStorage {    
    private let keyTag = "com.behtis.photoLock"
    private let privateKey: SecureEnclave.P256.KeyAgreement.PrivateKey?

    init() {
        self.privateKey = try? SecureEnclave.P256.KeyAgreement.PrivateKey()
    }

    func generateKeyPair() throws {
        guard let keyTagData = keyTag.data(using: .utf8) else {
            throw EncryptionError.convertTagKeyToDataFailed
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTagData,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let publicKeyPath = try getPublicKeyLink().appendingPathComponent("public_key.pem")
        try? FileManager.default.removeItem(at: publicKeyPath)

        // Access Control
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            nil
        ) else {
            throw EncryptionError.createAccessControlFailed
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: keyTagData,
                kSecAttrAccessControl as String: access
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw EncryptionError.keyCreationFailed(error?.takeRetainedValue().localizedDescription ?? "Unknown")
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw EncryptionError.publicKeyExtractionFailed
        }

        do {
            try savePublicKeyToFile(data: publicKeyData)
        } catch {
            throw EncryptionError.fileWriteFailed(error.localizedDescription)
        }
    }

    func encrypt(data: Data, with publicKey: Data) throws -> Data? {
        let aesKey = SymmetricKey(size: .bits256)

        guard let nonce = try? AES.GCM.Nonce() else {
            throw EncryptionError.generateNonceFailed
        }

        guard let sealedBox = try? AES.GCM.seal(data, using: aesKey, nonce: nonce) else {
            throw EncryptionError.encryptionFailed("AES-GCM seal failed")
        }

        // Create public key from data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(publicKey as CFData, attributes as CFDictionary, &error) else {
            throw EncryptionError.invalidPublicKey(error?.takeRetainedValue().localizedDescription ?? "Invalid format")
        }

        guard let encryptedAESKey = SecKeyCreateEncryptedData(
            publicKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            aesKey.withUnsafeBytes { Data($0) } as CFData,
            &error
        ) as Data? else {
            throw EncryptionError.encryptionFailed(error?.takeRetainedValue().localizedDescription ?? "AES key encryption failed")
        }

        var bundle = Data()

        func append(_ chunk: Data) {
            var len = UInt32(chunk.count).bigEndian
            bundle.append(Data(bytes: &len, count: 4))
            bundle.append(chunk)
        }

        append(encryptedAESKey)
        append(nonce.withUnsafeBytes { Data($0) })
        append(sealedBox.ciphertext)
        append(sealedBox.tag)

        return bundle
    }

    func decrypt(data: Data) throws -> Data {
        guard let keyTagData = keyTag.data(using: .utf8) else {
            throw EncryptionError.convertTagKeyToDataFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTagData,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let privateKey = item else {
            throw EncryptionError.keyNotFound(String(status))
        }

        var offset = 0
        func readChunk() throws -> Data {
            guard data.count >= offset + 4 else {
                throw EncryptionError.invalidFileFormat("Missing length header")
            }
            let length = Int(UInt32(bigEndian: data[offset..<offset+4].withUnsafeBytes { $0.load(as: UInt32.self) }))
            offset += 4
            guard data.count >= offset + length else {
                throw EncryptionError.invalidFileFormat("Chunk length mismatch")
            }
            let chunk = data[offset..<offset + length]
            offset += length
            return chunk
        }

        let encryptedAESKey = try readChunk()
        let nonceData       = try readChunk()
        let ciphertext      = try readChunk()
        let tag             = try readChunk()

        var error: Unmanaged<CFError>?
        guard let aesKeyData = SecKeyCreateDecryptedData(
            privateKey as! SecKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            encryptedAESKey as CFData,
            &error
        ) as Data? else {
            throw EncryptionError.decryptionFailed(error?.takeRetainedValue().localizedDescription ?? "Unable to decrypt AES key")
        }

        let aesKey = SymmetricKey(data: aesKeyData)

        do {
            let box = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonceData),
                ciphertext: ciphertext,
                tag: tag
            )
            return try AES.GCM.open(box, using: aesKey)
        } catch {
            throw EncryptionError.decryptionFailed(error.localizedDescription)
        }
    }
}
