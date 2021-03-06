/**
 * Dependencies
 */

import UIKit
import ReactorKit

/**
 * Controller
 */

final class TasksCellController: CoreTableViewCellController, View {

    typealias Reactor = TasksCellReactor

    // MARK: Constants

    struct Metric {
        static let surface = UIColor(named: config["theme"]["themes"]["waos"]["surface"].string ?? "")
    }

    // MARK: UI

    let labelTitle = CoreUILabel().then {
        $0.numberOfLines = 2
    }

    // MARK: Initializing

    override func initialize() {
        self.contentView.addSubview(self.labelTitle)
        self.contentView.backgroundColor = Metric.surface
    }

    // MARK: Layout
    override func setupConstraints() {
        self.labelTitle.snp.makeConstraints { make in
            make.left.equalTo(25)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: Binding

    func bind(reactor: Reactor) {
        self.labelTitle.text = reactor.currentState.title
    }
}
