//
//  BTManager.swift
//  Plan2PEAK_AW Extension
//
//  Created by Christian on 26.06.18.
//

import Foundation
import CoreBluetooth

struct  ExtPeripheral {
    var name:String
    var manufacturaName:String
    var lastRSSI:NSNumber
    var peripheral:CBPeripheral
}

private enum BlueToothGATTServices: UInt16 {
    case BatteryService         = 0x180F
    case DeviceInformation      = 0x180A
    case HeartRate              = 0x180D
    case CyclingPower           = 0x1818
    case CyclingSpeedandCadence = 0x1816
    case RunningSpeedandCadence = 0x1814
    case ManufacturaNameString  = 0x2A29
    
    var UUID: CBUUID {
        return CBUUID(string: String(self.rawValue, radix: 16, uppercase: true))
    }
}


enum Bit: UInt8, CustomStringConvertible {
    case zero, one

    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}

/* maybe later this will be a struct, currently we only have one value - pwr
struct PowerValue {
    let power:Int
    let intensity:Int?
}*/


// which servises to look for -> currently only Cycling Power
let supportedServicesWeAreInterestedIn = [
    BlueToothGATTServices.CyclingPower.UUID, BlueToothGATTServices.CyclingSpeedandCadence.UUID
]

class BTManager :  NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals:[ExtPeripheral]?
    private var isScanning = false
    private var powerMonitor: CBPeripheral?
    //private var sensors : [CBPeripheral] = []
    private var onlyConnectWithoutDataAccess = false
    private var stopConnectionRequestTimer : Timer?
    private var activePeripherals = Dictionary<String,ExtPeripheral>()
    var updatePowerValue: ((_ pwr:Double)->())?
    let timeScale              = 1024.0
    var lastMeasurement:Measurement?
    static let DefaultWheelSize:UInt32   = 2170
    // todo check if i need below ?
    //var updateMessage: ((_ msg:String)->())?
    //var updateStopScan: (()->())?

    //.. end todo
    
    var updateConnectionStatus: ((_ peripheralState:CBPeripheralState)->())?
    var updateList: ((_ list:[ExtPeripheral])->())?
    
    func getConnectionStatusOfPowerSensor() -> CBPeripheralState?
    {
        return powerMonitor?.state
    }
    
    func getServiceStatusOfPowerSensor() -> Bool
    {
        return powerMonitor?.services != nil
    }
    
    func getPowerSensorImageName() -> String
    {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        if let manufacturaString = defaults?.string(forKey: "manufacturaName") {
            if manufacturaString == "Stryd" {
                return "BT_StrydDevice"
            }
        }
        return "BT_PowerSensor"
    }
    
    func getListOfConnectedPeripherals() -> [String:ExtPeripheral] {
        let services = [BlueToothGATTServices.DeviceInformation.UUID]
        let conDev = self.centralManager.retrieveConnectedPeripherals(withServices:  services)
        conDev.forEach{ item in
            let identifier = item.identifier.uuidString
            if activePeripherals[identifier] == nil {  // ask if already existing
                activePeripherals[identifier] = ExtPeripheral(name: item.name ?? "", manufacturaName : "", lastRSSI: 0, peripheral: item)
            }
        }
        return activePeripherals
    }
    
    static let shared = BTManager()
    private override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        activePeripherals = [:]
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // scanning peripherals
    ////////////////////////////////////////////////////////////////////////////////////////
    
    // functions supported here
    public func startScanForDevices() {
        //globalDebugDataInstance.showInfoMsg("BTManager: startScanning for devices")
        
        self.discoveredPeripherals = []
        self.isScanning = true
        self.updateList?(self.discoveredPeripherals!)

        
        //check to be in power on state
        if (centralManager.state==CBManagerState.poweredOn) {
            centralManager.scanForPeripherals(withServices:supportedServicesWeAreInterestedIn, options: nil)
            //centralManager.scanForPeripherals(withServices:nil, options: nil)
        }  else {
            // wait 2 seconds and try again
            // todo check if this is needed
            let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                self.centralManager.scanForPeripherals(withServices:supportedServicesWeAreInterestedIn, options: nil)
            }
        }
    }
    
    public func stopScanning() {
        globalDebugDataInstance.showInfoMsg("BTManager: stop scanning for devices")
        if (self.isScanning) {
            self.isScanning = false
            self.centralManager.stopScan()
        }
    }
    
    // delegate function called if peripheral is discovered by scan process
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        globalDebugDataInstance.showInfoMsg("BTManager: didDiscover peripheral")
        
        for (index, foundPeripheral) in discoveredPeripherals!.enumerated(){
            if foundPeripheral.peripheral.identifier == peripheral.identifier{
                discoveredPeripherals![index].lastRSSI = RSSI
                return
            }
        }
        
        let sensorName:String
        if let localName:String = advertisementData[CBAdvertisementDataLocalNameKey] as! String? {
            sensorName = localName
        } else if let localName:String = peripheral.name{
            sensorName = localName
        } else {
            sensorName = "No Device Name"
        }
        
        let displayPeripheral:ExtPeripheral = ExtPeripheral(name: sensorName, manufacturaName : "", lastRSSI: RSSI, peripheral: peripheral)
        discoveredPeripherals!.append(displayPeripheral)
        self.updateList?(self.discoveredPeripherals!)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Search for peripherals with known/unknwon UUID
    ////////////////////////////////////////////////////////////////////////////////////////
    public func connectToPowerSensorAndRetrieveData() {
        guard isPeripheralRegistered() else {return }
        
        self.onlyConnectWithoutDataAccess = false
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        let peripheralUUID = defaults?.string(forKey: "activeBtPeripheralUUID")
        
        if (peripheralUUID != nil) {
            if let peripheralUUID = peripheralUUID {
                //globalDebugDataInstance.showInfoMsg("BTManager: connect to registered uuid =>> \(peripheralUUID)")
            }
           
            for p:AnyObject in self.centralManager.retrievePeripherals(withIdentifiers: [NSUUID(uuidString:peripheralUUID!)! as UUID]) {
                if p is CBPeripheral {
                    self.powerMonitor = p as? CBPeripheral
                    self.powerMonitor?.delegate = self
                    if (self.powerMonitor != nil) {
                        self.centralManager.connect(self.powerMonitor!, options: nil)
                        self.stopConnectionRequestTimer?.invalidate()
                        self.stopConnectionRequestTimer = Timer.scheduledTimer(withTimeInterval: 60 * 15, repeats: false) { _ in
                                self.disconnectFromPeripheral(self.powerMonitor!)
                        }
                    }
                }
            }
        }
    }
    
    public func tryToConnectToPeripheral (uuid : UUID) {
        self.onlyConnectWithoutDataAccess = true
        //globalDebugDataInstance.showInfoMsg("BTManager: try to connect to =>> \(uuid)")
        for p:AnyObject in self.centralManager.retrievePeripherals(withIdentifiers: [uuid]) {
            if p is CBPeripheral {
                //self.powerMonitor = p as? CBPeripheral
                //if (self.powerMonitor != nil) {
                //    self.centralManager.connect(self.powerMonitor!, options: nil)
                //}
                if let sensor = p as? CBPeripheral {
                    sensor.delegate = self
                    self.centralManager.connect(sensor, options: nil)
                }
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Connecting /Discon. peripherals
    ////////////////////////////////////////////////////////////////////////////////////////
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //globalDebugDataInstance.showInfoMsg(">>>>>>>>> didConnect peripheral,  uuid =>> \(peripheral.identifier.uuidString)")
        
        // save peripheral and setup delegates
        
        //self.powerMonitor = peripheral
        //self.powerMonitor!.delegate = self
        
        // later change this to more services and user will select one/multiple
        // only search for power service:
        let powerServiceUUID = BlueToothGATTServices.CyclingPower.UUID
        let deviceInforUUID = BlueToothGATTServices.DeviceInformation.UUID
        let cadenceServiceUUID = BlueToothGATTServices.CyclingSpeedandCadence.UUID
        peripheral.discoverServices([powerServiceUUID, deviceInforUUID, cadenceServiceUUID])


        /*let connected = "Connected: " + (self.heartMonitor!.state == CBPeripheralState.connected ? "YES" : "NO")
        print("\(connected)")
        self.updateMessage?("Connected.")*/
        //updateConnectionStatus?(self.powerMonitor!.state)
    }
       
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            //globalDebugDataInstance.showErrorMsg(" BTManager didDisconnectPeripheral:: \(error!.localizedDescription)")
            
        }
        
        activePeripherals.removeValue(forKey: peripheral.identifier.uuidString)
        updateConnectionStatus?(peripheral.state)
        // todo give info that connection is not possible -> callback needed
        
        if (peripheral == powerMonitor) {
            updatePowerValue?(0)
            self.powerMonitor?.delegate = nil
            // only in case of workout running make a re-connect (in this case we lost the device)
            if (globalWorkoutDataInstance.isWorkoutRunning == true) {
                // wait 500 ms before next connection try (advise to wait 20ms or more, info from discussion forum in net
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.connectToPowerSensorAndRetrieveData()
                }
            }
        } else {
            peripheral.delegate = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            //globalDebugDataInstance.showErrorMsg(" BTManager didDisconnectPeripheral:: \(error!.localizedDescription)")
            
        }

        // update connection status
        activePeripherals.removeValue(forKey: peripheral.identifier.uuidString)
        updateConnectionStatus?(CBPeripheralState.disconnected)
        
        if (peripheral == powerMonitor) {
            updatePowerValue?(0)
            self.powerMonitor?.delegate = nil
            // only in case of workout running make a re-connect (in this case we lost the device)
            if (globalWorkoutDataInstance.isWorkoutRunning == true) {
                // wait 500 ms before next connection try (advise to wait 20ms or more, info from discussion forum in net
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    self.connectToPowerSensorAndRetrieveData()
                }
            }
        } else {
            peripheral.delegate = nil
        }
    }
    
    
    func disconnectFromPowerSensor()
    {
        if powerMonitor != nil {
            self.centralManager.cancelPeripheralConnection(powerMonitor!)
            self.powerMonitor = nil
            self.stopConnectionRequestTimer?.invalidate()
        }
    }
    
    func disconnectFromPeripheral(_ per : CBPeripheral)
    {
        centralManager.cancelPeripheralConnection(per)
    }
    
    func disconnectAllSensors() {
        for (identifier,ExtPeripheral) in self.activePeripherals {
            self.centralManager.cancelPeripheralConnection(ExtPeripheral.peripheral)
            self.activePeripherals[identifier] = nil
        }
        let services = [BlueToothGATTServices.DeviceInformation.UUID]
        let conDev = self.centralManager.retrieveConnectedPeripherals(withServices:  services)
        conDev.forEach{ item in
            self.centralManager.cancelPeripheralConnection(item)
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Services / Characteristic handling
    ////////////////////////////////////////////////////////////////////////////////////////
    
    func servicesSupportedWeAreInterestedIn(_ per : CBPeripheral) -> Bool? {
        var supported = false
        per.services?.forEach { service in
            if supportedServicesWeAreInterestedIn.contains(service.uuid) {
                supported = true
            }
        }
        return supported
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            //globalDebugDataInstance.showErrorMsg(" BTManager didDiscoverServices:: \(error!.localizedDescription)")
            
        }
        
        // call update connection list again since now we have a service list of this sensor
        updateConnectionStatus?(peripheral.state)

        for service in peripheral.services!
        {
            //globalDebugDataInstance.showInfoMsg("Discovered service: \(service.uuid)")
            
            // always ask for device information
            if service.uuid == BlueToothGATTServices.DeviceInformation.UUID {
              peripheral.discoverCharacteristics(nil, for: service)
            }  else if service.uuid == BlueToothGATTServices.CyclingSpeedandCadence.UUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }else if (self.onlyConnectWithoutDataAccess == false) {
              // ask for power service
              peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil { globalDebugDataInstance.showErrorMsg(" BTManager didDiscoverCharacteristicsFor:: \(error!.localizedDescription)") }
        
        for characteristic in (service.characteristics!) {
            globalDebugDataInstance.showInfoMsg("Discovered characteristic: \(characteristic.uuid)")
        }
        
        // service UUID was before limited to UUID: "0x1818"
        for characteristic in (service.characteristics!) {
            if characteristic.uuid == CBUUID(string: "2A29") {
                peripheral.readValue(for: characteristic) // get manufacture ID
            }
            
            
            if characteristic.uuid == CBUUID(string: "0x2A5B") {
                globalDebugDataInstance.showInfoMsg("Discovered cadence characteristic: \(characteristic.uuid)")
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    peripheral.discoverDescriptors(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
            
            // we are looking for: org.bluetooth.characteristic.cycling_power_measurement
            if characteristic.uuid == CBUUID(string: "0x2A63") {
                globalDebugDataInstance.showInfoMsg("Discovered characteristic: \(characteristic.uuid)")
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    peripheral.discoverDescriptors(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    // received updated value
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // todo later extend for more characteristics
        if error != nil {
            //globalDebugDataInstance.showErrorMsg(" BTManager didUpdateValueFor:: \(error!.localizedDescription)")
            
        }
        
        if characteristic.uuid == CBUUID(string: "2A29") {
            guard let data = characteristic.value else { return }
            let count = data.count / MemoryLayout<UInt8>.size
            var array = [UInt8](repeating: 0, count: count)
            data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
            let str = String(bytes: data, encoding: .utf8)
            
            let key = peripheral.identifier.uuidString
            let extPer = ExtPeripheral(name: peripheral.name ?? "", manufacturaName : str ?? "", lastRSSI: 0, peripheral: peripheral)
            activePeripherals.updateValue(extPer, forKey: key)
            updateConnectionStatus?(peripheral.state)
        } else if characteristic.uuid == CBUUID(string: "0x2A5B") {
            //globalDebugDataInstance.showInfoMsg("BTManager cadence didUpdateValueFor called")
            self.getCadenceData(characteristic: characteristic, error: error)
        } else {
            self.getPowerData(characteristic: characteristic, error: error)
        }
    }
    
    
    
     func getCadenceData(characteristic: CBCharacteristic, error: Error?) {
         if error != nil {
            globalDebugDataInstance.showErrorMsg(" BTManager getCadenceData:: \(error!.localizedDescription)")
            
         }
         guard let data = characteristic.value else { return }
         
         let count = data.count / MemoryLayout<UInt8>.size
         var array = [UInt8](repeating: 0, count: count)
         data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
         globalDebugDataInstance.showInfoMsg("BTManager Discovered cadence array: \(array.description)")
         // todo evaluate array
         handleValueData(data: data, isCadence: true)
     }
    
    func handleValueData( data:Data, isCadence: Bool ) {
        let cadenceMode = globalWorkoutDataInstance.getCadenceMode() ?? false
       if !cadenceMode {
           print("cadence called handleValueData")
           return
       }
       let measurement = Measurement(data: data, wheelSize: BTManager.DefaultWheelSize, isCandenceDevice: isCadence)
        print("\(measurement)")
      
       let values = measurement.valuesForPreviousMeasurement(previousSample: lastMeasurement)
        lastMeasurement = measurement
        
       print("cadenceis\(values?.cadenceinRPM)")
        globalWorkoutDataInstance.cyclingCadence.value = values?.cadenceinRPM ?? 0.0
        //sensorDelegate?.sensorUpdatedValues(speedInMetersPerSecond: values?.speedInMetersPerSecond, cadenceInRpm: values?.cadenceinRPM, distanceInMeters: values?.distanceinMeters)
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // Get Power values from Peripheral
    ////////////////////////////////////////////////////////////////////////////////////////
    func getPowerData(characteristic: CBCharacteristic, error: Error?) {
        if error != nil { globalDebugDataInstance.showErrorMsg(" BTManager getHeartBPMData:: \(error!.localizedDescription)") }
        guard let data = characteristic.value else { return }
        
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
        
        // todo evaluate array
        print(array)
        //let pwr : Double = Double((array[2] << 8) | array[3])
        //let pwr : Double = Double(array[4])
        
        var pwr : Int = 0
        pwr = (Int(array[3]) << 8) | Int(array[2])
        globalWorkoutDataInstance.currentPower.value = Double(pwr)
        handleValueData(data: data, isCadence: false)
    }
   /*
    func getHeartBPMData(characteristic: CBCharacteristic, error: Error?) {
        if error != nil { print(" getHeartBPMData:: \(error!)") }
        guard let data = characteristic.value else { return }
        
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
        
        if ((array[0] & 0x01) == 0) {
            let bpm = array[1]
            let bpmInt = Int(bpm)
            let hr = HeartRate(BPM: bpmInt, intensity: 0)
            self.update?(hr)
            print(hr)
        }
    } */
    
    ////////////////////////////////////////////////////////////////////////////////////////
    // User Defaults handling
    ////////////////////////////////////////////////////////////////////////////////////////
    public func getRegisteredPeripheral() -> UUID? {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        if let storedPeripheralUUID = defaults?.string(forKey: "activeBtPeripheralUUID") {
            return (NSUUID(uuidString:storedPeripheralUUID) as UUID?)
        } else {
            return nil
        }
    }
    
    public func registerPeripheralAsPowerSensor(_ per : ExtPeripheral) {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        defaults?.set(per.peripheral.identifier.uuidString, forKey: "activeBtPeripheralUUID")
        defaults?.set(per.manufacturaName, forKey: "manufacturaName")
    }
    
    public func removePeripheral() {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        defaults?.removeObject(forKey: "activeBtPeripheralUUID")
    }
    
    public func isPeripheralRegistered(peripheralUUID : UUID? = nil)->Bool {
        let defaults = UserDefaults(suiteName: "group.plan2peak.com.aw.userdefaults")
        let storedPeripheralUUID = defaults?.string(forKey: "activeBtPeripheralUUID")
        
        if (storedPeripheralUUID == nil) {
            return false
        }
        
        if (peripheralUUID == nil) {
            return true
        } else {
            return (NSUUID(uuidString:storedPeripheralUUID!) as UUID?) == peripheralUUID!
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    
    // delegate for central Manager state transitions:
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOff:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is powered off")
        case CBManagerState.poweredOn:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is powered on and ready")
        case CBManagerState.unauthorized:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is unauthorized")
        case CBManagerState.resetting:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is resetting")
        case CBManagerState.unknown:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is unknown")
        case CBManagerState.unsupported:
            globalDebugDataInstance.showInfoMsg("CoreBluetooth BLE hardware is unsupported")
        }
    }
}
