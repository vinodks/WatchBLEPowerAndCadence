//
//  Measurement.swift
//
//  Copyright (c) 2019, Devendra Narain
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import CoreBluetooth

// CSC Measurement
// https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.csc_measurement.xml
//
//  Flags : 1 byte.  Bit 0: Wheel. Bit 1: Crank
//  Cumulative Wheel revolutions: 4 bytes uint32
//  Last wheel event time: 2 bytes. uint16 (1/1024s)
//  Cumulative Crank revolutions: 2 bytes uint16
//  Last cranck event time: 2 bytes. uint16 (1/1024s)


struct Measurement : CustomDebugStringConvertible {
    
    let hasWheel:Bool
    let hasCrank:Bool
    let cumulativeWheel:UInt32
    let lastWheelEventTime:TimeInterval
    let cumulativeCrank:UInt16
    let lastCrankEventTime:TimeInterval
    let wheelSize:UInt32
    let timeScale = 1024.0
    var pedalPowerPresent = false
    var accumulatedTorquePresent = false
    
    
    init(data: Data, wheelSize: UInt32, isCandenceDevice: Bool) {
        
        self.wheelSize = wheelSize
        
        var wheel:UInt32=0
        var wheelTime:UInt16=0
        var crank:UInt16=0
        var crankTime:UInt16=0
        let newData =  data as NSData
        var currentOffset = 1
        var length = 0
        
        
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
        //globalDebugDataInstance.showInfoMsg("BTManager Discovered power cadence array: \(array.description)")
        
        if !isCandenceDevice {
            
            
            // todo evaluate array
            print(array)
            //let pwr : Double = Double((array[2] << 8) | array[3])
            //let pwr : Double = Double(array[4])
            
            //var pwr : Int = 0
            //pwr = (Int(array[3]) << 8) | Int(array[2])
            //HealthStoreManager.shared.currentPower.value = Double(pwr)
            currentOffset = 2
            length = 0
            let bit = Helper.bitsArray(fromByte: array[0])
            
            //globalDebugDataInstance.showInfoMsg("BTManager Discovered power cadence array[0]: \(bit)")
            if bit[4] == .one {
                //globalDebugDataInstance.showInfoMsg("BTManager Discovered power wheel cadence value is present")
                hasWheel = true
                hasCrank = false
            } else if bit[5] == .one {
                //globalDebugDataInstance.showInfoMsg("BTManager Discovered power crank cadence value is present")
                hasCrank = true
                hasWheel = false
            } else {
                hasWheel = false
                hasCrank = false
                //globalDebugDataInstance.showInfoMsg("BTManager Discovered power cadence value is not present")
            }
            
            if bit[0] == .one {
                pedalPowerPresent = true
            }
            
            if bit[2] == .one {
                accumulatedTorquePresent = true
            }
            
            //instant power
            length = MemoryLayout<UInt16>.size
            currentOffset += length
            
            //Pedal Power Balance
            if pedalPowerPresent {
                length = MemoryLayout<UInt8>.size
                currentOffset += length
            }
            
            //Accumulated Torque
            if accumulatedTorquePresent {
                length = MemoryLayout<UInt16>.size
                currentOffset += length
            }
            
        } else {
            let wheelFlagMask:UInt8    = 0b01
            let crankFlagMask:UInt8    = 0b10
            var flags:UInt8=0
            let endIndex = data.index(data.startIndex, offsetBy: 1)
            let range: Range<Data.Index> = data.startIndex..<endIndex
            data.copyBytes(to: &flags, from: range)
            hasWheel = ((flags & wheelFlagMask) > 0)
            hasCrank = ((flags & crankFlagMask) > 0)
            //globalDebugDataInstance.showInfoMsg("BTManager hasWheel: \(hasWheel)")
            
        }
        
        if ( hasWheel ) {
            //Wheel Revolution Data - Cumulative Wheel Revolutions
            length = MemoryLayout<UInt32>.size
            newData.getBytes(&wheel, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            //Wheel Revolution Data - Last Wheel Event Time
            length = MemoryLayout<UInt16>.size
            newData.getBytes(&wheelTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            cumulativeWheel     = CFSwapInt32LittleToHost(wheel)
            lastWheelEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(wheelTime))/timeScale)
        } else {
            cumulativeWheel = 0
            lastWheelEventTime = 0
        }
        
        if ( hasCrank ) {
            //Crank Revolution Data - Cumulative Wheel Revolutions
            //globalDebugDataInstance.showInfoMsg("Measurement currentOffset crank \(currentOffset)")
            length = MemoryLayout<UInt16>.size
            newData.getBytes(&crank, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            //globalDebugDataInstance.showInfoMsg("Measurement currentOffset crankTime \(crankTime)")
            //Crank Revolution Data - Last Wheel Event Time
            length = MemoryLayout<UInt16>.size
            newData.getBytes(&crankTime, range: NSRange(location: currentOffset, length: length))
            currentOffset += length
            //globalDebugDataInstance.showInfoMsg("Measurement Discovered crank \(crank)")
            //globalDebugDataInstance.showInfoMsg("Measurement Discovered crankTime \(crankTime)")
            
        }
        cumulativeCrank     = CFSwapInt16LittleToHost(crank)
        lastCrankEventTime  = TimeInterval( Double(CFSwapInt16LittleToHost(crankTime))/timeScale)
        //globalDebugDataInstance.showInfoMsg("Measurement cumulativeWheel: \(cumulativeWheel)")
        //globalDebugDataInstance.showInfoMsg("Measurement lastWheelEventTime: \(lastWheelEventTime)")
        //globalDebugDataInstance.showInfoMsg("Measurement Discovered cumulativeCrank \(cumulativeCrank)")
        //globalDebugDataInstance.showInfoMsg("Measurement Discovered lastCrankEventTime \(lastCrankEventTime)")
        
    }
    
    
   
    
    func timeIntervalForCurrentSample( current:TimeInterval, previous:TimeInterval ) -> TimeInterval {
        var timeDiff:TimeInterval = 0
        if( current >= previous ) {
            timeDiff = current - previous
        }
        else {
            // passed the maximum value
            timeDiff =  ( TimeInterval((Double( UINT16_MAX) / timeScale)) - previous) + current
        }
        return timeDiff
    }
    
    func valueDiffForCurrentSample<T:UnsignedInteger>( current:T, previous:T , max:T) -> T {
        var diff:T = 0
        if  ( current >= previous ) {
            diff = current - previous
        }
        else {
            diff = ( max - previous ) + current
        }
        return diff
    }
    
    
    func valuesForPreviousMeasurement( previousSample:Measurement? ) -> ( cadenceinRPM:Double?, distanceinMeters:Double?, speedInMetersPerSecond:Double?)? {
        var distance:Double?, cadence:Double?, speed:Double?
        guard let previousSample = previousSample else {
            return nil
        }
        if ( hasWheel && previousSample.hasWheel ) {
            let wheelTimeDiff = timeIntervalForCurrentSample(current: lastWheelEventTime, previous: previousSample.lastWheelEventTime)
            let valueDiff = valueDiffForCurrentSample(current: cumulativeWheel, previous: previousSample.cumulativeWheel, max: UInt32.max)
            
            distance = Double( valueDiff * wheelSize) / 1000.0 // distance in meters
            if  distance != nil  &&  wheelTimeDiff > 0 {
                speed = (wheelTimeDiff == 0 ) ? 0 : distance! / wheelTimeDiff // m/s
            }
        }
        
        if( hasCrank && previousSample.hasCrank ) {
            let crankDiffTime = timeIntervalForCurrentSample(current: lastCrankEventTime, previous: previousSample.lastCrankEventTime)
            let valueDiff = Double(valueDiffForCurrentSample(current: cumulativeCrank, previous: previousSample.cumulativeCrank, max: UInt16.max))
            
            cadence = (crankDiffTime == 0) ? 0 : Double(60.0 * valueDiff / crankDiffTime) // RPM
        }
        print( "Cadence: \(cadence) RPM. Distance: \(distance) meters. Speed: \(speed) Km/h" )
        return ( cadenceinRPM:cadence, distanceinMeters:distance, speedInMetersPerSecond:speed)
    }
    
    
    
    
    
    var debugDescription:String {
        get {
            return "Wheel Revs: \(cumulativeWheel). Last whee   l event time: \(lastWheelEventTime). Crank Revs: \(cumulativeCrank). Last Crank event time: \(lastCrankEventTime)"
        }
    }
    
}


