import UIKit

class API {
    let baseURL: NSURL?

    init(baseURL: NSURL?) {
        self.baseURL = baseURL
    }

    func URLWithPath(path: String) -> NSURL {
        return NSURL(string: path, relativeToURL: baseURL)!
    }

    func formRequest(HTTPMethod: String, _ path: String, _ fields: Dictionary<String, String>) -> NSMutableURLRequest {
        return Web.formRequest(HTTPMethod, URL: URLWithPath(path), fields)
    }

    func multipartRequest(path: String, _ data: NSData, _ fields: Dictionary<String, String>) -> NSMutableURLRequest {
        return Web.multipartRequest(URLWithPath(path), data, fields)
    }
}

class Web {
    class func formRequest(HTTPMethod: String, URL: NSURL, _ fields: Dictionary<String, String>) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = HTTPMethod
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = formHTTPBodyFromFields(fields)
        return request
    }

    class func multipartRequest(URL: NSURL, _ data: NSData, _ fields: Dictionary<String, String>) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "POST"

        let boundary = "-----AcaniFormBoundary" + randomStringWithLength(16)
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var bodyString = ""
        for (name, value) in fields {
            bodyString += "--" + boundary + "\r\n"
            bodyString += "Content-Disposition: form-data; name=\"\(name)\"" + "\r\n" + "\r\n"
            bodyString += value + "\r\n"
        }
        bodyString += "--" + boundary + "\r\n"
        var name = "file"
        bodyString += "Content-Disposition: form-data; name=\"\(name)\"" + "; filename=\"p.jpg\"" + "\r\n"
        bodyString += "Content-Type: image/jpeg" + "\r\n" + "\r\n"
        var body = NSMutableData(data: bodyString.dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(data)
        bodyString = "\r\n" + "--" + boundary + "--" + "\r\n"
        body.appendData(bodyString.dataUsingEncoding(NSUTF8StringEncoding)!)
        request.HTTPBody = body

        return request
    }

    // Convert ["name1": "value1", "name2": "value2"] to "name1=value1&name2=value2".
    // NOTE: Like curl, let front-end developers URL encode names & values.
    private class func formHTTPBodyFromFields(fields: Dictionary<String, String>) -> NSData? {
        var bodyString = [String]()
        for (name, value) in fields {
            bodyString.append("\(name)=\(value)")
        }
        return join("&", bodyString).dataUsingEncoding(NSUTF8StringEncoding)
    }

    private class func randomStringWithLength(length: Int) -> String {
        let alphabet = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ -> Character in
            return alphabet[advance(alphabet.startIndex, Int(arc4random_uniform(64)))]
        })
    }
}

extension String {
    // Percent encode all characters except alphanumerics, "*", "-", ".", and "_". Replace " " with "+".
    // http://www.w3.org/TR/html5/forms.html#application/x-www-form-urlencoded-encoding-algorithm
    func stringByAddingFormURLEncoding() -> String {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("*-._ ")
        return stringByAddingPercentEncodingWithAllowedCharacters(characterSet)!.stringByReplacingOccurrencesOfString(" ", withString: "+")
    }
}

extension UIAlertView {
    convenience init(dictionary: Dictionary<String, String>?, error: NSError!, delegate: AnyObject?) {
        let title = dictionary?["title"] ?? ""
        let message = dictionary?["message"] ?? (error != nil ? error.localizedDescription : "Could not connect to server.")
        self.init(title: title, message: message, delegate: delegate, cancelButtonTitle: "OK")
    }
}
