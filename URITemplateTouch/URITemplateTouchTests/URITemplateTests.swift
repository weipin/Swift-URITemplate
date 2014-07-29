//
//  URITemplateTests.swift
//  URITemplateTests
//
//  Created by Weipin Xia on 7/20/14.
//  Copyright (c) 2014 Weipin Xia. All rights reserved.
//

import UIKit
import XCTest

import URITemplateTouch

let TestBundleIdentifier = "com.cocoahope.URITemplateTests"

class URITemplateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

    func testURLTemplate() {
        var bundle = NSBundle(identifier: TestBundleIdentifier)
        var URL = bundle.URLForResource("URITemplateRFCTests", withExtension: "json")
        var data = NSData.dataWithContentsOfURL(URL, options: NSDataReadingOptions(0), error: nil)
        var dict: NSDictionary! = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as NSDictionary
        for (testSuiteName, value) in dict {
            var variables = value["variables"]
            var testcases = value["testcases"] as [AnyObject]
            for testcase in testcases {
                var template = testcase[0] as String
                var result = testcase[1] as String
                var (string, errors) = URITemplate.process(template, values: variables)
                XCTAssertEqual(string, result, "SUITE: \(testSuiteName), TEMPLATE: \(template)")
            }
        }
    }
}
