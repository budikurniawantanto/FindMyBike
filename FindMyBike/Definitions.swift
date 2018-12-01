//
//  Definitions.swift
//  Bluetooth
//
//  Created by Mick on 12/20/14.
//  Copyright (c) 2014 MacCDevTeam LLC. All rights reserved.
//

import CoreBluetooth

let MAC_PERIPHERAL = "609E5D1A-7FEC-6CE3-85C1-06D0E9A51AB1"
let MAC_TRANSFER_SERVICE_UUID = "ec00"
let MAC_TRANSFER_CHARACTERISTIC_UUID = "ec0e"
let TRANSFER_SERVICE_UUID = "FFE0"
let TRANSFER_CHARACTERISTIC_UUID = "FFE1"
let NOTIFY_MTU = 20

let MACtransferServiceUUID = CBUUID(string: MAC_TRANSFER_SERVICE_UUID)
let MACtransferCharacteristicUUID = CBUUID(string: MAC_TRANSFER_CHARACTERISTIC_UUID)
let transferServiceUUID = CBUUID(string: TRANSFER_SERVICE_UUID)
let transferCharacteristicUUID = CBUUID(string: TRANSFER_CHARACTERISTIC_UUID)
