//
//  URITemplate.swift
//  URITemplateTouch
//
//  Created by Weipin Xia on 7/20/14.
//  Copyright (c) 2014 Weipin Xia. All rights reserved.
//

import Foundation

//var s = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//    str.bridgeToObjectiveC(), nil,
//    "!*'();:@&=+$,/?%#[]",
//    CFStringBuiltInEncodings.UTF8.toRaw())

enum URITemplateError {

}

class URITemplate {
    enum State {
        case Idle
        case LiteralsStart
        case LiteralsIn
        case LiteralsInPctEncodedStart
        case LiteralsInPctEncodedIn
        case LiteralsInPctEncodedEnd
        case LiteralsEnd
        case ExpressionStart
        case ExpressionIn
        case ExpressionEnd
    }

    enum BehaviorAllow {
        case U
        case R
        case UR
    }

    struct Behavior {
        var first: String
        var sep: String
        var named: Bool
        var ifemp: String
        var allow: BehaviorAllow
    }

    class func process(template: String, values: AnyObject, error: NSErrorPointer) -> String {
        // TODO: Use class variable
        struct ClassVariable {
            static let BehaviorTable = [
                "NUL": Behavior(first: "",  sep: ",", named: false, ifemp: "",  allow: .U),
                "+"  : Behavior(first: "",  sep: ",", named: false, ifemp: "",  allow: .UR),
                "."  : Behavior(first: ".", sep: ".", named: false, ifemp: "",  allow: .U),
                "/"  : Behavior(first: "/", sep: "/", named: false, ifemp: "",  allow: .U),
                ";"  : Behavior(first: ";", sep: ";", named: true,  ifemp: "",  allow: .U),
                "?"  : Behavior(first: "?", sep: "&", named: true,  ifemp: "=", allow: .U),
                "&"  : Behavior(first: "&", sep: "&", named: true,  ifemp: "=", allow: .U),
                "#"  : Behavior(first: "#", sep: ",", named: false, ifemp: "",  allow: .UR),
            ]
            static let HEXDIG = NSCharacterSet(charactersInString: "0123456789abcdefABCDEF")
            static let RESERVED = NSCharacterSet(charactersInString: ":/?#[]@!$&'()*+,;=")
            static let UNRESERVED = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~") // 66
        }

        var state: State = .Idle
        var result = ""
        var error: URITemplateError?

        for (c, index) in enumerate(template) {
            switch state {
            case .Idle:
                println("")
            case .LiteralsStart:
                println("")
            case .LiteralsIn:
                println("")
            case .ExpressionStart:
                println("")
            case .ExpressionIn:
                println("")
            case .ExpressionEnd:
                println("")
            }
        }

        return ""
    }
}