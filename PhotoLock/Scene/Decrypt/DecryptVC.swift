//
//  DecryptVC.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import UIKit
import Combine
import UniformTypeIdentifiers

// MARK: - DecryptViewController
class DecryptVC: UIViewController, UIDocumentPickerDelegate {

    // MARK: Properties
    private let viewModel = DecryptViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: UI Components
    private let scrollView = UIScrollView()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var fileSelectionView: FileSelectionUIView = {
        let view = FileSelectionUIView()
        view.configure(
            title: "Select Encrypted File",
            systemImage: "doc.badge.arrow.up"
        )
        view.onTap = { [weak self] in
            self?.viewModel.selectFileTapped()
        }
        return view
    }()

    private let decryptButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Decrypt & Save File"
        config.image = UIImage(systemName: "lock.open.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Decrypt File"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        decryptButton.addTarget(self, action: #selector(decryptButtonTapped), for: .touchUpInside)

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        stackView.addArrangedSubview(fileSelectionView)
        let spacer = UIView() // فضای خالی برای قرار دادن دکمه در پایین
        stackView.addArrangedSubview(spacer)

        view.addSubview(decryptButton)
        view.addSubview(activityIndicator)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: decryptButton.topAnchor, constant: -20),

            // StackView constraints
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            
            // Decrypt Button constraints
            decryptButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            decryptButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            decryptButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            decryptButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activity Indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - View Model Bindings
    private func setupBindings() {
        viewModel.showFileImporterAction
            .sink { [weak self] in
                self?.presentFileImporter()
            }
            .store(in: &cancellables)
            
        viewModel.showDecryptedFileSaverAction
            .sink { [weak self] data in
                self?.presentFileSaver(dataToSave: data)
            }
            .store(in: &cancellables)

        viewModel.showAlertAction
            .sink { [weak self] (title, message) in
                self?.presentAlert(title: title, message: message)
            }
            .store(in: &cancellables)
            
        viewModel.$isDecrypting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDecrypting in
                self?.decryptButton.isHidden = isDecrypting
                if isDecrypting {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$encryptedFileURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.decryptButton.isEnabled = url != nil
                self?.fileSelectionView.setSelectedFileName(url?.lastPathComponent)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func decryptButtonTapped() {
        viewModel.decryptFileTapped()
    }
    
    // MARK: - Document Picker Logic
    private func presentFileImporter() {
        let supportedTypes: [UTType] = [.data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentFileSaver(dataToSave: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("decrypted_file.jpg")
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

    // MARK: UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        viewModel.handleFileImport(result: .success(url))
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled the picker
    }
}


// MARK: - FileSelectionUIView (Custom View)
class FileSelectionUIView: UIView {
    
    var onTap: (() -> Void)?
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let fileNameLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12
        
        iconImageView.tintColor = .label
        iconImageView.contentMode = .scaleAspectFit
        
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        
        fileNameLabel.font = .preferredFont(forTextStyle: .subheadline)
        fileNameLabel.textColor = .secondaryLabel
        fileNameLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, fileNameLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 150)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func viewTapped() {
        onTap?()
    }
    
    func configure(title: String, systemImage: String) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: systemImage)
        fileNameLabel.text = "No file selected"
    }
    
    func setSelectedFileName(_ name: String?) {
        fileNameLabel.text = name ?? "No file selected"
    }
}
