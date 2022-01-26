//
//  GlobalVars.swift
//  Utility file for AW Extension
//      this class will be instantiated one time and used by all Controllers/Objects
//  Created by RH-Sports, 2017

import Foundation
import WatchKit
import CoreMotion

// watc type (for special GUI adaptions)
enum WatchType: Int {
    case WATCH_TYPE_38mm = 0
    case WATCH_TYPE_40mm
    case WATCH_TYPE_42mm
    case WATCH_TYPE_44mm
}

enum ApplicationState: Int {
    case finishLauncing
    case becomeActive
    case resignActive
    case enterBackground
    case enterForegroud
}

// This is a gneric reference class can be used for any type of Object
class Ref<T>{
    var value : T
    init(_ value: T){
        self.value = value
    }
}

//class GlobalVars {
//    public var      applicationInForeground : Bool = true // app starts in foreground
//    public var      IsAuthenticated : Bool = false // starts with-out auth
//    public var      splashScreenTransitionDidHappen : Bool = false
//    public var      lastAutoSyncCall : Date? // remember lastAutoSyncCall to impelment cool down (avoid endless loop if failing)
//    public var      triggerAutoSyncAfterSuccessfulTrainingExecution : Bool = false
//    public var      debug_logging_enabled : Bool = true
//    public var      eWatchType: Int = WatchType.WATCH_TYPE_38mm.rawValue
//    public var      workoutFilesUploadOngoing : Bool = false
//    // this variable is set if workout is saved/canceled and avoids further actions by the user until startupIFController is loaded
//    public var      workoutFinished : Bool = false
//    public var      isUserOnLapview: Bool = false
//    public var      applicationStatusArray: [ApplicationState] = []
//
//
//    public var siriBtnInterfaceControllerRef : WKInterfaceController? = nil
//
//    // constructor
//    init() {
//    }
//
//    // set current date as time stamp for last synchronization
//    public func setLastSyncInfoTimeStamp() {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//        let dateFormatter = DateFormatter()
//        let now = Date()
//
//        dateFormatter.dateFormat = "yyyy-MM-dd'_'HH:mm:ss"
//        let dateString = dateFormatter.string(from: now)
//
//        defaults?.set(dateString, forKey: "last_sync_info")
//    }
//    // get time stamp of last synchronization
//    public func getLastSyncInfoTimeStamp() -> String {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//
//        // get time stamp from store
//        if let lastSyncInfo = defaults?.string(forKey: "last_sync_info") {
//            if (lastSyncInfo != "") {
//                return lastSyncInfo
//            }
//        }
//        return ""
//    }
//
//    // set time stamp of demo download
//    public func setDemoDownloadTimeStamp() {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//        let gregorian = Calendar(identifier: .gregorian)
//        let now = Date()
//        let components = gregorian.dateComponents([.year, .month, .day], from: now)
//        let today = gregorian.date(from: components)!
//        let dateFormater: DateFormatter = DateFormatter()
//
//        dateFormater.dateFormat = "yyyy-MM-dd"
//        let timeStamp = dateFormater.string(from: today)
//
//        defaults?.set(timeStamp, forKey: "demo_workout_download_time_stamp")
//    }
//    // clear time stamp of demo download
//    public func clearDemoDownloadTimeStamp() {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//
//        defaults?.set("", forKey: "demo_workout_download_time_stamp")
//    }
//    // get time stamp of demo download
//    public func getDemoDownloadTimeStamp() -> String {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//
//        // get time stamp from store
//        if let timeStamp = defaults?.string(forKey: "demo_workout_download_time_stamp") {
//            if ("" != timeStamp) {
//                return timeStamp
//            }
//        }
//        return ""
//    }
//
//    public func addApplicationStatus(_ status: ApplicationState) {
//        if applicationStatusArray.count > 2 {
//            applicationStatusArray.removeFirst()
//        }
//        applicationStatusArray.append(status)
//    }
//
//    func checkWhetherDeviceToBeWaterUnLocked() {
//         if globalVarsInstance.applicationInForeground {
//             if globalWorkoutDataInstance.isDeviceWaterLocked {
//                print(globalVarsInstance.applicationStatusArray.debugDescription)
//                 if let lastObj = globalVarsInstance.applicationStatusArray.last, globalVarsInstance.applicationStatusArray.count > 1 {
//                     let secondLastObj = globalVarsInstance.applicationStatusArray[1]
//                     if lastObj == .becomeActive && secondLastObj == .resignActive {
//                        globalWorkoutDataInstance.isDeviceWaterLocked = false
//                        print("DEVICE IS UNLOCKED")
//                     }
//                 }
//             }
//         }
//     }
//}
//
//// class to handle all user-related data
//class GlobalUserData {
//    // constructor
//    init() {
//    }
//
//    public var isAppleSignedIn: Bool = false
//
//    // user name get/set functions
//    public func setUserName(userName: String) {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//        if (userName.contains("undefined")) {
//            defaults?.set("", forKey: "user_name")
//        } else {
//            defaults?.set(userName, forKey: "user_name")
//        }
//    }
//    public func getUserName() -> String {
//        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
//
//        if let user_name = defaults?.string(forKey: "user_name") {
//            if (user_name != "") {
//                return user_name
//            }
//        }
//        return ""
//    }
//
//    public func logoutUser(isForced: Bool = false, message: String = "Token expired"){
//        self.resetValues()
//        if isForced {
//            if let controller = WKExtension.shared().visibleInterfaceController {
//              self.showAlertOnForceLogout(message, controller)
//            } else {
//                self.showSplashController()
//            }
//            return
//        }
//        self.showSplashController()
//    }
//
//    func showSplashController() {
//        DispatchQueue.main.async {
//                   // this has to be done in main thread
//                       WKInterfaceController.reloadRootPageControllers(withNames: ["splashScreen"],
//                       contexts: nil,
//                       orientation: .horizontal,
//                       pageIndex: 0)
//               }
//    }
//
//    func showAlertOnForceLogout(_ text: String ,_ interface: WKInterfaceController) {
//        let h1 = {
//            self.showSplashController()
//        }
//        let action2 = WKAlertAction(title: NSLocalizedString("Ok", comment: "Continue"), style: .default, handler:h1)
//        interface.presentAlert(withTitle: NSLocalizedString("Plan2PEAK", comment: ""),
//                          message: text,
//                          preferredStyle: .alert,
//                          actions: [action2])
//    }
//
//    public func resetValues() {
//            setAppleUserName(value: nil)
//               setTokenExpirationTime(value: 0)
//               setDefaultToken(value: nil)
//               setRefreshToken(value: nil)
//                globalVarsInstance.splashScreenTransitionDidHappen = false
//               globalUserDataInstance.setUserName(userName: "")
//        setStandaloneMode(mode: false)
//    }
//}
//


