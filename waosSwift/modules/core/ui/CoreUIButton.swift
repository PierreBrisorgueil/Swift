@IBDesignable class CoreUIButton: UIButton {

    // MARK: Initializing

    override init(frame: CGRect) {
        super.init(frame: frame)
        shared()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        shared()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        shared()
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.highlightBtn()
            } else {
                self.clearHighlighted()
            }
        }
    }

    open override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.4
        }
    }

    func highlightBtn() {
        if traitCollection.userInterfaceStyle == .light {
            self.backgroundColor = UIColor(named: config["theme"]["themes"]["waos"]["surface"].string ?? "")!.darker(by: 5)
        } else {
            self.backgroundColor = UIColor(named: config["theme"]["themes"]["waos"]["surface"].string ?? "")!.lighter(by: 5)
        }

    }

    func clearHighlighted() {
        self.backgroundColor = UIColor(named: config["theme"]["themes"]["waos"]["surface"].string ?? "")
    }

    func shared() {
        self.layer.cornerRadius = CGFloat(config["theme"]["global"]["radius"].int ?? 0)
        self.backgroundColor = UIColor(named: config["theme"]["themes"]["waos"]["surface"].string ?? "")
        self.setTitleColor(UIColor(named: config["theme"]["themes"]["waos"]["onSurface"].string ?? ""), for: .normal)

        // animation at first launch
        self.transform = CGAffineTransform.init(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        })
    }
}
