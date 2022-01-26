
//
//  Helper.swift
//  TestSwift
//
//  Created by Devendra Narain on 12/30/14.
//  Copyright (c) 2018 HDVI. All rights reserved.
//

import UIKit


func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafePointer(to: &i) {
            $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}

public func allValues<T: Hashable>(_:T.Type) -> Array<T> {
    var allValues = [T]()
    let iterator = iterateEnum(T.self)
    for item in iterator {
        allValues.append(item)
    }
    return allValues
}

class Helper: NSObject {
   static let encryptKey = "rkMiLW1hVG9FrPpLHi7111DH9KhYVDbN"
   
    
    class func GetPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true) 
        return paths.first!
    }
    
    class func getDataArray(jsonString: String) -> [[String: AnyObject]]? {
        
        // convert String to NSData
        let data: NSData = jsonString.data(using: String.Encoding.utf8)! as NSData
        do {
            // convert NSData to 'AnyObject'
            let jsonObject = try JSONSerialization.jsonObject(with: data as Data, options: [])
            if let jsonObject = jsonObject as? [[String: AnyObject]] {
                /*
                if let graphData = jsonObject["Data"] as? [[String: AnyObject]] {
                    for graphModelDict in graphData {
                        let graphModel = GraphModel(data: graphModelDict)
                        graphObjectArray.append(graphModel)
                    }
                }
 */
                return jsonObject
            }
            
        } catch {
            let encodingError = error as NSError
            print("Error could not parse JSON: \(encodingError)")
        }
        return nil
    }
    
    class func getDictonaryData(jsonString: String) -> [String: AnyObject]? {
        // convert String to NSData
        let data: NSData = jsonString.data(using: String.Encoding.utf8)! as NSData
        do {
            // convert NSData to 'AnyObject'
            let jsonObject = try JSONSerialization.jsonObject(with: data as Data, options: [])
            if let jsonObject = jsonObject as? [String: AnyObject]{
                return jsonObject
            }
        } catch {
            let encodingError = error as NSError
            print("Error could not parse JSON: \(encodingError)")
        }
        return nil
    }
    
    
    
   
    
    class func stringToDateStringFormat(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "MM/dd/yyyy @ hh:mm a"
            dateFormatter.timeZone = TimeZone.current
            let str = dateFormatter.string(from: date)
            return str
        }
        return ""
    }
    
    
    class func stringToDateStringForNotificationFormat(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "MM/dd/yyyy @ hh:mm a"
            dateFormatter.timeZone = TimeZone.current
            let str = dateFormatter.string(from: date)
            return str
        }
        return ""
    }
    
    class func dateFromStringForNotificationFormat(date: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = dateFormatter.date(from: date) {
            dateFormatter.timeZone = TimeZone.current
            let str = dateFormatter.string(from: date)
            return dateFormatter.date(from:str)
        }
        return nil
    }
    
    
    class func stringToDateExcludingDateStringFormat(date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = dateFormatter.date(from: date) {
            dateFormatter.dateFormat = "MM/dd/yyyy"
            dateFormatter.timeZone = TimeZone.current
            let str = dateFormatter.string(from: date)
            return str
        }
        return ""
    }
    
    class func stringFromDateServerEndFormatter (date : Date, inUTC: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        if inUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        //2018-01-24T17:18:00
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    class func stringForNotesDateServerEndFormatter (date : Date, inUTC: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        if inUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    class func dateFromStringServerEndFormatter (string : String, inUTC: Bool = false) -> Date {
        let dateFormatter = DateFormatter()
        if inUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
        } else {
            dateFormatter.timeZone = TimeZone.current
        }
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.date(from: string) ??  Date()
    }
    
    class func stringify(json: Any, prettyPrinted: Bool = false) -> String {
        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options = JSONSerialization.WritingOptions.prettyPrinted
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: options)
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                return string
            }
        } catch {
            print(error)
        }
        return ""
    }
    
    class func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    class func getRandomColor() -> UIColor {
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    
    
    class func addUnderLineToText(_ text: String) -> NSAttributedString {
        let underlineAttribute = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        let underlineAttributedString = NSAttributedString(string: "\(text)", attributes: underlineAttribute)
        return underlineAttributedString
    }
    
   
    
    class func changeRequestToString(_ parameters: [String: Any]? = nil) -> NSString? {
        do {
            if let requestParameter = parameters {
                let jsonData = try JSONSerialization.data(withJSONObject: requestParameter , options: JSONSerialization.WritingOptions.prettyPrinted)
                let jsonRequest = NSString(data: jsonData,
                                           encoding: String.Encoding.utf8.rawValue)
                return jsonRequest
            }
        } catch let error as NSError {
            print(error)
        }
        return ""
    }
    
    class func bitsArray(fromByte byte: UInt8) -> [Bit] {
        var byte = byte
        var bits = [Bit](repeating: .zero, count: 8)
        for i in 0..<8 {
            let currentBit = byte & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }
            byte >>= 1
        }
        
        return bits
    }
    
}

