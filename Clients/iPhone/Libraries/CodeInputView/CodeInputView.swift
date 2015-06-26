import UIKit

class CodeInputView: UIView, UIKeyInput {
    var delegate: CodeInputViewDelegate?
    var nextTag = 1

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add four digitLabels
        var frame = CGRect(x: 15, y: 10, width: 35, height: 40)
        for index in 1...4 {
            let digitLabel = UILabel(frame: frame)
            digitLabel.font = UIFont.systemFontOfSize(42)
            digitLabel.tag = index
            digitLabel.text = "–"
            digitLabel.textAlignment = .Center
            self.addSubview(digitLabel)
            frame.origin.x += 35 + 15
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIResponder

    override func canBecomeFirstResponder() -> Bool {
        return true;
    }

    // MARK: - UIKeyInput

    func hasText() -> Bool {
        return nextTag > 1 ? true : false
    }

    func insertText(text: String) {
        if nextTag < 5 {
            (self.viewWithTag(nextTag) as! UILabel).text = text
            ++nextTag

            if nextTag == 5 {
                var code = (self.viewWithTag(1) as! UILabel).text!
                for index in 2..<nextTag {
                    code += (self.viewWithTag(index) as! UILabel).text!
                }
                delegate?.codeInputView(self, didFinishWithCode: code)
            }
        }
    }

    func deleteBackward() {
        if nextTag > 1 {
            --nextTag
            (self.viewWithTag(nextTag) as! UILabel).text = "-"
        }
    }

    func clear() {
        while nextTag > 1 {
            deleteBackward()
        }
    }

    // MARK: - UITextInputTraits

    var keyboardType: UIKeyboardType { get { return .NumberPad } set { } }
}

protocol CodeInputViewDelegate {
    func codeInputView(codeInputView: CodeInputView, didFinishWithCode code: String)
}