// class to handle all workout-related data
class GlobalWorkoutData {
    private var workoutType : String = ""
    private var workoutDuration : Int  = 0
    private var workoutSteps : Int = 0
    private var workoutIntervals : Int = 0
    private var workoutIntervalsCompleted : Int = 0
    private var workoutSummaryFile : String = ""
    private var workoutFile : String = ""
   // private var workoutLocationType: LocationType = .indoor
    //public  var workoutTargetTrainingType : SupportedWorkoutTargetType = .noTargetType
    public  var showImperialUnits : Bool = false
    public  var isWorkoutRunning : Bool = false
    public  var isWorkoutPaused  : Bool = false
    public  var freeTrainingSelected : Bool = false
    //public  var freeTrainingWorkoutType : FreeTrainingSelectableWorkoutTypes
    public  var demoWorkoutTypeString : String = ""
    //public  var guideTimeIntervalSetting: TimeBarValue = .twoMin
    public  var isDeviceWaterLocked: Bool = false
    public  var isVolumePopupShown: Bool = false
    var currentPower : Ref<Double> = Ref<Double>(0)
    var cyclingCadence: Ref<Double> = Ref<Double>(0)


    // constructor
    init() {
        //freeTrainingWorkoutType = FreeTrainingSelectableWorkoutTypes.Other
        //if let interval =  getDefaultForVoiceGuidance() {
           // guideTimeIntervalSetting = interval
       // }
    }

