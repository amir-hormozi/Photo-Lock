//
//  KeyGenerateViewModel.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation
import Combine

class KeyGenerateViewModel: ObservableObject {
    
    // MARK: - Variable
    let showAlertAction = PassthroughSubject<(title: String, message: String), Never>()
    private var encryptionManager: EncryptionProtocol = EncryptionManager()
    
    // MARK: Function
    func generateNewKeysTapped() {
        do {
            try encryptionManager.generateKeyPair()
            let successMessage = "New key pair generated and saved to Documents/public_key.pem!"
            showAlertAction.send(("Success", successMessage))
        } catch {
            let errorMessage = "Failed to generate key pair: \(error.localizedDescription)"
            showAlertAction.send(("Error", errorMessage))
        }
    }
}
