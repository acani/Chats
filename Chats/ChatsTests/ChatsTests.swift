import XCTest

class ChatsTests: XCTestCase {
    func testExample() {
        XCTAssertNil(User(ID: 1, username: "mattdipasquale", firstName: nil, lastName: nil).initials, "")

        let users = [
            (User(ID: 3, username: "walterstephanie", firstName: nil, lastName: "Di Pasquale"), "D"),
            (User(ID: 1, username: "mattdipasquale", firstName: "Matt", lastName: nil), "M"),
            (User(ID: 3, username: "walterstephanie", firstName: " ", lastName: "Di Pasquale"), " D"),
            (User(ID: 1, username: "mattdipasquale", firstName: "Matt", lastName: " "), "M "),
            (User(ID: 1, username: "mattdipasquale", firstName: "Matt", lastName: "Di Pasquale"), "MD"),
            (User(ID: 3, username: "walterstephanie", firstName: "Ë", lastName: "R"), "ËR"),
            (User(ID: 4, username: "wake_gs", firstName: "Ë", lastName: "中"), "Ë")
        ]

        for (user, initials) in users {
            XCTAssertEqual(user.initials!, initials, "")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
}
