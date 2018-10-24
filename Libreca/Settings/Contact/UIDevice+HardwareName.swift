//
//  UIDevice+Hardware.swift
//  Fiscus
//
//  Created by Justin Marshall on 3/1/18.
//
//  Libreca is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Libreca is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Libreca.  If not, see <https://www.gnu.org/licenses/>.
//
//  Copyright © 2018 Justin Marshall
//  This file is part of project: Libreca
//

import UIKit

// courtesy of: https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios, slightly modified
extension UIDevice {
    private var hardwareVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private var hardwareMapping: [String: String] {
        return [
            // Simulator
            "i386": "32-bit Simulator",
            "x86_64": "64-bit Simulator",
            
            // iPhone
            "iPhone1,1": "iPhone",
            "iPhone1,2": "iPhone 3G",
            "iPhone2,1": "iPhone 3GS",
            "iPhone3,1": "iPhone 4",
            "iPhone3,3": "iPhone 4",
            "iPhone4,1": "iPhone 4S",
            "iPhone5,1": "iPhone 5",
            "iPhone5,2": "iPhone 5",
            "iPhone5,3": "iPhone 5c",
            "iPhone5,4": "iPhone 5c",
            "iPhone6,1": "iPhone 5s",
            "iPhone6,2": "iPhone 5s",
            "iPhone7,1": "iPhone 6 Plus",
            "iPhone7,2": "iPhone 6",
            "iPhone8,1": "iPhone 6S",
            "iPhone8,2": "iPhone 6S Plus",
            "iPhone8,4": "iPhone SE",
            "iPhone9,1": "iPhone 7",
            "iPhone9,3": "iPhone 7",
            "iPhone9,2": "iPhone 7 Plus",
            "iPhone9,4": "iPhone 7 Plus",
            "iPhone10,1": "iPhone 8",
            "iPhone10,4": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X",
            "iPhone10,6": "iPhone X",
            
            // iPad 1
            "iPad1,1": "iPad",
            
            // iPad 2
            "iPad2,1": "iPad 2 - Wifi",
            "iPad2,2": "iPad 2",
            "iPad2,3": "iPad 2 - 3G",
            "iPad2,4": "iPad 2 - Wifi",
            
            // iPad Mini
            "iPad2,5": "iPad Mini - Wifi",
            "iPad2,6": "iPad Mini - Wifi + Cellular",
            "iPad2,7": "iPad Mini - Wifi + Cellular",
            
            // iPad 3
            "iPad3,1": "iPad 3 - Wifi",
            "iPad3,2": "iPad 3 - Wifi + Cellular",
            "iPad3,3": "iPad 3 - Wifi + Cellular",
            
            // iPad 4
            "iPad3,4": "iPad 4 - Wifi",
            "iPad3,5": "iPad 4 - Wifi + Cellular",
            "iPad3,6": "iPad 4 - Wifi + Cellular",
            
            // iPad Air
            "iPad4,1": "iPad Air - Wifi",
            "iPad4,2": "iPad Air - Wifi + Cellular",
            "iPad4,3": "iPad Air - Wifi + Cellular",
            
            // iPad Mini 2
            "iPad4,4": "iPad Mini 2 - Wifi",
            "iPad4,5": "iPad Mini 2 - Wifi + Cellular",
            "iPad4,6": "iPad Mini 2 - Wifi + Cellular",
            
            // iPad Mini 3
            "iPad4,7": "iPad Mini 3 - Wifi",
            "iPad4,8": "iPad Mini 3 - Wifi + Cellular",
            "iPad4,9": "iPad Mini 3 - Wifi + Cellular",
            
            // iPad Mini 4
            "iPad5,1": "iPad Mini 4 - Wifi",
            "iPad5,2": "iPad Mini 4 - Wifi + Cellular",
            
            // iPad Air 2
            "iPad5,3": "iPad Air 2 - Wifi",
            "iPad5,4": "iPad Air 2 - Wifi + Cellular",
            
            // iPad Pro 12.9"
            "iPad6,3": "iPad Pro 12.9\" - Wifi",
            "iPad6,4": "iPad Pro 12.9\" - Wifi + Cellular",
            
            // iPad Pro 9.7"
            "iPad6,7": "iPad Pro 9.7\" - Wifi",
            "iPad6,8": "iPad Pro 9.7\" - Wifi + Cellular",
            
            // iPad (5th generation)
            "iPad6,11": "iPad 5 - Wifi",
            "iPad6,12": "iPad 5 - Wifi + Cellular",
            
            // iPad Pro 12.9" (2nd Gen)
            "iPad7,1": "iPad Pro 2 12.9\" - Wifi",
            "iPad7,2": "iPad Pro 2 12.9\" - Wifi + Cellular",
            
            // iPad Pro 10.5"
            "iPad7,3": "iPad Pro 2 10.5\" - Wifi",
            "iPad7,4": "iPad Pro 2 10.5\" - Wifi + Cellular",
            
            // iPod Touch
            "iPod1,1": "iPod Touch First Generation",
            "iPod2,1": "iPod Touch Second Generation",
            "iPod3,1": "iPod Touch Third Generation",
            "iPod4,1": "iPod Touch Fourth Generation",
            "iPod7,1": "iPod Touch 6th Generation"
        ]
    }
    
    var hardwareName: String {
        let theHardwareVersion = hardwareVersion
        guard let theHardwareName = hardwareMapping[theHardwareVersion] else {
            // Not found on database. At least guess main device type from string contents:
            if theHardwareVersion.contains("iPod") {
                return "iPod Touch"
            } else if theHardwareVersion.contains("iPad") {
                return "iPad"
            } else if theHardwareVersion.contains("iPhone") {
                return "iPhone"
            } else {
                return "Unknown"
            }
        }
        return theHardwareName
    }
}
