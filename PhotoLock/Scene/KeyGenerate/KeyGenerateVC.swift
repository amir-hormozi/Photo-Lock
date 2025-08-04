//
//  KeyGenerateVC.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import UIKit
import Combine

class KeyGenerateVC: UIViewController {

    // MARK: Variable
    private let viewModel = KeyGenerateViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let iconImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 60)
        let image = UIImage(systemName: "key.icloud.fill", withConfiguration: config)
        let imageView = UIImageView(image: image)
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Key Management"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Press the button below to generate a new key pair. This key is stored securely in the device's Secure Enclave.\n\nWarning: This will replace any existing key you have."
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var generateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Generate New Key Pair"
        config.image = UIImage(systemName: "arrow.2.circlepath.key")
        config.imagePadding = 8
        config.cornerStyle = .large
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.viewModel.generateNewKeysTapped()
        })
        return button
    }()
    
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    // MARK: Function
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        mainStackView.addArrangedSubview(iconImageView)
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.setCustomSpacing(30, after: titleLabel)
        mainStackView.addArrangedSubview(descriptionLabel)
        mainStackView.addArrangedSubview(generateButton)
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            generateButton.widthAnchor.constraint(equalTo: mainStackView.widthAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.showAlertAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (title, message) in
                self?.presentAlert(title: title, message: message)
            }
            .store(in: &cancellables)
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
