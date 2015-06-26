import UIKit

class UsersCollectionViewController: UICollectionViewController {
    convenience init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: userCollectionViewCellHeight, height: userCollectionViewCellHeight)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        layout.sectionInset = UIEdgeInsets(top: 9, left: 0, bottom: 9, right: 0)
        self.init(collectionViewLayout: layout)
        title = "Users"
    }

    deinit {
        account.removeObserver(self, forKeyPath: "users")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.alwaysBounceVertical = true
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.registerClass(UserCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UserCollectionViewCell))
        account.addObserver(self, forKeyPath: "users", options: NSKeyValueObservingOptions(0), context: nil)

        if account.accessToken != "guest_access_token" {
            getUsers()
        }
    }

    func getUsers() -> NSURLSessionDataTask {
        let activityView = ActivityView()
        activityView.show()

        let request = NSMutableURLRequest(URL: api.URLWithPath("/users"))
        request.setValue("Bearer "+account.accessToken, forHTTPHeaderField: "Authorization")
        let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if response != nil {
                let statusCode = (response as! NSHTTPURLResponse).statusCode
                let collection: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)

                var users = [User]()
                if statusCode == 200 {
                    for item in collection as! NSArray {
                        let ID = item["id"] as! NSNumber
                        let name = item["name"] as! Dictionary<String, String>
                        let user = User(ID: ID.unsignedLongValue, username: "", firstName: name["first"]!, lastName: name["last"]!)
                        users.append(user)
                    }
                }

                dispatch_async(dispatch_get_main_queue(), {
                    activityView.dismissAnimated(true)
                    if statusCode == 200 {
                        account.users = users
                    } else {
                        UIAlertView(dictionary: (collection as! Dictionary), error: error, delegate: nil).show()
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    activityView.dismissAnimated(true)
                    UIAlertView(dictionary: nil, error: error, delegate: nil).show()
                })
            }
        })
        dataTask.resume()
        return dataTask
    }


    // MARK: - NSKeyValueObserving

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        collectionView!.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return account.users.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(UserCollectionViewCell), forIndexPath: indexPath) as! UserCollectionViewCell
        let user = account.users[indexPath.item]
        cell.nameLabel.text = user.name
        if let pictureName = user.pictureName() {
            (cell.backgroundView as! UIImageView).image = UIImage(named: pictureName)
        } else {
            (cell.backgroundView as! UIImageView).image = nil
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let user = account.users[indexPath.item]
        navigationController?.pushViewController(ProfileTableViewController(user: user), animated: true)
    }
}