    // reset global workout data (shall be called at the beginning of a workout)
    public func resetWorkoutData() {
        self.workoutSteps = 0
        self.workoutIntervals = 0
        self.workoutIntervalsCompleted = 0
       // self.workoutLocationType = .indoor
    }

    
    // workout type get/set functions
    // Type e.g.: running, cycling, boxing..
    public func setWorkoutType(workoutType: String) {
        self.workoutType = workoutType
    }
    public func getWorkoutType() -> String? {
        return workoutType
    }

    // workout duration get/set functions
    public func setWorkoutDuration(newValue: Int) {
        self.workoutDuration = newValue
    }
    public func getWorkoutDuration() -> Int {
        return self.workoutDuration
    }

    // workout steps get/set functions
    public func setWorkoutSteps(newValue: Int) {
        self.workoutSteps = newValue
    }
    public func getWorkoutSteps() -> Int {
        return self.workoutSteps
    }

    // workout interval functions
    public func setWorkoutIntervals(newValue: Int) {
        self.workoutIntervals = newValue
    }
    public func getWorkoutIntervals() -> Int {
        return self.workoutIntervals
    }
    public func incWorkoutIntervalCompleted() {
        self.workoutIntervalsCompleted += 1
    }
    public func getWorkoutIntervalsCompleted() -> Int {
        return self.workoutIntervalsCompleted
    }

    // workout summary file get/set functions
    public func getWorkoutSummaryFile() -> String {
        return self.workoutSummaryFile
    }
    public func setWorkoutSummaryFile(workoutSummaryFile: String) {
        self.workoutSummaryFile = workoutSummaryFile
    }

    // workout file get/set functions
    public func setWorkoutFile(workoutFile: String) {
        self.workoutFile = workoutFile
    }
    public func getWorkoutFile() -> String {
        return self.workoutFile
    }

//    // workout location type get/set functions
//    public func setWorkoutLocationType(workoutLocationType: LocationType) {
//        self.workoutLocationType = workoutLocationType
//    }
//
//    public func getWorkoutLocationType() -> LocationType {
//        return self.workoutLocationType
//    }
//
//    public func isSpeedBasedTraining() -> Bool {
//        return (workoutTargetTrainingType == .speedTargetType)
//    }
//
//    public func isHeartRateBasedTraining() -> Bool {
//        return (workoutTargetTrainingType == .hrTargetType)
//    }
//
//    public func isPaceBasedTraining() -> Bool {
//        return (workoutTargetTrainingType == .paceTargetType)
//    }
//
//    public func isPowerBasedTraining() -> Bool {
//        return (workoutTargetTrainingType == .powerTargetType)
//    }
//
//    public func wktHasNoGuidance() -> Bool {
//        return (workoutTargetTrainingType == .noTargetType)
//    }
    
    public func isCandanceAvailable() -> Bool {
        return CMPedometer.isCadenceAvailable()
    }
    
    public func isCyclingCandanceAvailable() -> Bool {
        return true
    }
    
//    public func isWorkoutHavingLap() -> Bool {
//        if let workoutType = globalWorkoutDataInstance.getWorkoutType(), isRunningSportlapView() {
//             switch (workoutType) {
//                // (running, treadmill, orienteering, long running and trail running
//             case "Running", "LongRunning", "Orienteering","TrailRunning","Treadmill":
//                 return true
//             default:
//                 return false
//             }
//         }
//        return false
//    }
    
    
//    public func isRunningSportlapView() -> Bool {
//        return globalDebugDataInstance.bLapRunSportTest
//    }
    
//    public func isSwimmingWorkoutEnabled() -> Bool {
//        if !isDeviceSupportingSwimming() {
//            return false
//        }
//        return globalDebugDataInstance.bSwimFuctionality
//    }
    private func isDeviceSupportingSwimming() -> Bool {
        let isSupporting = WKInterfaceDevice.current().waterResistanceRating
        switch isSupporting {
        case .ipx7:
            return false
        case .wr50:
            return true
        
        }
    }
    
