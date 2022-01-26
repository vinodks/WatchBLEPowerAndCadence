//
//  bleTestIfController.swift
//  Bike2PEAK_AW Extension
//
//  Created by Christian on 22.05.18.
//

import WatchKit
import Foundation
import CoreBluetooth


enum BluetoothSearchDeviceState {
    case scanning
    case tryToConnect
    case connected
}

class BTScanForDevicesInterfaceController: WKInterfaceController{
    private var lastUUIDUsed : UUID?
    //private var searchState : BluetoothSearchDeviceState = BluetoothSearchDeviceState.scanning
    private var foundPeripheralsDuringScan : [ExtPeripheral]?
    private var initialConnectedPeripheralsByOtherApps : Dictionary<String,ExtPeripheral> = [:]
    private var btManager : BTManager?{
    didSet {
            btManager?.updateList = { (list:[ExtPeripheral]) in
                DispatchQueue.main.async {
                // call here function to update list of found sensors
                    self.foundPeripheralsDuringScan = list
                    self.updateAvailableDevicesTableList(list)
                    self.updateConnectedDevicesTableList()
                }
            }
        
            btManager?.updateConnectionStatus = { (state: CBPeripheralState) in
                    DispatchQueue.main.async {
                        if let conDev = self.btManager?.getListOfConnectedPeripherals() {
                            self.updateConnectedDevicesTableList()
                            self.foundPeripheralsDuringScan = self.foundPeripheralsDuringScan?.filter { (per) -> Bool in
                                conDev[per.peripheral.identifier.uuidString] == nil
                            }
                        self.updateAvailableDevicesTableList(self.foundPeripheralsDuringScan ?? [])
                    }
                }
            }
        }
    }
        
    @IBOutlet var statusLabel: WKInterfaceLabel!
    @IBOutlet var connectedDeviceLabel: WKInterfaceLabel!
    @IBOutlet var availableDeviceLabel: WKInterfaceLabel!
    @IBOutlet var connectedDevicesTable: WKInterfaceTable!
    @IBOutlet var availableDevices: WKInterfaceTable!
   
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
       
        // set static texts
        setTitle(NSLocalizedString("Back", comment: ""))
        connectedDeviceLabel.setText(NSLocalizedString("Connected Devices", comment: ""))
        availableDeviceLabel.setText(NSLocalizedString("Available Devices", comment: ""))
        
        /*if let id = self.value(forKey: "_viewControllerID") as? NSString {
            let strClassDescription = String(describing: self)
            print("\(strClassDescription) has the Interface Controller ID \(id)")
        }*/
        btManager = BTManager.shared
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
       
        // always start scanning on willActivate
        btManager?.startScanForDevices()
        statusLabel.setText(NSLocalizedString("Scanning", comment: ""))
        
        /*
        if (searchState == BluetoothSearchDeviceState.scanning) {
            // scan for peripherals
            btManager?.startScanForDevices()
            statusLabel.setText(NSLocalizedString("Scanning", comment: ""))
        } else if (searchState == BluetoothSearchDeviceState.tryToConnect) {
            // try to connect
            btManager?.tryToConnectToPeripheral(uuid: lastUUIDUsed!)
            statusLabel.setText(NSLocalizedString("Connecting", comment: ""))
        } else if (searchState == BluetoothSearchDeviceState.connected) {
            // no action to be taken
            statusLabel.setText(NSLocalizedString("Connected", comment: ""))
        } */
        
        // check for connected peripherals
        initialConnectedPeripheralsByOtherApps = btManager!.getListOfConnectedPeripherals()

        // this devices i don't know the servies supported, they are already connected in system so try to connect to them and ask for services
        initialConnectedPeripheralsByOtherApps.forEach{ dev in
            btManager?.tryToConnectToPeripheral(uuid: dev.value.peripheral.identifier)
        }

        self.updateConnectedDevicesTableList()
        lastUUIDUsed = btManager?.getRegisteredPeripheral()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        btManager?.stopScanning()
        
        // only disconnect if back is pressed
//        if (globalVarsInstance.applicationInForeground == true) {
//            btManager?.disconnectAllSensors()
//        }
        
