//
//  SheetViewController.swift
//
//
//  Created by Максим Голов on 04.04.2022.
//

import UIKit

// MARK: - SheetScrollView

private final class SheetScrollView: UIScrollView {
    /// Отключить автоматический скролл к текстовому полю при появлении клавиатуры
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {}
}

// MARK: - SheetViewControllerDelegate

protocol SheetViewControllerDelegate: AnyObject {
    func sheetViewControllerDidDismiss(_ sheetViewController: SheetViewController)
}

// MARK: - SheetViewController

class SheetViewController: TrendViewController, PresentationControllerDelegate {
    // MARK: - Constants

    private enum Constants {
        static let dismissTriggerOffset: CGFloat = 10
    }

    // MARK: - Public Properties

    weak var sheetDelegate: SheetViewControllerDelegate?

    /// `UIView` that stays always on the screen, similar to UITableView sections
    var stickyHeaderView: UIView? {
        headerStackView
    }

    var scrollViewBottomInset: CGFloat {
        view.safeAreaInsets.bottom
    }

    var contentPreferredHeight: CGFloat {
        contentView.systemLayoutSizeFitting(.zero).height
    }

    var maxAvailableContentHeight: CGFloat {
        scrollView.frame.height - minimumScrollTopInset - scrollViewBottomInset
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private let titleContainer: UIView = {
        let container = UIView()
//        container.isVisible = false
        return container
    }()

    private(set) lazy var headerStackView = {
        let stackView = UIStackView(arrangedSubviews: [
//            BarHandleView(backgroundStyle: backgroundStyle, barColor: barHandleColor),
            titleContainer
        ])
        stackView.axis = .vertical
        stackView.layer.insertSublayer(headerStackViewBackgroudLayer, at: .zero)
        return stackView
    }()

    private(set) lazy var contentView = {
        let view = UIView()
        // Layer нужен для того, чтобы не было пустоты снизу при растягивании bottom sheet-а
        let layer = SheetBackgroundLayer(style: backgroundStyle)
        view.layer.insertSublayer(layer, at: .zero)
        return view
    }()

    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = SheetScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delaysContentTouches = false
//        scrollView.setCorners(radius: 14, maskedCorners: .top)
        return scrollView
    }()

    // MARK: - Private Properties

    private var minimumScrollTopInset: CGFloat {
        stickyHeaderView?.layoutIfNeeded()
        return stickyHeaderView?.frame.height ?? .zero
    }

    private var scrollViewTopInset: CGFloat {
        return max(
            minimumScrollTopInset,
            scrollView.frame.height - contentPreferredHeight - scrollViewBottomInset
        )
    }

    private var availableToDismiss: Bool {
        scrollView.contentOffset.y + scrollViewTopInset <= Constants.dismissTriggerOffset
    }

    private lazy var headerStackViewBackgroudLayer: SheetBackgroundLayer = {
        let layer = SheetBackgroundLayer(style: backgroundStyle)
        layer.cornerRadius = 14
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return layer
    }()

    private let backgroundStyle: SheetBackgroundLayer.Style
//    private let barHandleColor: UIColor
    private let ignoreSafeArea: Bool

    // MARK: - Initialisers