    public func isSwimmimgWorkout() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType(), workoutType == "Swimming" {
            return true
        }
        return false
    }
    
    public func doWorkoutNeedGPSData() -> Bool {
        if isSwimmimgWorkout() {
            return false
        }
        
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            if workoutType == "Treadmill" {
                return false
            }
        }
    
        return true
    }
    
    public func isOnlyIndoorActivity() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            if workoutType == "Treadmill" {
                return true
            }
        }
    
        return false
    }
    
    
    public func isAlreadyIndoorActivity() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            if workoutType == "IndoorCycling" {
                return true
            }
        }
    
        return false
    }
    
    
    public func isAlreadyOutdoorActivity() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            if workoutType == "Cycling" {
                return true
            }
        }
    
        return false
    }
    
    
    public func isCadenceApplicable() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            switch (workoutType) {
            case "Running", "LongRunning", "Orienteering","TrailRunning","AlpineHiking", "NordicWalking","Treadmill":
                return isCandanceAvailable()
            default:
                return false
            }
        }
        return false
    }
    
    
    public func isCyclingCadenceApplicable() -> Bool {
        if let workoutType = globalWorkoutDataInstance.getWorkoutType() {
            switch (workoutType) {
            case "Cycling","LongCycling","IndoorCycling":
                return isCyclingCandanceAvailable()
            default:
                return false
            }
        }
        return false
    }
    
    func getCadenceMode() -> Bool? {
        
        return true
    }
    
    // ----------------------------------------------------------------------------------------
    //               Functions for extracting info from JSON Workout File
    // ----------------------------------------------------------------------------------------

    // return workout step limit for
    //  lower limit
    //  average limit
    //  maximum limit
//    public func getWorkoutStepLimit(step: [String:Any]) -> (Double, Double, Double) {
//        var lowerLimit : Double = 0.0
//        var averageLimit : Double = 0.0
//        var upperLimit : Double = 0.0
//
//        if let targetZones : [String:Double] = step["targetZones"] as? [String:Double] {
//            switch globalWorkoutDataInstance.workoutTargetTrainingType {
//            case .hrTargetType:
//                lowerLimit = Double(truncating: targetZones["pulse_min"] as NSNumber? ?? 0)
//                upperLimit = Double(truncating: targetZones["pulse_max"] as NSNumber? ?? 0)
//                averageLimit = (lowerLimit + upperLimit) / 2
//            case .speedTargetType, .paceTargetType:
//                lowerLimit = Double(truncating: targetZones["speed_min"] as NSNumber? ?? 0)
//                upperLimit = Double(truncating: targetZones["speed_max"] as NSNumber? ?? 0)
//                averageLimit = (lowerLimit + upperLimit) / 2
//            case .powerTargetType:
//                lowerLimit = Double(truncating: targetZones["power_min"] as NSNumber? ?? 0)
//                upperLimit = Double(truncating: targetZones["power_max"] as NSNumber? ?? 0)
//                averageLimit = (lowerLimit + upperLimit) / 2
//            default:
//                averageLimit = 0.0
//            }
//        }
//        return (lowerLimit, averageLimit, upperLimit)
//    }

    
    // TargetType: workout target pre-selection by Gosia -> e.g this is a hr workout
    // SupportedWorkoutTargetType: what is available in json file
