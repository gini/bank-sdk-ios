//
//  SkontoHelpViewController.swift
//
//  Copyright © 2024 Gini GmbH. All rights reserved.
//

import GiniCaptureSDK
import UIKit

final class SkontoHelpViewController: UIViewController {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.spacing = Constants.spacing
        return stackView
    }()

    private lazy var headerView: SkontoHelpHeaderView = {
        let header = SkontoHelpHeaderView()
        return header
    }()

    private lazy var itemsGroupView: SkontoHelpItemsContainerView = {
        let groupView = SkontoHelpItemsContainerView(viewModel: viewModel)
        return groupView
    }()

    private lazy var footerView: SkontoHelpFooterView = {
        let footer = SkontoHelpFooterView()
        return footer
    }()

    private lazy var spacerView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }()

    private lazy var scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    private var navigationBarBottomAdapter: SkontoHelpNavigationBarBottomAdapter?
    private var navigationBarHeightConstraint: NSLayoutConstraint?

    private let viewModel = SkontoHelpViewModel()

    init() {
        super.init(nibName: nil, bundle: nil)
        setupViews()
        setupConstraints()
        configureBottomNavigationBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        title = NSLocalizedStringPreferredGiniBankFormat("ginibank.skonto.help.screen.title",
                                                         comment: "Help")
        view.backgroundColor = .giniColorScheme().background.primary.uiColor()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(itemsGroupView)
        stackView.addArrangedSubview(footerView)
        stackView.addArrangedSubview(spacerView)
        let backButtonTitle = NSLocalizedStringPreferredGiniBankFormat("ginibank.skonto.help.back",
                                                                       comment: "Skonto discount")
        let backButton = GiniBarButton(ofType: .back(title: backButtonTitle))
        backButton.addAction(self, #selector(dismissViewController))
        navigationItem.leftBarButtonItem = backButton.barButton
    }

    private func setupConstraints() {
        let widthMultiplier = UIDevice.current.isIpad ? 0.6 : 1

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.padding),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.padding),
            scrollViewBottomConstraint,

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: widthMultiplier),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func configureBottomNavigationBar() {
        let configuration = GiniBankConfiguration.shared
        if configuration.bottomNavigationBarEnabled {
            if let bottomBar = configuration.skontoHelpNavigationBarBottomAdapter {
                navigationBarBottomAdapter = bottomBar
            } else {
                navigationBarBottomAdapter = DefaultSkontoHelpNavigationBarBottomAdapter()
            }

            navigationBarBottomAdapter?.setBackButtonClickedActionCallback { [weak self] in
                self?.dismissViewController()
            }

            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.leftBarButtonItem = nil

            if let navigationBar = navigationBarBottomAdapter?.injectedView() {
                navigationBar.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(navigationBar)

                layoutBottomNavigationBar(navigationBar)
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self,
                  let heightConstraint = self.navigationBarHeightConstraint else { return }

            let newHeight = self.calculatedNavigationBarHeight(for: UIDevice.current.orientation)
            heightConstraint.constant = newHeight
            self.view.layoutIfNeeded()
        }
    }

    private func layoutBottomNavigationBar(_ navigationBar: UIView) {
        let navigationBarHeight = calculatedNavigationBarHeight(for: UIDevice.current.orientation)

        scrollViewBottomConstraint.isActive = false

        let heightConstraint = navigationBar.heightAnchor.constraint(equalToConstant: navigationBarHeight)
        navigationBarHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: navigationBar.topAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightConstraint
        ])

        view.bringSubviewToFront(navigationBar)
    }

    private func calculatedNavigationBarHeight(for orientation: UIDeviceOrientation) -> CGFloat {
        let isLandscape = orientation.isLandscape

        let baseHeight: CGFloat
        if isLandscape {
            baseHeight = Constants.navigationBarHeightLandscape
        } else {
            baseHeight = Constants.navigationBarHeightPortrait
        }

        let safeAreaBottomInset = isLandscape ? view.safeAreaInsets.bottom : 0
        return baseHeight + safeAreaBottomInset
    }

    @objc private func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
}

private extension SkontoHelpViewController {
    enum Constants {
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 32
        static let navigationBarHeightPortrait: CGFloat = UIDevice.current.isSmallIphone ? 72 : 114
        static let navigationBarHeightLandscape: CGFloat = UIDevice.current.isSmallIphone ? 40 : 62
    }
}
