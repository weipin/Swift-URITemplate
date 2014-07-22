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
    case MalformedPctEncodedInLiterals
}

class URITemplate {
    enum State {
        case ScanningLiterals
        case ScanningExpressions
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
            static let HEXDIG = "0123456789abcdefABCDEF"
            static let RESERVED = ":/?#[]@!$&'()*+,;="
            static let UNRESERVED = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~" // 66
        }

        let BehaviorTable = ClassVariable.BehaviorTable
        let HEXDIG = ClassVariable.HEXDIG
        let RESERVED = ClassVariable.RESERVED
        let UNRESERVED = ClassVariable.UNRESERVED


        // Pct-encoded isn't taken into account
        func appendLiteralCharacter(character: Character, toString: String) -> String {
            if find(RESERVED, character) || find(UNRESERVED, character) {
                var str = toString + character
                return str
            }

            var str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                            String(character).bridgeToObjectiveC(), nil, nil,
                            CFStringBuiltInEncodings.UTF8.toRaw())
            return str
        }

        func appendLiteralString(string: String, toString: String) -> String {
            var result = toString
            for c in string {
                result = appendLiteralCharacter(c, result)
            }
            return result
        }

        var state: State = .ScanningLiterals
        var result = ""
        var pctEncoded = ""
        var errors = Dictionary<Int, URITemplateError>()

        for (index, c) in enumerate(template) {
            switch state {
            case .ScanningLiterals:
                if c == "(" {
                    state = .ScanningExpressions

                } else if (countElements(pctEncoded) > 0) {
                    switch countElements(pctEncoded) {
                    case 1:
                        if find(HEXDIG, c) {
                            pctEncoded += c
                        } else {
                            errors[index] = URITemplateError.MalformedPctEncodedInLiterals
                            result = appendLiteralString(pctEncoded, result)
                            result = appendLiteralCharacter(c, result)
                            state = .ScanningLiterals
                            pctEncoded = ""
                        }

                    case 2:
                        if find(HEXDIG, c) {
                            pctEncoded += c
                            result += pctEncoded
                            state = .ScanningLiterals
                            pctEncoded = ""

                        } else {
                            errors[index] = URITemplateError.MalformedPctEncodedInLiterals
                            result = appendLiteralString(pctEncoded, result)
                            result = appendLiteralCharacter(c, result)
                            state = .ScanningLiterals
                            pctEncoded = ""
                        }

                    default:
                        assert(false)
                    }

                } else if c == "%" {
                    pctEncoded += c
                    state = .ScanningLiterals

                } else if find(UNRESERVED, c) || find(RESERVED, c) {
                    result += c

                } else {

                }

            case .ScanningExpressions:
                println("")

            default:
                assert(false)
            } // switch
        }// for

        return result
    } // process

} // URITemplate