    init(
        backgroundStyle: SheetBackgroundLayer.Style = .solid(.white),
//        barHandleColor: UIColor = .Background.secondary,
        ignoreSafeArea: Bool = false
    ) {
        self.backgroundStyle = backgroundStyle
//        self.barHandleColor = barHandleColor
        self.ignoreSafeArea = ignoreSafeArea
        super.init()
        view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { nil }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

//        titleContainer.addSubview(titleLabel) {
//            $0.top.equalToSuperview()
//            $0.leading.trailing.bottom.equalToSuperview().inset(20)
//        }
//        scrollView.addSubview(contentView) {
//            $0.edges.equalToSuperview()
//            $0.width.equalToSuperview()
//            $0.centerX.equalToSuperview()
//        }
//        view.addSubview(scrollView) {
//            $0.top.equalToSuperview().inset(UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
//            $0.leading.trailing.equalToSuperview()
//            $0.bottom.equalToSuperview().offset(ignoreSafeArea ? 2 * (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) : 0)
//        }
//        activityIndicatorContainerView.snp.remakeConstraints {
//            $0.center.equalTo(contentView)
//            $0.size.equalTo(70)
//        }
//        activityIndicatorContainerView.isHidden = true
        addStickyHeaderView()
        view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        headerStackView.layoutIfNeeded()

        scrollView.contentInset = UIEdgeInsets(
            top: ceil(scrollViewTopInset),
            left: .zero,
            bottom: scrollViewBottomInset,
            right: .zero
        )

        let backgroundLayerHeight = max(UIScreen.main.bounds.height, contentView.frame.height) * 2
        contentView.layer.sublayers?.first?.frame = CGRect(
            origin: .zero,
            size: CGSize(width: contentView.frame.width, height: backgroundLayerHeight)
        )
        headerStackViewBackgroudLayer.frame = CGRect(
            origin: .zero,
            size: CGSize(width: headerStackView.frame.width, height: headerStackView.frame.height)
        )
    }

    // MARK: - PresentationControllerDelegate

    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController,
        withInteractionIn view: UIView?
    ) -> Bool {
//        if let view = view,
//           scrollView.hasViewInHierarchy(of: view, where: { $0 is UIDatePicker || $0 is UIPickerView }) {
//            return false
//        }
//        if let scrollView = view as? UIScrollView, scrollView !== self.scrollView {
//            return scrollView.contentOffset.y == 0
//        }
        return false //availableToDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        sheetDelegate?.sheetViewControllerDidDismiss(self)
    }

    func backgroundView(for presentationController: UIPresentationController) -> UIView? {
        return scrollView
    }

    // MARK: - Public Methods

    func updateSheetTitle(text: String?) {
//        titleLabel.updateText(text: text, shouldUseLineHeight: true)
//        titleContainer.isVisible = !text.isEmptyOrNil
    }

    // MARK: - Private Methods

    private func addStickyHeaderView() {
        guard let stickyHeaderView = stickyHeaderView else { return }

//        scrollView.addSubview(stickyHeaderView) {
//            $0.width.equalToSuperview()
//            $0.centerX.equalToSuperview()
//            $0.bottom.equalTo(contentView.snp.top)
//        }
    }
}

// MARK: - UIScrollViewDelegate

extension SheetViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView else { return }
        stickyHeaderTransform(for: scrollView.contentOffset)
    }

    private func stickyHeaderTransform(for contentOffset: CGPoint) {
        guard let stickyHeaderView = stickyHeaderView else { return }

        if contentOffset.y >= -stickyHeaderView.bounds.height {
            let translationY = contentOffset.y + stickyHeaderView.bounds.height
            stickyHeaderView.transform = CGAffineTransform(translationX: 0, y: translationY)
        } else {
            stickyHeaderView.transform = .identity
        }
    }
}

import UIKit

// MARK: - UIViewController + Toast

extension UIViewController {
    func showToast(_ toast: UIView) {
        let bigBackView = UIView()
        bigBackView.layer.zPosition = 10
//        bigBackView.snp.makeConstraints {
//            $0.height.equalTo(view.frame.height - view.safeAreaInsets.bottom)
//            $0.width.equalTo(view.frame.width)
//        }
//        bigBackView.addSubview(toast) {
//            $0.bottom.equalToSuperview().inset(20)
//            $0.leading.trailing.equalToSuperview().inset(20)
//        }
//        view.showToast(bigBackView)
    }

