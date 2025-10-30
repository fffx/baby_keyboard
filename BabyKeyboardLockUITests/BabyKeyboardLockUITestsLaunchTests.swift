//
//  BabyKeyboardLockUITestsLaunchTests.swift
//  BabyKeyboardLockUITests
//
//  Created by Fangxing Xiong on 15.12.2024.
//

import XCTest

final class BabyKeyboardLockUITestsLaunchTests: XCTestCase {
    
    // Store original appearance mode
    static var originalAppearance: String?

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        // Set to false to prevent automatic switching between light/dark modes
        // which can leave the system in dark mode after tests complete
        false
    }
    
    override class func setUp() {
        super.setUp()
        // Save the original system appearance before tests run
        originalAppearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
    }
    
    override class func tearDown() {
        // Restore the original system appearance after all tests complete
        if let original = originalAppearance {
            // Restore dark mode
            UserDefaults.standard.set(original, forKey: "AppleInterfaceStyle")
        } else {
            // Remove the key to restore light mode
            UserDefaults.standard.removeObject(forKey: "AppleInterfaceStyle")
        }
        UserDefaults.standard.synchronize()
        
        // Notify the system of the appearance change
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        
        super.tearDown()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
