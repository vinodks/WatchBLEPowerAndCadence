//
//  DebugModul.swift

//  Debugging Features
//      this class will be instantiated one time and used by all Controllers/Objects
//  Created by RH-Sports, 2018

import Foundation
import WatchKit

// debug level
enum DebugLevels: Int {
    case DISABLED_LEVEL = 0                                 // report nothing
    case LOW_DEBUG_LEVEL                                    // only report errors
    case MEDIUM_DEBUG_LEVEL                                 // report warnings and errors
    case HIGHEST_DEBUG_LEVEL                                // report all
}

// class to handle global debug data
class GlobalDebugData {
    private var nDebugLevel: Int = DebugLevels.DISABLED_LEVEL.rawValue
    private var strMessageText1 : String = ""
    private var strMessageText2 : String = ""
    private var strMessageText3 : String = ""
    private var strMessageText4 : String = ""
    private var strMessageArray: [String] = []
    public var bSpeakSpeedChange : Bool = false
    public var bSwimFuctionality : Bool = true {
        didSet {
            //setSwimmimgMode(mode: bSwimFuctionality)
        }
    }
    
    public var bSpeakSwimTest : Bool = false
    public var bLapRunSportTest : Bool = true {
        didSet {
            //setRunSportLapViewMode(mode: bLapRunSportTest)
        }
    }
    
    
    public var bCadenceEnable: Bool = true {
        didSet {
            //setCadenceMode(mode: bCadenceEnable)
        }
    }

    // constructor
    init() {
        //setSwimmimgMode(mode: bSwimFuctionality)
        //setRunSportLapViewMode(mode: bLapRunSportTest)
        //setCadenceMode(mode: bCadenceEnable)
//        if let mode = getSwimmimgMode() {
//            bSwimFuctionality = mode
//        }
//
//        if let isLapRunMode = getRunSportLapViewMode() {
//            bLapRunSportTest = isLapRunMode
//        }
    }
    

    private func updateMessageText(newMessage: String) {
        let gregorian = Calendar(identifier: .gregorian)
        let now = Date()
        let components = gregorian.dateComponents([.hour, .minute, .second], from: now)
        let today = gregorian.date(from: components)!
        let dateFormater: DateFormatter = DateFormatter()
        
        dateFormater.dateFormat = "hh:mm:ss"
        let timeStamp = dateFormater.string(from: today)
        
        strMessageText4 = strMessageText3
        strMessageText3 = strMessageText2
        strMessageText2 = strMessageText1
        strMessageText1 = timeStamp + ": " + newMessage
        self.addDataInArray(newMessage)
    }
    
    public func getDebugLevel() -> Int {
        return nDebugLevel
    }

    public func setDebugLevel(level : Int) {
        nDebugLevel = level
    }
    
    public func addDataInArray(_ str: String) {
        if strMessageArray.count >= 3 {
            strMessageArray.removeFirst()
        }
        strMessageArray.append(str)
        if strMessageArray.count > 0 {
            self.saveMessageInUserDefault()
        }
    }
    
    private func saveMessageInUserDefault() {
        //setDebugMessageArray(array: strMessageArray)
    }
    
    public func showDebugInfo() {
       //DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
//        WKExtension.shared().visibleInterfaceController?.presentController(withName: LastMessageInterfaceController.className, context: nil)
//        })
      
    }
    
    public func showInfoMsg(_ items: Any...) {
        Swift.print(items)

        if (nDebugLevel >= DebugLevels.HIGHEST_DEBUG_LEVEL.rawValue) {
            let lastMessageText = items.map { "\($0)" }.joined(separator: " ")

            updateMessageText(newMessage: lastMessageText)

//            if (globalVarsInstance.debug_logging_enabled) {
//                WorkoutLoggingManager.shared.addDebugMessageInLog(msg: lastMessageText)
//            }
        }
    }

    public func showWarningMsg(_ items: Any...) {
        Swift.print(items)
        if (nDebugLevel >= DebugLevels.MEDIUM_DEBUG_LEVEL.rawValue) {
            let lastMessageText = items.map { "\($0)" }.joined(separator: " ")
            updateMessageText(newMessage: lastMessageText)
            //gTextToSpeechInstance.speakText(strText: lastMessageText)
            
//            if (globalVarsInstance.debug_logging_enabled) {
//                WorkoutLoggingManager.shared.addDebugMessageInLog(msg: lastMessageText)
//            }
        }
    }

    public func showErrorMsg(_ items: Any...) {
        //Swift.print(items)
        
        if (nDebugLevel >= DebugLevels.LOW_DEBUG_LEVEL.rawValue) {
            let lastMessageText = items.map { "\($0)" }.joined(separator: " ")
            
            updateMessageText(newMessage: lastMessageText)
            //gTextToSpeechInstance.speakText(strText: lastMessageText)
            
//            if (globalVarsInstance.debug_logging_enabled) {
//                WorkoutLoggingManager.shared.addDebugMessageInLog(msg: lastMessageText)
//            }
        }
    }

    public func getLastMessageText(index: Int) -> String {
        switch (index) {
            case 1: return strMessageText1
            case 2: return strMessageText2
            case 3: return strMessageText3
            case 4: return strMessageText4
            default: break;
        }
        return "ERROR"
    }

    // get/set debug checkpoint functions
    public func setCheckPoint(checkPoint: String) {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        
        if (checkPoint.contains("undefined")) {
            defaults?.set("", forKey: "debug_checkPoint")
        } else {
            defaults?.set(checkPoint, forKey: "debug_checkPoint")
        }
    }
    public func getCheckPoint() -> String {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        
        if let checkPoint = defaults?.string(forKey: "debug_checkPoint") {
            if (checkPoint != "") {
                return checkPoint
            }
        }
        return ""
    }
}


// one and only global vars instance
var globalDebugDataInstance = GlobalDebugData()
