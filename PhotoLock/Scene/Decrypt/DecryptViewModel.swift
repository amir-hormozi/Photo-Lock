//
//  DecryptViewModel.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation
import Combine

/// ViewModel for managing file decryption logic, designed for UIKit.
class DecryptViewModel: ObservableObject {
    
    // MARK: - State Properties
    @Published var encryptedFileURL: URL?
    @Published var decryptedData: Data?
    @Published var isDecrypting = false
    
    // MARK: - Action Subjects
    let showFileImporterAction = PassthroughSubject<Void, Never>()
    let showDecryptedFileSaverAction = PassthroughSubject<Data, Never>()
    let showAlertAction = PassthroughSubject<(title: String, message: String), Never>()

    // Your existing EncryptionManager would go here
    private let encryptionManager = EncryptionManager()

    // MARK: - Intentions (Methods called by the View)
    
    /// Tells the ViewController to present the file importer.
    func selectFileTapped() {
        showFileImporterAction.send()
    }
    
    /// Handles the result from the document picker.
    func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showAlertAction.send(("Access Denied", "Could not access the selected file."))
                return
            }
            encryptedFileURL = url
            
        case .failure(let error):
            showAlertAction.send(("Error", "Failed to select file: \(error.localizedDescription)"))
        }
    }
    
    /// Decrypts the selected file.
    func decryptFileTapped() {
        guard let encryptedFileURL = encryptedFileURL else {
            showAlertAction.send(("No File", "Please select an encrypted file first."))
            return
        }
        
        isDecrypting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                encryptedFileURL.stopAccessingSecurityScopedResource()
                DispatchQueue.main.async {
                    self.isDecrypting = false
                }
            }

            do {
                let encryptedData = try Data(contentsOf: encryptedFileURL)
                let decryptedData = try self.encryptionManager.decrypt(data: encryptedData)
                DispatchQueue.main.async {
                    self.decryptedData = decryptedData
                    self.showDecryptedFileSaverAction.send(decryptedData)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.showAlertAction.send(("Decryption Failed", error.localizedDescription))
                }
            }
        }
    }
}
