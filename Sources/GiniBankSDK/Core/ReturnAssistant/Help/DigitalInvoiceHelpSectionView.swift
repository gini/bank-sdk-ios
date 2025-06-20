//
//  DigitalInvoiceHelpSectionView.swift
//  
//
//  Created by David Vizaknai on 15.02.2023.
//

import GiniCaptureSDK
import UIKit

final class DigitalInvoiceHelpSectionView: UIView {
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = GiniColor(light: .GiniBank.dark1, dark: .GiniBank.light1).uiColor()
        titleLabel.font = configuration.textStyleFonts[.bodyBold]
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.isAccessibilityElement = false
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.isAccessibilityElement = false
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = GiniColor(light: .GiniBank.dark6,
                                               dark: .GiniBank.light6).uiColor()
        descriptionLabel.font = configuration.textStyleFonts[.body]
        descriptionLabel.adjustsFontForContentSizeCategory = true
        return descriptionLabel
    }()

    private let configuration = GiniBankConfiguration.shared

    init(content: DigitalInvoiceHelpSection) {
        super.init(frame: .zero)

        let accessibilityText = "\(content.title)\n\(content.description)"

        setupView(with: content)
        setupAccessibility(text: accessibilityText)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(with content: DigitalInvoiceHelpSection) {
        backgroundColor = .clear
        iconImageView.image = content.icon
        titleLabel.text = content.title
        descriptionLabel.text = content.description

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
    }

    private func setupAccessibility(text: String) {
        isAccessibilityElement = true
        accessibilityLabel = text
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: Constants.iconSize.height),
            iconImageView.widthAnchor.constraint(equalToConstant: Constants.iconSize.width),
            iconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -Constants.padding),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -Constants.padding),

            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension DigitalInvoiceHelpSectionView {
    private enum Constants {
        static let padding: CGFloat = 8
        static let iconSize = CGSize(width: 24, height: 24)
    }

}
