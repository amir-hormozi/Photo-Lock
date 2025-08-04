//
//  EncryptVC.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//


import UIKit
import Combine
import UniformTypeIdentifiers

fileprivate struct LocalConstants {
    static let VCTitle: String = "Encrypt File"
    
    static let sourceFileSVIdn: String = "sourceFile"
    static let publicKeySVIdn: String = "publicKey"
    
    static let sourceFileSVTitle: String = "1. Select File to Encrypt"
    static let publicKeySVTitle: String = "2. Select Recipient's Public Key"
    
    static let sourceFileSVImage: String = "doc.badge.plus"
    static let publicKeySVImage: String = "key.fill"
    
    static let encryptButtonTitle: String = "Encrypt & Save File"
    static let encryptButtonImage: String = "lock.fill"
    
    static let stackViewSpacing: CGFloat = 30
    
    
}
class EncryptVC: UIViewController, UIDocumentPickerDelegate, UIFileSelectionViewDelegate {

    // MARK: Variable
    private let viewModel = EncryptViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components
    lazy var scrollView: UIScrollView = {
       let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = LocalConstants.stackViewSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var sourceFileSelectionView: UIFileSelectionView = {
        let view = UIFileSelectionView()
        view.delegate = self
        view.identifier = LocalConstants.sourceFileSVIdn
        view.configure(
            title: LocalConstants.sourceFileSVTitle,
            systemImage: LocalConstants.sourceFileSVImage
        )
        return view
    }()
    
    private lazy var publicKeySelectionView: UIFileSelectionView = {
        let view = UIFileSelectionView()
        view.delegate = self
        view.identifier = LocalConstants.publicKeySVIdn
        view.configure(
            title: LocalConstants.publicKeySVTitle,
            systemImage: LocalConstants.publicKeySVImage
        )
        return view
    }()

    private let encryptButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = LocalConstants.encryptButtonTitle
        config.image = UIImage(systemName: LocalConstants.encryptButtonImage)
        config.imagePadding = 8
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(encryptButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    // MARK: Function
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = LocalConstants.VCTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        stackView.addArrangedSubview(sourceFileSelectionView)
        stackView.addArrangedSubview(publicKeySelectionView)
        let spacer = UIView()
        stackView.addArrangedSubview(spacer)

        view.addSubview(encryptButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: encryptButton.topAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            
            encryptButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            encryptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            encryptButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            encryptButton.heightAnchor.constraint(equalToConstant: 50),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.showFileImporterAction
            .sink { [weak self] contentTypes in
                self?.presentFileImporter(allowedContentTypes: contentTypes)
            }
            .store(in: &cancellables)
            
        viewModel.showEncryptedFileSaverAction
            .sink { [weak self] data in
                self?.presentFileSaver(dataToSave: data)
            }
            .store(in: &cancellables)

        viewModel.showAlertAction
            .sink { [weak self] (title, message) in
                self?.presentAlert(title: title, message: message)
            }
            .store(in: &cancellables)
            
        viewModel.$isEncrypting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEncrypting in
                self?.encryptButton.isHidden = isEncrypting
                if isEncrypting { self?.activityIndicator.startAnimating() }
                else { self?.activityIndicator.stopAnimating() }
            }
            .store(in: &cancellables)
        
        viewModel.$sourceFileURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.sourceFileSelectionView.setSelectedFileName(url?.lastPathComponent)
            }
            .store(in: &cancellables)
            
        viewModel.$publicKeyURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.publicKeySelectionView.setSelectedFileName(url?.lastPathComponent)
            }
            .store(in: &cancellables)
            
        Publishers.CombineLatest(viewModel.$sourceFileURL, viewModel.$publicKeyURL)
            .map { $0 != nil && $1 != nil }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isEnabled, on: encryptButton)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func encryptButtonTapped() {
        viewModel.encryptFileTapped()
    }
    
    // MARK: - Document Picker Logic
    private func presentFileImporter(allowedContentTypes: [UTType]) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentFileSaver(dataToSave: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("encrypted_file.pkg")
        do {
            try dataToSave.write(to: tempURL)
            let picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
            picker.delegate = self
            present(picker, animated: true)
        } catch {
            presentAlert(title: "Error", message: "Could not save temporary file: \(error.localizedDescription)")
        }
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        viewModel.handleFileImport(result: .success(url))
    }
    
    func didTapFileSelectionView(identifier: AnyHashable?) {
        
        switch identifier as? String {
        case "sourceFile":
            viewModel.selectFileTapped(for: .sourceFile)
        case "publicKey":
            viewModel.selectFileTapped(for: .publicKey)
        default:
            break
        }
    }

}