        // disconnect BT callbacks
        btManager?.updateList = nil
        btManager?.updateConnectionStatus = nil
    }
    
    private func updateAvailableDevicesTableList(_ peripherals :[ExtPeripheral]) {
        availableDevices.setNumberOfRows(peripherals.count, withRowType: "availableDeviceTableRowController")
        var i : Int = 0
        
        for peripheral in peripherals {
            let row = availableDevices.rowController(at: i) as! availableDeviceListEntry
            row.deviceName.setText(peripheral.name)

            if lastUUIDUsed == peripheral.peripheral.identifier {
                btManager?.tryToConnectToPeripheral(uuid: lastUUIDUsed!)
                statusLabel.setText(NSLocalizedString("Connecting", comment: ""))
            }
            
            row.peripheral = peripheral
            row.statusImage.setImageNamed("BT_unknownDevice")
            i += 1
        }
    }
    
    private func updateConnectedDevicesTableList() {
        let conDevicesDictionary = btManager!.getListOfConnectedPeripherals()
        connectedDevicesTable.setNumberOfRows(conDevicesDictionary.count, withRowType: "connectedDeviceTableRowController")
        var i : Int = 0
        for (_, device) in conDevicesDictionary {
            let row = connectedDevicesTable.rowController(at: i) as! connectedDeviceListEntry
            
            // check if supported services are in
            let  weAreInterestedInThisService = btManager?.servicesSupportedWeAreInterestedIn(device.peripheral)
            
            if (weAreInterestedInThisService == true)
            {
                if device.peripheral.identifier == lastUUIDUsed {
                    btManager?.registerPeripheralAsPowerSensor(device) // this is now the active power monitor
                    row.deviceName.setAttributedText(NSAttributedString(string: device.name,
                                                                        attributes: [NSAttributedString.Key.foregroundColor : UIColor.green]))
                    row.supportedServiceAvailable = true
                    statusLabel.setText(NSLocalizedString("Connected", comment: ""))
                } else {
                    //row.deviceName.setText(peripheral.name)
                    row.deviceName.setAttributedText(NSAttributedString(string: device.name,
                                                                        attributes: [NSAttributedString.Key.foregroundColor : UIColor.white]))
                    row.supportedServiceAvailable = true
                }
            } else {
                //row.deviceName.setText(peripheral.name)
                row.deviceName.setAttributedText(NSAttributedString(string: device.name,
                                                                    attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray]))
                row.supportedServiceAvailable = false
            }
            
            // display image of sensor Type
            if (device.manufacturaName == "Apple Inc.") {
                row.statusImage.setImageNamed("BT_AppleDevice")
            } else if (device.manufacturaName == "Stryd") {
                row.statusImage.setImageNamed("BT_StrydDevice")
            } else {
                if (weAreInterestedInThisService == true) {
                    row.statusImage.setImageNamed("BT_PowerSensor")
                } else {
                    row.statusImage.setImageNamed("BT_unknownDevice")
                }
            }
            row.peripheral = device
            i += 1
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if (table == availableDevices) {
            // device was selected -> try to connect this one

            // todo to do fixme add check to do not exceed max number of connections
            // better to ask for devices connected?
            // disconnect all devices connected so far

            for (_, device) in btManager!.getListOfConnectedPeripherals() {
                if initialConnectedPeripheralsByOtherApps[device.peripheral.identifier.uuidString] == nil {
                        self.btManager?.disconnectFromPeripheral(device.peripheral)
                }
                btManager?.startScanForDevices() //-> scanning should be running, but this also re-sets the list of available peripherals
            }
            
            if let rowControler = table.rowController(at: rowIndex) as? availableDeviceListEntry {
                lastUUIDUsed = rowControler.peripheral.peripheral.identifier
                btManager?.tryToConnectToPeripheral(uuid: lastUUIDUsed!)
                statusLabel.setText(NSLocalizedString("Connecting", comment: ""))
            }
        } else
            // remove connected one only if supported and connected
            if let rowControler = table.rowController(at: rowIndex) as? connectedDeviceListEntry {

                if rowControler.supportedServiceAvailable == false {
                    return // cannot connect this one
                }
                
                statusLabel.setText(NSLocalizedString("Scanning", comment: ""))
                
                if rowControler.peripheral.peripheral.identifier == lastUUIDUsed {
                    // disconnect this one
                    lastUUIDUsed = nil
                    rowControler.statusImage.setImageNamed("BT_Disconnected")
                    self.btManager?.removePeripheral()
                    
                    if initialConnectedPeripheralsByOtherApps[rowControler.peripheral.peripheral.identifier.uuidString] == nil {
                        // disconnect if this sensor was not initially connected by AppleWatch
                        self.btManager?.disconnectFromPeripheral(rowControler.peripheral.peripheral)
                        btManager?.startScanForDevices() //-> scanning should be running, but this also re-sets the list of available peripherals
                    } else {
                        // in this case just change the color, do not disconnect, since in this case we lose service information of this peripheral
                        rowControler.deviceName.setAttributedText(NSAttributedString(string: rowControler.peripheral.name,
                                                                            attributes: [NSAttributedString.Key.foregroundColor : UIColor.white]))
                    }

                    //searchState = BluetoothSearchDeviceState.scanning
                } else {
                    // try to connect this one
                    lastUUIDUsed = rowControler.peripheral.peripheral.identifier
                    btManager?.tryToConnectToPeripheral(uuid: lastUUIDUsed!)
                    statusLabel.setText(NSLocalizedString("Connecting", comment: ""))
            }
        }
    }
}

// Workout Information
class availableDeviceListEntry: NSObject {
    var peripheral : ExtPeripheral!
    @IBOutlet var deviceName: WKInterfaceLabel!
    @IBOutlet var statusImage: WKInterfaceImage!
}

class connectedDeviceListEntry: NSObject {
    var peripheral : ExtPeripheral!
    var supportedServiceAvailable : Bool!
    @IBOutlet var deviceName: WKInterfaceLabel!
    @IBOutlet var statusImage: WKInterfaceImage!
}
