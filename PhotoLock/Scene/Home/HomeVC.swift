//
//  HomeVC.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import UIKit
import Combine

class HomeVC: UIViewController {

    // MARK: Variable
    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let mainImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "topHomePage"))
        imageView.contentMode = .scaleToFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Encrypt", "Decrypt", "Keys"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentedControlChanged(_:)), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var encryptVC = EncryptVC()
    private lazy var decryptVC = DecryptVC()
    private lazy var keyManagementVC = KeyGenerateVC()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(mainImageView)
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            mainImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainImageView.heightAnchor.constraint(equalToConstant: 150),
            
            segmentedControl.topAnchor.constraint(equalTo: mainImageView.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTab in
                self?.displayChildViewController(for: newTab)
            }
            .store(in: &cancellables)
    }
    
    @objc private func segmentedControlChanged(_ sender: UISegmentedControl) {
        viewModel.didSelectTab(at: sender.selectedSegmentIndex)
    }
    
    private func displayChildViewController(for tab: HomeViewModel.Tab) {
        if let currentChild = children.first {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
        
        let childToAdd: UIViewController
        switch tab {
        case .encrypt:
            childToAdd = encryptVC
        case .decrypt:
            childToAdd = decryptVC
        case .keys:
            childToAdd = keyManagementVC
        }
        
        addChild(childToAdd)
        containerView.addSubview(childToAdd.view)
        childToAdd.view.frame = containerView.bounds
        childToAdd.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childToAdd.didMove(toParent: self)
    }
}

class KeyManagementVC: UIViewController { }
