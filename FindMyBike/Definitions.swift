//
//  Definitions.swift
//  Bluetooth
//
//  Created by Mick on 12/20/14.
//  Copyright (c) 2014 MacCDevTeam LLC. All rights reserved.
//

import CoreBluetooth
import UIKit

let MAC_PERIPHERAL = "609E5D1A-7FEC-6CE3-85C1-06D0E9A51AB1"
let MAC_TRANSFER_SERVICE_UUID = "ec00"
let MAC_TRANSFER_CHARACTERISTIC_UUID = "ec0e"
//let BLE_TRANSFER_SERVICE_UUID = "FFE0"
//let BLE_TRANSFER_CHARACTERISTIC_UUID = "FFE1"
//let BLE_TRANSFER_SERVICE_UUID = "A495BEEF-C5B1-4B44-B512-1370F02D74DE"
//let BLE_TRANSFER_CHARACTERISTIC_UUID = "69492B9B-49B5-9B6E-A2DD-333210A3EF5E"
let BLE_TRANSFER_SERVICE_UUID = "A495FF10-C5B1-4B44-B512-1370F02D74DE"
let BLE_TRANSFER_CHARACTERISTIC_UUID = "A495FF11-C5B1-4B44-B512-1370F02D74DE"
let NOTIFY_MTU = 20

let MACtransferServiceUUID = CBUUID(string: MAC_TRANSFER_SERVICE_UUID)
let MACtransferCharacteristicUUID = CBUUID(string: MAC_TRANSFER_CHARACTERISTIC_UUID)
let BLEtransferServiceUUID = CBUUID(string: BLE_TRANSFER_SERVICE_UUID)
let BLEtransferCharacteristicUUID = CBUUID(string: BLE_TRANSFER_CHARACTERISTIC_UUID)

var isFetch = (UIScreen.main.bounds.size.height == 812) || (UIScreen.main.bounds.size.height == 896)
var screenH: CGFloat! = 0
var needUpdateBikeLocation: Bool! = false

