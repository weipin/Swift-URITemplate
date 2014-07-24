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
    case MalformedPctEncodedInLiteral
    case NonLiteralsCharacterFoundInLiteral
    case ExpressionEndedWithoutClosing
    case NonExpressionFound
    case InvalidOperator
    case MalformedVarSpec
}

let URITemplateSyntaxErrorsKey = "SyntaxErrors"

class URITemplate {
    enum State {
        case ScanningLiteral
        case ScanningExpression
    }

    enum ExpressionState {
        case ScanningVarName
        case ScanningModifier
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

    class func process(template: String, values: AnyObject) -> (String, Array<(URITemplateError, Int)>) {
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
            static let DIGIT = "0123456789"
            static let RESERVED = ":/?#[]@!$&'()*+,;="
            static let UNRESERVED = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~" // 66
            static let VARCHAR = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" // exclude pct-encoded
        }

        let BehaviorTable = ClassVariable.BehaviorTable
        let HEXDIG = ClassVariable.HEXDIG
        let DIGIT = ClassVariable.DIGIT
        let RESERVED = ClassVariable.RESERVED
        let UNRESERVED = ClassVariable.UNRESERVED
        let VARCHAR = ClassVariable.VARCHAR

        // Pct-encoded isn't taken into account
        func appendLiteralCharacter(character: Character, toString: String) -> String {
            if find(RESERVED, character) || find(UNRESERVED, character) {
                var str = toString + character
                return str
            }

            var str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                            String(character).bridgeToObjectiveC(), nil, nil,
                            CFStringBuiltInEncodings.UTF8.toRaw())
            return String(str)
        }

        func appendLiteralString(string: String, toString: String) -> String {
            var result = toString
            for c in string {
                result = appendLiteralCharacter(c, result)
            }
            return result
        }

        func findOperatorInExpression(expression: String) -> (operator: Character?, error: URITemplateError?) {
            var count = countElements(expression)

            if count == 0 {
                return (nil, URITemplateError.InvalidOperator)
            }

            var operator: Character? = nil
            var error: URITemplateError? = nil
            var startCharacher = expression[expression.startIndex]
            if startCharacher == "%" {
                if count < 3 {
                    return (nil, URITemplateError.InvalidOperator)
                }

                var c1 = expression[advance(expression.startIndex, 1)]
                var c2 = expression[advance(expression.startIndex, 2)]
                if !find(HEXDIG, c1) {
                    return (nil, URITemplateError.InvalidOperator)
                }
                if !find(HEXDIG, c2) {
                    return (nil, URITemplateError.InvalidOperator)
                }
                var str = "%" + c1 + c2
                str = str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                operator = str[str.startIndex]
            } else {
                operator = startCharacher
            }

            if operator {
                if !find(VARCHAR, operator!) {
                    return (nil, URITemplateError.InvalidOperator)
                }

                if !BehaviorTable[String(operator!)] {
                    return (nil, nil)
                }
            }

            return (operator, error)
        }

        var state: State = .ScanningLiteral
        var result = ""
        var pctEncoded = ""
        var expression = ""
        var expressionCount = 0
        var syntaxErrors = Array<(URITemplateError, Int)>()

