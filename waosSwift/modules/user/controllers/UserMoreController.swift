/**
 * Dependencies
 */

import UIKit
import ReactorKit
import Eureka
import SafariServices

/**
 * Controller
 */

class UserMoreController: CoreFormController, View, NVActivityIndicatorViewable {

    // MARK: Constant

    fileprivate var avatar = BehaviorRelay<Data?>(value: nil)

    // MARK: UI

    let barButtonCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    let barButtonDone = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)

    // button Information
    let buttonChangelog = ButtonRow {
        $0.title = "Changelog"
        $0.setFontAwesomeIcon("fa-file")
    }
    let buttonTermsOfUse = ButtonRow {
        $0.title = L10n.userTermsOfUse
        $0.setFontAwesomeIcon("fa-file-alt")
    }
    let buttonPrivacyPolicy = ButtonRow {
        $0.title = L10n.userPrivacyPolicy
        $0.setFontAwesomeIcon("fa-lock")
    }
    let buttonLegalNotice = ButtonRow {
        $0.title = L10n.userLegalNotice
        $0.setFontAwesomeIcon("fa-stamp")
    }

    // MARK: Initializing

    init(reactor: UserMoreReactor) {
        super.init()
        self.reactor = reactor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        form
            +++ Section(header: L10n.userSectionAbout, footer: "")
            <<< self.buttonChangelog
            <<< self.buttonTermsOfUse
            <<< self.buttonPrivacyPolicy
            <<< self.buttonLegalNotice

        self.navigationItem.leftBarButtonItem = self.barButtonCancel
        self.navigationItem.rightBarButtonItem = self.barButtonDone
        self.view.addSubview(self.tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: Binding

    func bind(reactor: UserMoreReactor) {
        bindView(reactor)
        bindAction(reactor)
        bindState(reactor)
    }

}

/**
 * Extensions
 */

private extension UserMoreController {

    // MARK: views (View -> View)

    func bindView(_ reactor: UserMoreReactor) {
        // cancel
        self.barButtonCancel.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
        // informations
        self.buttonChangelog.rx.tap
            .subscribe(onNext: { _ in
                let viewController = HomePageController(reactor: reactor.changelogReactor())
                let navigationController = UINavigationController(rootViewController: viewController)
                self.present(navigationController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        self.buttonTermsOfUse.rx.tap
            .subscribe(onNext: { _ in
                if let url = config["app"]["links"]["terms"].string {
                    if (url.prefix(4) == "http") {
                        guard let url = URL(string: url) else { return }
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    } else {
                        let viewController = HomePageController(reactor: reactor.pageReactor(name: url))
                        let navigationController = UINavigationController(rootViewController: viewController)
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
            })
            .disposed(by: disposeBag)
        self.buttonPrivacyPolicy.rx.tap
            .subscribe(onNext: { _ in
                if let url = config["app"]["links"]["privacy"].string {
                    if (url.prefix(4) == "http") {
                        guard let url = URL(string: url) else { return }
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    } else {
                        let viewController = HomePageController(reactor: reactor.pageReactor(name: url))
                        let navigationController = UINavigationController(rootViewController: viewController)
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
            })
            .disposed(by: disposeBag)
        self.buttonLegalNotice.rx.tap
            .subscribe(onNext: { _ in
                if let url = config["app"]["links"]["legal"].string {
                    if (url.prefix(4) == "http") {
                        guard let url = URL(string: url) else { return }
                        let svc = SFSafariViewController(url: url)
                        self.present(svc, animated: true, completion: nil)
                    } else {
                        let viewController = HomePageController(reactor: reactor.pageReactor(name: url))
                        let navigationController = UINavigationController(rootViewController: viewController)
                        self.present(navigationController, animated: true, completion: nil)
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: actions (View -> Reactor)

    func bindAction(_ reactor: UserMoreReactor) {
        // buttons
        self.barButtonDone.rx.tap
            .throttle(.milliseconds(Metric.timesButtonsThrottle), latest: false, scheduler: MainScheduler.instance)
            .map { Reactor.Action.done }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
    }

    // MARK: states (Reactor -> View)

    func bindState(_ reactor: UserMoreReactor) {
        // dissmissed
        reactor.state
            .map { $0.isDismissed }
            .distinctUntilChanged()
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
}
