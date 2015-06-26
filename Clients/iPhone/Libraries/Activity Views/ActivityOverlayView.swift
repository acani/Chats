import UIKit

class ActivityOverlayView: UIView {
    private var activityIndicatorView: UIActivityIndicatorView {
        return self.viewWithTag(1) as! UIActivityIndicatorView
    }

    var titleLabel: UILabel {
        return self.viewWithTag(2) as! UILabel
    }

    class func sharedView() -> ActivityOverlayView {
        let topWindow = UIApplication.sharedApplication().windows.last as! UIWindow
        var activityOverlayView = topWindow.viewWithTag(147) as! ActivityOverlayView!
        if activityOverlayView == nil {
            activityOverlayView = ActivityOverlayView()
            activityOverlayView.tag = 147
        }
        return activityOverlayView
    }

    private init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 128, height: 128))
        autoresizingMask = .FlexibleTopMargin | .FlexibleLeftMargin | .FlexibleBottomMargin | .FlexibleRightMargin
        backgroundColor = UIColor(white: 0, alpha: 0.75)
        layer.cornerRadius = 10

        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicatorView.center = CGPoint(x: 128/2, y: 128/2)
        activityIndicatorView.tag = 1
        self.addSubview(activityIndicatorView)

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 128-20-16, width: 128, height: 20))
        titleLabel.font = UIFont.boldSystemFontOfSize(16)
        titleLabel.tag = 2
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor.whiteColor()
        self.addSubview(titleLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWithTitle(title: String) {
        let sharedApplication = UIApplication.sharedApplication()
        sharedApplication.beginIgnoringInteractionEvents()
        activityIndicatorView.startAnimating()
        titleLabel.text = title
        let topWindow = sharedApplication.windows.last as! UIWindow
        center = topWindow.center
        topWindow.addSubview(self)
    }

    func dismissAnimated(animated: Bool) {
        UIView.animateWithDuration(animated ? 0.3 : 0, animations: {
            self.alpha = 0 // fade
        }, completion: { (finished) -> Void in
            self.removeFromSuperview()
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        })
    }
}
