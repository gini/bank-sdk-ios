//
//  EditLineItemViewController.swift
//
//  Copyright © 2024 Gini GmbH. All rights reserved.
//

import GiniCaptureSDK
import UIKit

final class EditLineItemViewController: UIViewController {
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = GiniColor(light: .GiniBank.light1, dark: .GiniBank.dark1).uiColor()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = .GiniBank.dark1
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var editLineItemView: EditLineItemView = {
        let view = EditLineItemView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var currentContainerHeight: CGFloat = 300
    private var currentBottomPadding: CGFloat = 0

    private var defaultHeight: CGFloat = 355
    private var isKeyboardPresented: Bool = false
    private var keyboardHeight: CGFloat = 0

    private var containerViewHeightConstraint: NSLayoutConstraint?
    private var containerViewBottomConstraint: NSLayoutConstraint?

    init(lineItemViewModel: EditLineItemViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.editLineItemView.viewModel = lineItemViewModel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        calculateContainerHeight()
        setupView()
        setupConstraints()
        setupPanGesture()
        setupTapGesture()
        GiniAnalyticsManager.trackScreenShown(screenName: .editReturnAssistant)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentContainer()
        animateDimmedView()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            if UIDevice.current.isIpad {
                self?.animatePresentContainer()
            }
        })
    }

    private func setupView() {
        view.backgroundColor = .clear
		if UIDevice.current.isIpad {
			containerView.round(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
								radius: Constants.cornerRadius)
		} else {
			containerView.round(corners: [.topLeft, .topRight],
								radius: Constants.cornerRadius)
		}
    }

    private func setupConstraints() {
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        containerView.addSubview(editLineItemView)

		// Create the constraints
		let constraints = [
			dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
			dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			editLineItemView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			editLineItemView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			editLineItemView.topAnchor.constraint(equalTo: containerView.topAnchor),
			editLineItemView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
		]

		// Set the priority for the height constraint
		let heightConstraint = editLineItemView.heightAnchor.constraint(equalToConstant: defaultHeight)
		heightConstraint.priority = UILayoutPriority(rawValue: 750)

		// Activate the constraints
		NSLayoutConstraint.activate(constraints + [heightConstraint])
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        if UIDevice.current.isIpad {
            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalTo: view.widthAnchor,
                                                     multiplier: Constants.tabletWidthMultiplier),
                containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
            containerViewBottomConstraint?.constant = defaultHeight
        } else {
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            ])
        }
        containerViewHeightConstraint?.isActive = true
        containerViewBottomConstraint?.isActive = true
    }

    private func calculateContainerHeight() {
        let normalSize: CGFloat = 17 // size of the .body textstyle when the font is not set bigger in accessibility
        if let pointSize = GiniBankConfiguration.shared.textStyleFonts[.body]?.pointSize {
            let diff = pointSize - normalSize
            let height = defaultHeight + 6 * diff // adding the extra difference for the 6 lines of the edit screen
            defaultHeight = min(height, self.view.frame.height)
            currentContainerHeight = min(height, self.view.frame.height)
        }
    }

    private func animatePresentContainer() {
        var bottomPadding: CGFloat
        if UIDevice.current.isIpad {
            bottomPadding = (view.bounds.height - defaultHeight) / 2
            currentBottomPadding = bottomPadding
        } else {
            bottomPadding = 0
        }

        UIView.animate(withDuration: Constants.animationDuration) {
            self.containerViewBottomConstraint?.constant = -bottomPadding
            self.view.layoutIfNeeded()
        }
    }

    private func animateDimmedView() {
        UIView.animate(withDuration: Constants.animationDuration) {
            self.dimmedView.alpha = Constants.maxDimmedAlpha
        }
    }

    private func animateDismissView() {
        editLineItemView.viewModel?.didTapCancel()
        editLineItemView.hideKeyBoard()
        UIView.animate(withDuration: Constants.animationDuration) {
            self.containerViewBottomConstraint?.constant = self.defaultHeight
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.dimmedView.alpha = Constants.maxDimmedAlpha
            UIView.animate(withDuration: Constants.animationDuration) {
                self.dimmedView.alpha = 0
            } completion: { _ in
                self.dismiss(animated: false)
            }
        }
    }

    // Pan gesture recognizer to move the container on tablet or change the height on phone.
    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }

    // Tap gesture recognizer to dismiss the viewcontroller
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture))
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        dimmedView.addGestureRecognizer(tapGesture)
    }

    // Handling the pan gesture
    @objc
    private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
            let newHeight = currentContainerHeight - translation.y
            let newBottomPadding = currentBottomPadding - translation.y

            switch gesture.state {
            // Pan is still in progress
            case .changed:
                if UIDevice.current.isIpad {
                    // Move the container based on the pan gesture
                    setBottomConstraint(gestureYTranslation: translation.y)
                    view.layoutIfNeeded()
                } else {
                    // Resize the container based on the pan gesture
                    if newHeight < Constants.maximumContainerHeight {
                        containerViewHeightConstraint?.constant = newHeight
                        view.layoutIfNeeded()
                    }
                }
            case .ended:
                // Pan ended
                if UIDevice.current.isIpad {
                    /* Dismiss the view if the bottom padding is half of the standard padding
                     or animate back to initial position of not */
                    if newBottomPadding < currentBottomPadding / 2 {
                        animateDismissView()
                    } else {
                        animateContainerToInitialPosition()
                    }
                } else {
                    /* Dismiss the view if the height is less than minimum height
                     or animate back to initial height of not */
                    if newHeight < Constants.dismissibleHeight + (isKeyboardPresented ? keyboardHeight : 0) {
                        animateDismissView()
                    } else {
                        animateContainerToInitialHeight()
                    }
                }
            default:
                break
            }
        }

    private func setBottomConstraint(gestureYTranslation: CGFloat = 0) {
        if UIApplication.shared.statusBarOrientation.isLandscape,
           self.isKeyboardPresented,
           self.keyboardHeight > 200 { // checking if digital keyboard is presented.
            containerViewBottomConstraint?.constant = -(view.frame.height - currentContainerHeight - Constants.topPadding - gestureYTranslation)
        } else {
            containerViewBottomConstraint?.constant = -(currentBottomPadding - gestureYTranslation)
        }
    }

    @objc
    private func handleTapGesture() {
        if isKeyboardPresented {
            editLineItemView.hideKeyBoard()
        } else {
            animateDismissView()
        }
    }

    private func animateContainerToInitialHeight() {
        UIView.animate(withDuration: Constants.animationDuration) {
            if self.isKeyboardPresented {
                self.containerViewHeightConstraint?.constant = self.defaultHeight +
                                                                (self.isKeyboardPresented ? self.keyboardHeight : 0)
                self.view.layoutIfNeeded()
            } else {
                self.containerViewHeightConstraint?.constant = self.defaultHeight
                self.view.layoutIfNeeded()
            }
        }
        currentContainerHeight = defaultHeight + (isKeyboardPresented ? keyboardHeight : 0)
    }

    private func animateContainerToInitialPosition() {
        UIView.animate(withDuration: Constants.animationDuration) {
            self.setBottomConstraint()
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Handle keyboard appearance
    @objc
    private func keyboardWillAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.keyboardHeight = keyboardHeight

            isKeyboardPresented = true
            if UIDevice.current.isIpad {
                if currentBottomPadding < keyboardHeight {
                    var bottomPadding: CGFloat

                    if keyboardHeight + currentContainerHeight > view.frame.height {
                        bottomPadding = view.frame.height - currentContainerHeight - Constants.topPadding
                    } else {
                        bottomPadding = keyboardHeight
                    }

                    UIView.animate(withDuration: Constants.animationDuration) {
                        self.containerViewBottomConstraint?.constant = -bottomPadding
                        self.view.layoutIfNeeded()
                    }
                }
            } else {
                let height = min(self.defaultHeight + keyboardHeight, self.view.frame.height)
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.containerViewHeightConstraint?.constant = height
                    self.view.layoutIfNeeded()
                }
                currentContainerHeight = height
            }
        }
    }

    @objc
    private func keyboardWillDisappear() {
        isKeyboardPresented = false
        if UIDevice.current.isIpad {
            animateContainerToInitialPosition()
        } else {
            animateContainerToInitialHeight()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}

private extension EditLineItemViewController {
    enum Constants {
        static let maxDimmedAlpha: CGFloat = 0.6
        static let defaultHeight: CGFloat = 586
        static let dismissibleHeight: CGFloat = 200
        static let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height - 64
        static let tabletWidthMultiplier: CGFloat = 0.6
        static let animationDuration: CGFloat = 0.3
        static let topPadding: CGFloat = 36
		static let cornerRadius: CGFloat = 16
    }
}
