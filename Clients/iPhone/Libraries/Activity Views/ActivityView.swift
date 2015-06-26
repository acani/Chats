import UIKit

class ActivityView: UIView {
    private var activityIndicatorView: UIActivityIndicatorView {
        return self.viewWithTag(1) as! UIActivityIndicatorView
    }

    var titleLabel: UILabel {
        return self.viewWithTag(2) as! UILabel
    }

    convenience init() {
        self.init(title: "Loading…")
    }

    init(title: String) {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        let width1 = activityIndicatorView.frame.width
        activityIndicatorView.center = CGPoint(x: width1/2, y: width1/2)
        activityIndicatorView.tag = 1

        let titleLabel = UILabel(frame: CGRect(x: width1+4, y: 0, width: 0, height: width1-1))
        titleLabel.font = UIFont.systemFontOfSize(14)
        titleLabel.tag = 2
        titleLabel.text = title
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor(white: 102/255, alpha: 1)
        let width2 = titleLabel.sizeThatFits(UIScreen.mainScreen().bounds.size).width
        titleLabel.frame.size.width = width2

        super.init(frame: CGRect(x: 0, y: 0, width: width1+4+width2, height: width1))
        autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleBottomMargin | .FlexibleRightMargin

        self.addSubview(activityIndicatorView)
        self.addSubview(titleLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        activityIndicatorView.startAnimating()
        let topWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        center = topWindow.center
        topWindow.addSubview(self)
    }

    func dismissAnimated(animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0, animations: {
            self.alpha = 0 // fade
        }, completion: { (finished) -> Void in
            self.activityIndicatorView.stopAnimating()
            self.removeFromSuperview()
        })
    }
}