    func showToast(title: String, subtitle: String, imageName: String) {
        let bigBackView: UIView = {
            let bigView = UIView()
            bigView.layer.zPosition = 10
//            bigView.snp.makeConstraints { make in
//                make.height.equalTo(view.safeAreaLayoutGuide.layoutFrame.size.height)
//                make.width.equalTo(UIScreen.main.bounds.width)
//            }
            return bigView
        }()

        let backView: UIView = {
            let backView = UIView()
//            backView.backgroundColor = UIColor.Mono.black80
            backView.layer.cornerRadius = 10
            bigBackView.addSubview(backView)
//            backView.snp.makeConstraints { make in
//                make.bottom.equalTo(bigBackView.snp.bottom).offset(40)
//                make.left.equalTo(bigBackView.snp.left).offset(20)
//                make.right.equalTo(bigBackView.snp.right).offset(-20)
//            }
            return backView
        }()
        let imageView: UIImageView = {
            let imageView = UIImageView(image: UIImage(named: imageName))
//            backView.addSubview(imageView) {
//                $0.size.equalTo(20)
//                $0.centerY.equalToSuperview()
//                $0.leading.equalToSuperview().inset(10)
//            }
            return imageView
        }()
//        let titleLabel: TALabel = {
//            let label = TALabel(style: .textBold)
//            label.textColor = .white
//            label.numberOfLines = 0
//            label.updateText(text: title)
//            backView.addSubview(label)
//            label.snp.makeConstraints { make in
//                make.top.equalTo(backView.snp.top).offset(10)
//                make.leading.equalTo(imageView.snp.trailing).offset(10)
//                make.right.equalTo(backView.snp.right).offset(-20)
//            }
//            return label
//        }()
//        let subtitleLabel: TALabel = {
//            let label = TALabel(style: .smallText)
//            label.textColor = .white
//            label.numberOfLines = 0
//            label.updateText(text: subtitle)
//            backView.addSubview(label)
//            label.snp.makeConstraints { make in
//                make.top.equalTo(titleLabel.snp.bottom).offset(5)
//                make.left.equalTo(titleLabel.snp.left)
//                make.right.equalTo(titleLabel.snp.right)
//                make.bottom.equalTo(backView.snp.bottom).offset(-10)
//            }
//            return label
//        }()
//        view.showToast(bigBackView)
    }
}

// MARK: - TrendViewController

/// Стандартный UIViewController, любой другой UIViewController должен наследоваться от этого класса (кроме исключений)
class TrendViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Variables

    var isUsingApp = true
    var notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    var backHandlerView: (() -> Void)?
    var timerServer: Timer?

    var needsToShowNewError: Bool {
        return false
    }

    var needsToUpNewError: Bool {
        return false
    }

    lazy var activityIndicatorContainerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 4
        containerView.layer.zPosition = 100

        view.addSubview(containerView)

