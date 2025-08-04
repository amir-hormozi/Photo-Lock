//
//  EncryptViewModel.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import Foundation
import Combine
import UniformTypeIdentifiers

class EncryptViewModel: ObservableObject {
    
    // MARK: Variable
    @Published var sourceFileURL: URL?
    @Published var publicKeyURL: URL?
    @Published var isEncrypting = false
    
    let showFileImporterAction = PassthroughSubject<[UTType], Never>()
    let showEncryptedFileSaverAction = PassthroughSubject<Data, Never>()
    let showAlertAction = PassthroughSubject<(title: String, message: String), Never>()

    private var currentPickerTarget: FilePickerTarget = .sourceFile
    private let encryptionManager = EncryptionManager()
        
    // MARK: Function
    func selectFileTapped(for target: FilePickerTarget) {
        self.currentPickerTarget = target
        let contentTypes: [UTType]
        if target == .publicKey {
            contentTypes = [UTType(filenameExtension: "pem") ?? .data]
        } else {
            contentTypes = [.data]
        }
        showFileImporterAction.send(contentTypes)
    }
    
    func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showAlertAction.send(("Access Denied", "Could not access the selected file."))
                return
            }
            if currentPickerTarget == .sourceFile {
                sourceFileURL = url
            } else {
                publicKeyURL = url
            }
        case .failure(let error):
            showAlertAction.send(("Error", "File selection failed: \(error.localizedDescription)"))
        }
    }
    
    func encryptFileTapped() {
        guard let sourceURL = sourceFileURL, let publicKeyURL = publicKeyURL else {
            showAlertAction.send(("Missing Files", "Please select both the source file and the public key."))
            return
        }
        
        isEncrypting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                sourceURL.stopAccessingSecurityScopedResource()
                publicKeyURL.stopAccessingSecurityScopedResource()
                DispatchQueue.main.async {
                    self.isEncrypting = false
                }
            }
            
            do {
                let sourceData = try Data(contentsOf: sourceURL)
                let pemString = try String(contentsOf: publicKeyURL)
                let rawPublicKeyData = try self.parsePEMPublicKey(pemString: pemString)
                
                guard let encryptedData = try self.encryptionManager.encrypt(data: sourceData, with: rawPublicKeyData) else {
                    throw NSError(domain: "Encryption", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encryption returned no data."])
                }
                
                // On success, directly trigger the file saver
                DispatchQueue.main.async {
                    self.showEncryptedFileSaverAction.send(encryptedData)
                }

            } catch {
                DispatchQueue.main.async {
                    self.showAlertAction.send(("Encryption Failed", error.localizedDescription))
                }
            }
        }
    }
        
    private func parsePEMPublicKey(pemString: String) throws -> Data {
        let lines = pemString.components(separatedBy: .newlines)
        let base64String = lines.filter { !$0.hasPrefix("-----") }.joined()
        
        guard let data = Data(base64Encoded: base64String) else {
            throw NSError(domain: "Parsing", code: -1, userInfo: [NSLocalizedDescriptionKey: "PEM Base64 decoding failed."])
        }
        return data
    }
}
