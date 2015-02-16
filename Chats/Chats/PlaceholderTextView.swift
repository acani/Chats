import UIKit

class PlaceholderTextView: UITextView {
    override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }

    override var text: String! {
        didSet {
            setNeedsDisplay()
        }
    }

    var placeholder: String = "" {
        didSet {
            setNeedsDisplay()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect, textContainer: NSTextContainer!) {
        super.init(frame: frame, textContainer: textContainer)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "setNeedsDisplay", name: UITextViewTextDidChangeNotification, object: self)
        notificationCenter.addObserver(self, selector: "setNeedsDisplay", name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if !hasText() {
            let rect = CGRect(x: 5, y: 8, width: self.frame.width-5*2, height: self.frame.height-5*2)
            let attributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor(white: 0.7, alpha: 1)]
            (placeholder as NSString).drawInRect(rect, withAttributes:attributes)
        }
    }
}
