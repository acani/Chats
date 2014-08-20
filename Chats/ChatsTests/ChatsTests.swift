import XCTest

class ChatsTests: XCTestCase {
    func testExample() {
        XCTAssertNil(User(ID: 1).initials, "")

        let users = [
            (User(ID: 3, firstName: nil, lastName: "Di Pasquale"), "D"),
            (User(ID: 1, firstName: "Matt", lastName: nil), "M"),
            (User(ID: 3, firstName: " ", lastName: "Di Pasquale"), " D"),
            (User(ID: 1, firstName: "Matt", lastName: " "), "M "),
            (User(ID: 1, firstName: "Matt", lastName: "Di Pasquale"), "MD"),
            (User(ID: 3, firstName: "Ë", lastName: "R"), "ËR"),
            (User(ID: 4, firstName: "Ë", lastName: "中"), "Ë")
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