//        containerView.snp.makeConstraints { make in
//            make.center.equalTo(view)
//            make.size.equalTo(70)
//        }

        return containerView
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: - Functions

    /// Показывает алерт
    /// - Parameter title: Заголовок
    /// - Parameter message: Сообщение
    /// - Parameter handler: Опциональный handler для кнопки
    func showAlert(
        title: String,
        message: String,
        actionHandler handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(
            title: "ok",
            style: .cancel,
            handler: handler
        )
        alert.addAction(okAction)

        present(
            alert,
            animated: true,
            completion: nil
        )
    }

    func showAlertForServer(
        message: String,
        actionHandler handler: ((UIAlertAction) -> Void)? = nil
    ) {
//        let alert = UIAlertController(
//            title: ".mokoString(\.common_error)",
//            message: message,
//            preferredStyle: .alert
//        )
//
//        let action = UIAlertAction(
//            title: ".mokoString(\.cancel)",
//            style: .cancel,
//            handler: nil
//        )
//        let okAction = UIAlertAction(
//            title: ".mokoString(\.retry_connection)",
//            style: .default,
//            handler: handler
//        )
//
//        alert.addAction(okAction)
//        alert.addAction(action)
//
//        present(
//            alert,
//            animated: true,
//            completion: nil
//        )
    }

    func showAlert(
        title: String,
        message: String,
        buttonTitle: String,
        buttonStyle: UIAlertAction.Style = .default,
        buttonHandler: ((UIAlertAction) -> Void)? = nil,
        actionTitle: String = "",
        actionStyle: UIAlertAction.Style = .cancel,
        actionHandler handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let action = UIAlertAction(
            title: buttonTitle,
            style: buttonStyle,
            handler: buttonHandler
        )
        let okAction = UIAlertAction(
            title: actionTitle,
            style: actionStyle,
            handler: handler
        )

        alert.addAction(action)
        alert.addAction(okAction)

        present(
            alert,
            animated: true,
            completion: nil
        )
    }

    func showCameraAccessDeniedAlert() {
//        showAlert(
//            title: ".mokoString(\.common_ios_camera_disabled)",
//            message: ".mokoString(\.common_ios_need_access_to_camera)",
//            buttonTitle: ".mokoString(\.common_cancel)",
//            buttonStyle: .cancel,
//            buttonHandler: nil,
//            actionTitle: ".mokoString(\.common_ios_in_settings)",
//            actionStyle: .default
//        ) { _ in
//            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
//            UIApplication.shared.open(settingsUrl)
//        }
    }

    func showAnimationErrorServer() {
        view.updateConstraintsIfNeeded()
        timerServer?.invalidate()
        UIView.animate(withDuration: 0.2, animations: {
//            self.errorView.frame = CGRect(x: 20, y: self.view.safeAreaLayoutGuide.layoutFrame.maxY - (self.needsToUpNewError ? 50 : 40), width: self.view.frame.width - 40, height: 40)
        }, completion: { _ in
            self.view.layoutIfNeeded()
        })
        timerServer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(stopTimer), userInfo: nil, repeats: false)
    }

    func hideAnimationErrorServer() {
        view.updateConstraintsIfNeeded()
        UIView.animate(withDuration: 0.2, delay: 0) {
//            self.errorView.frame = CGRect(x: 20, y: self.view.safeAreaLayoutGuide.layoutFrame.maxY + 40, width: self.view.frame.width - 40, height: 40)
        }
        view.layoutIfNeeded()
    }

    @objc private func stopTimer() {
        hideAnimationErrorServer()
    }

    @objc private func swipeRecognized(recognizer: UISwipeGestureRecognizer) {
        if recognizer.direction == .down {
            hideAnimationErrorServer()
        }
    }

    func showUserLocationUnauthorizedAlert() {
//        showAlert(
//            title: .mokoString(\.common_error),
//            message: .mokoString(\.common_need_location),
//            buttonTitle: .mokoString(\.common_settings),
//            buttonHandler: { _ in
//                guard
//                    let settingsUrl = URL(string: UIApplication.openSettingsURLString),
//                    UIApplication.shared.canOpenURL(settingsUrl)
//                else { return }
//
//                UIApplication.shared.open(settingsUrl)
//            }
//        )
    }

    @objc func showToastViewFromNotification(_ sender: Notification) {
        guard let title = sender.userInfo?["title"] as? String,
              let subtitle = sender.userInfo?["subtitle"] as? String,
              let imageName = sender.userInfo?["image"] as? String else { return }
        showToast(title: title, subtitle: subtitle, imageName: imageName)
    }

    func canPresentChat(chatId: String) -> Bool { true }

    // MARK: - UIViewController

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(showToastViewFromNotification(_:)),
//            name: .needsToShowToastView,
//            object: nil
//        )
//        _ = errorView
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        NotificationCenter.default.removeObserver(self, name: .needsToShowToastView, object: nil)
//        TrendAgentUserDefaults.instance.chatId = nil
        hideAnimationErrorServer()
    }

    deinit {
        print("Deinit \(classForCoder)")
    }
}
