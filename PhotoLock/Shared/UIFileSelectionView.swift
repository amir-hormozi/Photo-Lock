//
//  UIFileSelectionView.swift
//  PhotoLock
//
//  Created by Amir Hormozi on 7/7/25.
//

import UIKit

protocol UIFileSelectionViewDelegate: AnyObject {
    func didTapFileSelectionView(identifier: AnyHashable?)
}

class UIFileSelectionView: UIView {
    
    // MARK: Variable
    weak var delegate: UIFileSelectionViewDelegate?
    var identifier: AnyHashable?

    private lazy var iconImageView: UIImageView = {
        let image = UIImageView()
        image.tintColor = .label
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
       let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel, fileNameLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: LifeCycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Function
    private func setupView() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        addSubview(stack)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    @objc private func viewTapped() {
        delegate?.didTapFileSelectionView(identifier: identifier)
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