        for (index, c) in enumerate(template) {
            switch state {
            case .ScanningLiteral:
                if c == "{" {
                    state = .ScanningExpression
                    ++expressionCount

                } else if (countElements(pctEncoded) > 0) {
                    switch countElements(pctEncoded) {
                    case 1:
                        if find(HEXDIG, c) {
                            pctEncoded += c
                        } else {
                            syntaxErrors += (URITemplateError.MalformedPctEncodedInLiteral, index)
                            result = appendLiteralString(pctEncoded, result)
                            result = appendLiteralCharacter(c, result)
                            state = .ScanningLiteral
                            pctEncoded = ""
                        }

                    case 2:
                        if find(HEXDIG, c) {
                            pctEncoded += c
                            result += pctEncoded
                            state = .ScanningLiteral
                            pctEncoded = ""

                        } else {
                            syntaxErrors += (URITemplateError.MalformedPctEncodedInLiteral, index)
                            result = appendLiteralString(pctEncoded, result)
                            result = appendLiteralCharacter(c, result)
                            state = .ScanningLiteral
                            pctEncoded = ""
                        }

                    default:
                        assert(false)
                    }

                } else if c == "%" {
                    pctEncoded += c
                    state = .ScanningLiteral

                } else if find(UNRESERVED, c) || find(RESERVED, c) {
                    result += c

                } else {
                    syntaxErrors += (URITemplateError.NonLiteralsCharacterFoundInLiteral, index)
                    result += c
                }

            case .ScanningExpression:
                if c == "}" {
                    state = .ScanningLiteral
                    // Process expression
                    let (operator, error) = findOperatorInExpression(expression)
                    if error {
                        syntaxErrors += (URITemplateError.MalformedPctEncodedInLiteral, index)
                        result = result + "{" + expression + "}"

                    } else {
                        var operatorString = operator ? String(operator!) : "NUL"
                        var behavior = BehaviorTable[operatorString];
                        // Skip the operator
                        var skipCount = 0
                        if operator {
                            if expression[expression.startIndex] == "%" {
                                skipCount = 3
                            } else {
                                skipCount = 1
                            }
                        }
                        // Process varspec-list
                        var eError: URITemplateError? = nil
                        var estate = ExpressionState.ScanningVarName
                        var varName = ""
                        var modifier: Character?
                        var prefixLength :Int32 = 0
                        var str = expression[advance(expression.startIndex, skipCount)..<expression.endIndex]
                        str = str.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
                        var jIndex = 0
                        for (jIndex, j) in enumerate(str) {
                            if (estate == .ScanningVarName) {
                                if (j == "*" || j == ":") {
                                    if countElements(varName) == 0 {
                                        eError = .MalformedVarSpec
                                        break;
                                    }
                                    modifier = j
                                    estate = .ScanningModifier
                                }
                                if find(VARCHAR, j) || j == "." {
                                    varName += j
                                } else {
                                    eError = .MalformedVarSpec
                                    break;
                                }

                            } else if (estate == .ScanningModifier) {
                                if j == "," {
                                    // Process VarSpec
                                    // ...

                                    // Reset for next VarSpec
                                    eError = nil
                                    estate = .ScanningVarName
                                    varName = ""
                                    modifier = nil
                                    prefixLength = 0

                                } else {
                                    if modifier == "*" {
                                        eError = .MalformedVarSpec
                                        break;
                                    } else if modifier == ":" {
                                        if find(DIGIT, j) {
                                            prefixLength = prefixLength * 10 + String(j).bridgeToObjectiveC().intValue
                                            if prefixLength >= 1000 {
                                                eError = .MalformedVarSpec
                                                break;
                                            }

                                        } else {
                                            eError = .MalformedVarSpec
                                            break;
                                        }
                                    } else {
                                        assert(false);
                                    }
                                }

                            } else {
                                assert(false)
                            }
                        }

                        if eError {
                            syntaxErrors += (eError!, index + jIndex)
                            result = result + "{" + expression + "}"
                        } else {
                            // Process VarSpec
                        }
                    } // varspec-list

                } else {
                    expression += c;
                }

            default:
                assert(false)
            } // switch
        }// for

        // Handle ending
        var endingIndex = countElements(template)
        if state == .ScanningLiteral {
            if countElements(pctEncoded) > 0 {
                syntaxErrors += (URITemplateError.MalformedPctEncodedInLiteral, endingIndex)
                result = appendLiteralString(pctEncoded, result)
            }

        } else if (state == .ScanningExpression) {
            syntaxErrors += (URITemplateError.ExpressionEndedWithoutClosing, endingIndex)
            result = result + "{" + expression

        } else {
            assert(false);
        }
        if expressionCount == 0 {
            syntaxErrors += (URITemplateError.NonExpressionFound, endingIndex)
        }

        return (result, syntaxErrors)
    } // process

} // URITemplate
