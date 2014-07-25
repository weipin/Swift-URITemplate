//
//  URITemplate.swift
//  URITemplateTouch
//
//  Created by Weipin Xia on 7/20/14.
//  Copyright (c) 2014 Weipin Xia. All rights reserved.
//

import Foundation

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
        case U // any character not in the unreserved set will be encoded
        case UR // any character not in the union of (unreserved / reserved / pct-encoding) will be encoded
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
        func encodeLiteralCharacter(character: Character) -> String {
            if find(RESERVED, character) || find(UNRESERVED, character) {
                return String(character)
            }

            var str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                            String(character).bridgeToObjectiveC(), nil, nil,
                            CFStringBuiltInEncodings.UTF8.toRaw())
            return String(str)
        }

        func encodeLiteralString(string: String) -> String {
            var charactersToLeaveUnescaped = RESERVED + UNRESERVED
            var s = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                charactersToLeaveUnescaped.bridgeToObjectiveC(), nil, nil, CFStringBuiltInEncodings.UTF8.toRaw())
            var result = String(s)
            return result
        }

        func encodeStringWithBehaviorAllowSet(string: String, allow: BehaviorAllow) -> String {
            var result = ""

            if allow == .U {
                var s = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                    UNRESERVED.bridgeToObjectiveC(), nil, nil, CFStringBuiltInEncodings.UTF8.toRaw())
                result = String(s)

            } else if allow == .UR {
                result = encodeLiteralString(string)
            } else {
                assert(false)
            }

            return result
        }


        func stringOfAnyObject(object: AnyObject) -> String? {
            var str: String? = object as? String
            if !str {
                str = object.stringValue
            }
            return str
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

        func expandVarSpec(varName: String, modifier: Character?, prefixLength :Int,
        behavior: Behavior, values: AnyObject) -> String {
            var result = ""

            if varName == "" {
                return result
            }

            var value: AnyObject?
            if let d = values as? Dictionary<String, AnyObject> {
                value = d[varName]
            } else if let d = values as? NSDictionary {
                value = d.objectForKey(varName)
            } else {
                value = values.objectForKey?(varName)
            }

            if let str = stringOfAnyObject(value!) {
                if behavior.named {
                    result += encodeLiteralString(varName)
                    if str == "" {
                        result += behavior.ifemp
                        return result
                    } else {
                        result += "="
                    }
                }
                if modifier == ":" && prefixLength < countElements(str) {
                    var prefix = str[str.startIndex ..< advance(str.startIndex, prefixLength)]
                    result += encodeStringWithBehaviorAllowSet(prefix, behavior.allow)

                } else {
                    result += encodeStringWithBehaviorAllowSet(str, behavior.allow)
                }

            } else {
                if modifier == "*" {
                    if behavior.named {
                        if let ary = value as? [AnyObject] {
                            var count = 0
                            for v in ary {
                                var str = stringOfAnyObject(v)
                                if !str {
                                    continue
                                }
                                if count > 0 {
                                    result += behavior.sep
                                }
                                result += encodeLiteralString(varName)
                                if str! == "" {
                                    result += behavior.ifemp
                                } else {
                                    result += "="
                                    result += encodeStringWithBehaviorAllowSet(str!, behavior.allow)

                                }
                                ++count
                            }


                        } else if let dict = value as? Dictionary<String, AnyObject> {
                            var keys = Array(dict.keys)
                            keys = sorted(keys) {(s1: String, s2: String) -> Bool in
                                return s1.localizedCaseInsensitiveCompare(s2) == NSComparisonResult.OrderedAscending
                            }

                            var count = 0
                            for k in keys {
                                var str: String? = nil
                                if let v: AnyObject = dict[k] {
                                    str = stringOfAnyObject(v)
                                }
                                if !str {
                                    continue
                                }
                                if count > 0 {
                                    result += behavior.sep
                                }
                                result += encodeLiteralString(k)
                                if str == "" {
                                    result += behavior.ifemp
                                } else {
                                    result += "="
                                    result += encodeStringWithBehaviorAllowSet(str!, behavior.allow)
                                }
                                ++count
                            }

                        } else {
                            NSLog("Value for varName %@ is not a list or a pair", varName);
                        }

                    // end named
                    } else {
                        if let ary = value as? [AnyObject] {
                            var count = 0
                            for v in ary {
                                var str = stringOfAnyObject(v)
                                if !str {
                                    continue
                                }
                                if count > 0 {
                                    result += ","
                                }
                                result += encodeStringWithBehaviorAllowSet(str!, behavior.allow)
                                ++count
                            }

                        } else if let dict = value as? Dictionary<String, AnyObject> {
                            var keys = Array(dict.keys)
                            keys = sorted(keys) {(s1: String, s2: String) -> Bool in
                                return s1.localizedCaseInsensitiveCompare(s2) == NSComparisonResult.OrderedAscending
                            }

                            var count = 0
                            for k in keys {
                                var str: String? = nil
                                if let v: AnyObject = dict[k] {
                                    str = stringOfAnyObject(v)
                                }
                                if !str {
                                    continue
                                }
                                if count > 0 {
                                    result += ","
                                }
                                result += encodeLiteralString(k)
                                result += "="
                                result += encodeStringWithBehaviorAllowSet(str!, behavior.allow)
                                ++count
                            }

                        } else {
                            NSLog("Value for varName %@ is not a list or a pair", varName);
                        }
                    // end !named
                    }
                } else {

                }

            }
            return result
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
                            result += encodeLiteralString(pctEncoded)
                            result += encodeLiteralCharacter(c)
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
                            result += encodeLiteralString(pctEncoded)
                            result += encodeLiteralCharacter(c)
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
                        var behavior = BehaviorTable[operatorString]!;
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
                        var varCount = 0
                        var eError: URITemplateError? = nil
                        var estate = ExpressionState.ScanningVarName
                        var varName = ""
                        var modifier: Character?
                        var prefixLength :Int = 0
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
                                    if varCount == 0 {
                                        result += behavior.first
                                    } else {
                                        result += behavior.sep
                                    }
                                    var expanded = expandVarSpec(varName, modifier, prefixLength, behavior, values)
                                    result += expanded
                                    ++varCount

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
                                            prefixLength = prefixLength * 10 + Int(String(j).bridgeToObjectiveC().intValue)
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
                        } // for expression

                        if eError {
                            syntaxErrors += (eError!, index + jIndex)
                            let remainingExpression = str[advance(str.startIndex, jIndex)..<str.endIndex]
                            if operator {
                                result = result + "{" + operator! + remainingExpression + "}"
                            } else {
                                result = result + "{" + remainingExpression + "}"
                            }

                        } else {
                            // Process VarSpec
                            if varCount == 0 {
                                result += behavior.first
                            } else {
                                result += behavior.sep
                            }
                            var expanded = expandVarSpec(varName, modifier, prefixLength, behavior, values)
                            result += expanded
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
                result += encodeLiteralString(pctEncoded)
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
