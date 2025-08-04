# FileLock: Secure File Encryption for iOS

FileLock is a sample iOS application that demonstrates how to securely encrypt and decrypt files using a hybrid encryption scheme powered by the device's **Secure Enclave** and **CryptoKit**. It provides a clear, end-to-end example of modern cryptographic practices on iOS.

## ✨ Key Features

This project highlights several key capabilities and modern development practices:

* **Secure Enclave Integration**
    * Generates and securely stores a P-256 private key directly within the device's Secure Enclave hardware.
    * Key access is restricted to when the device is unlocked (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
    * Ensures the private key material never leaves the secure hardware, providing a strong defense against extraction.

* **Hybrid Encryption Scheme (ECIES)**
    * Encrypts file data using the fast and secure **AES-256-GCM** symmetric cipher.
    * The symmetric AES key is then securely wrapped (encrypted) using the recipient's public key with the **ECIES** standard (`eciesEncryptionCofactorX963SHA256AESGCM`).
    * This approach combines the performance of symmetric encryption for large data with the security of asymmetric (public-key) cryptography for key exchange.

* **Modern & Reactive Architecture**
    * Built with a clean **MVVM (Model-View-ViewModel)** architecture for a clear separation of concerns.
    * Leverages Apple's **Combine** framework for a declarative and reactive approach to handling UI updates, user actions, and asynchronous events.
    * UI state (e.g., loading indicators, button enabled states) is automatically managed based on data streams from the ViewModels.

* **Robust and Asynchronous by Design**
    * All intensive cryptographic operations are performed on a background `DispatchQueue` to ensure the UI remains smooth and responsive at all times.
    * Features a comprehensive `EncryptionError` enum with descriptive cases for robust error handling and debugging.

* **Seamless File Management**
    * Integrates `UIDocumentPickerViewController` for a native experience when importing files for encryption and exporting the results.
    * Properly handles security-scoped resource access for files selected from outside the app's sandbox.
    * Supports encryption of any file type and accepts public keys in the standard PEM format.

## ⚙️ How It Works

The cryptographic workflow is divided into three main stages:

#### 1. Key Pair Generation
1.  A new P-256 key pair is generated using `SecKeyCreateRandomKey`.
2.  The attributes specify that the private key must be permanent and stored in the Secure Enclave (`kSecAttrTokenIDSecureEnclave`).
3.  The public key is extracted using `SecKeyCopyPublicKey`.
4.  The public key is then encoded into a standard PEM format and saved to the app's Documents directory as `public_key.pem`.

#### 2. Encryption Flow
1.  The user selects a source file and the recipient's public PEM key.
2.  A new, single-use 256-bit symmetric key (`SymmetricKey`) is generated for AES-GCM encryption.
3.  The source file data is encrypted (sealed) using `AES.GCM.seal()` with the generated symmetric key.
4.  The symmetric key itself is then encrypted using the recipient's public key via `SecKeyCreateEncryptedData` with the ECIES algorithm.
5.  A final data package is assembled by concatenating four chunks, each prefixed with its length:
    * The encrypted AES key.
    * The `nonce` used for AES encryption.
    * The `ciphertext` (the encrypted file content).
    * The AES authentication `tag`.

#### 3. Decryption Flow
1.  The user selects the encrypted file package.
2.  The app retrieves the user's private key from the Secure Enclave by querying for its unique tag.
3.  The encrypted package is parsed into its four components (encrypted AES key, nonce, ciphertext, tag).
4.  `SecKeyCreateDecryptedData` is called with the private key to decrypt the AES key. This operation happens entirely within the Secure Enclave.
5.  Finally, `AES.GCM.open()` is used with the now-decrypted AES key and the other components to securely decrypt the original file data.

## 🛠️ Tech Stack

* **Language:** Swift
* **UI:** UIKit (Programmatic, AutoLayout)
* **Architecture:** MVVM
* **Frameworks:**
    * Combine
    * CryptoKit
    * Security

## 🚀 Usage

1.  Clone the repository.
2.  Open the project in Xcode and run it on a physical iOS device (Secure Enclave is not available in the simulator).
3.  **Generate Keys:** Navigate to the "Keys" tab and generate a new key pair. Use the Files app to locate and share your `public_key.pem` from the app's document directory.
4.  **Encrypt:** Go to the "Encrypt" tab. Select a source file and the recipient's public key. Save the encrypted output.
5.  **Decrypt:** Go to the "Decrypt" tab. Select an encrypted file that was encrypted for your public key. Save the decrypted output.

## 👨‍💻 Author

Amir Hormozi
