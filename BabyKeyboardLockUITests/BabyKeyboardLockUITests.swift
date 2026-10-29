//
//  BabyKeyboardLockUITests.swift
//  BabyKeyboardLockUITests
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import XCTest

final class BabyKeyboardLockUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 5)
    }
}
