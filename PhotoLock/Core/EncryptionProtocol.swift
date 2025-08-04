//
//  EncryptionProtocol.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation

protocol EncryptionProtocol {
    mutating func generateKeyPair() throws
    func encrypt(data: Data, with publicKey: Data) throws -> Data?
    mutating func decrypt(data: Data) throws -> Data
    func savePublicKeyToFile(data: Data) throws
}