//    public func getWorkoutTargetType() -> (TargetType,[SupportedWorkoutTargetType]) {
//        // read data for workout file
//        let file = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.plan2peak.com.aw.jsonData")?.appendingPathComponent(globalWorkoutDataInstance.getWorkoutFile())
//        var supportedTargetZones:[SupportedWorkoutTargetType] = []
//
//        do {
//            let data = try Data(contentsOf: (file?.absoluteURL)!)
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            if let workoutData = json as? [String: Any] {
//                if let steps = workoutData["steps"] as? [[String: Any]] {
//                    //todo warning in case of no steps defined
//                    if steps.count == 0 {
//                        return (.invalid, supportedTargetZones)
//                    }
//                    let targetType = TargetType(stepTargetJsonType: steps.first!["target_type"] as? NSNumber ?? 255)
//                    if let targetZones : [String:Double] = steps.first!["targetZones"] as? [String:Double] {
//                        if (targetZones["speed_min"] != 0) && (targetZones["speed_max"] != 0) {
//                            supportedTargetZones.append(.speedTargetType)
//                            supportedTargetZones.append(.paceTargetType)
//                        }
//                        if (targetZones["pulse_min"] != 0) && (targetZones["pulse_max"] != 0) {
//                            supportedTargetZones.append(.hrTargetType)
//                        }
//                        // if power values are available and BT power peripheral is registered
//                        if (targetZones["power_min"] != 0) && (targetZones["power_max"] != 0) && BTManager.shared.isPeripheralRegistered() {
//                            supportedTargetZones.append(.powerTargetType)
//                        }
//                        return (targetType, supportedTargetZones)
//                    } else {
//                        return (targetType, supportedTargetZones)
//                    }
//                }
//            }
//        } catch {
//            return (.invalid, supportedTargetZones)
//        }
//        return (.invalid, supportedTargetZones)
//    }
    
    // return the following info about next interval:
    // - interval step (Int)
    // - interval zone (Int)
    // - interval value (Double)
    // - interval start time from given step in seconds (Double)
    // - interval duration (Double)
//    public func getNextIntervalInfo(currentStep: Int) -> (Int, Int, Double, Double, Double) {
//        var intervalZone : Int = 0
//        var intervalValue: Double = 0.0
//        var intervalNextDuration : Double = 0.0
//        var intervalDuration: Double = 0.0
//
//        // read data for workout file
//        let file = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.plan2peak.com.aw.jsonData")?.appendingPathComponent(globalWorkoutDataInstance.getWorkoutFile())
//
//        do {
//            let data = try Data(contentsOf: (file?.absoluteURL)!)
//            let json = try JSONSerialization.jsonObject(with: data, options: [])
//            if let workoutData = json as? [String: Any] {
//                if let steps = workoutData["steps"] as? [[String: Any]] {
//                    if (currentStep > steps.count) {
//                        // no step available anymore
//                        return (-1, 0, 0.0, 0.0, 0.0)
//                    }
//
//                    var i : Int = 0
//                    for step in steps {
//                        if (i > currentStep) {
//                            if  let wkt_step_name = step["wkt_step_name"] as? NSString,
//                                let duration_value = step["duration_value"] as? NSNumber {
//
//                                intervalDuration = Double(truncating: step["duration_value"] as? NSNumber ?? 0) / 1000
//                                print("Interval duration  \(intervalDuration)")
//                                // check if it is an interval?
//                                intervalZone = getIntervalZone(wkt_step_name: step["wkt_step_name"] as? String ?? "")
//                                if (2 < intervalZone) {
//                                    // new interval found --> get limit and return
//                                    (_, intervalValue,_) = getWorkoutStepLimit(step: step)
//                                    return (i, intervalZone, intervalValue, intervalNextDuration, intervalDuration)
//                                }
//                                // no interval, add duration
//                                intervalNextDuration += intervalDuration
//                            }
//                        }
//                        i += 1
//                    } // end for step in steps
//                }
//            }
//        } catch {
//            return (-1, 0, 0.0, 0.0, 0.0)
//        }
//        return (-1, 0, 0.0, 0.0, 0.0)
//    }
}

// one and only global vars instance
//var globalVarsInstance = GlobalVars()
//var globalUserDataInstance = GlobalUserData()
var globalWorkoutDataInstance = GlobalWorkoutData()
    
    
