//
//  CBCentral.swift
//  BLESampleApp
//
//  Created by MakotoKaneko on 2019/07/13.
//  Copyright © 2019 MakotoKaneko. All rights reserved.
//

import CoreBluetooth

class CBCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var manager: CBCentralManager?
    var peripherals: [CBPeripheral] = []
    var result: String = ""
    var cbPeripheral: CBPeripheral? = nil
    var cbCharacteristic: CBCharacteristic? = nil
    
    override init () {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func scan() {
        if manager!.isScanning == false {
            manager!.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func connect() {
        for peripheral in peripherals {
            if peripheral.name != nil && peripheral.name == "Device Name" {
                cbPeripheral = peripheral
                manager?.stopScan()
                break;
            }
        }
        
        if cbPeripheral != nil {
            manager!.connect(cbPeripheral!, options: nil)
        }
        else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("!! not found device : \(formatter.string(from: date))\n")
        }
    }
    
    func  Send(message: String) {
        if cbCharacteristic != nil {
            var command = message + "\n"
            let data = command.data(using: String.Encoding.utf8, allowLossyConversion:true)
            cbPeripheral!.writeValue(data! , for: cbCharacteristic!, type: .withResponse)
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("Success Send(\(message)) : \(formatter.string(from: date))\n")
        }
        else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("!! failed Send(\(message)) : \(formatter.string(from: date))\n")
        }
    }
    
    // CBCentralManagerDelegate Protcol
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Must
    }

    // 1. ペリフェラルが発見されると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals.append(peripheral)
    }
    
    // 2. ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        cbPeripheral?.delegate = self
        
        //指定されたサービスUUIDを探す
        let services: [CBUUID] = [CBUUID(string: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")]
        cbPeripheral!.discoverServices(services)
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jms")
        result.append("connected : \(formatter.string(from: date))\n")
    }
    
    // 2. ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jms")
        result.append("!! failed : \(formatter.string(from: date))\n")
    }
    
    // 4. サービス内のキャラクタリスティクスを見つける
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if cbPeripheral != nil {
            let ser: CBUUID = CBUUID(string: "27ADC9CA-35EB-465A-9154-B8FF9076F3E8")
            for service in cbPeripheral!.services! {
                if(service.uuid == ser) {
                    cbPeripheral?.discoverCharacteristics(nil, for: service)
                    
                    let date = Date()
                    let formatter = DateFormatter()
                    formatter.setLocalizedDateFormatFromTemplate("jms")
                    result.append("succecced 1. peripheral() : \(formatter.string(from: date))\n")
                }
                
            }
        }
        else {
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("!! not found Char 1 : \(formatter.string(from: date))\n")
        }
    }
    
    // 5. 特定のキャラクタリスティックを見つける
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var isSuccess = false
        
        //ペリフェラルの保持しているキャラクタリスティクスから特定のものを探す
        for i in service.characteristics!{
            var debug = i.uuid.uuidString
            if i.uuid.uuidString == "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"{
                
                //Notificationを受け取るハンドラ
                peripheral.setNotifyValue(true, for: i)

                let date = Date()
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("jms")
                result.append("succecced 2. peripheral() Notify : \(formatter.string(from: date))\n")
                
                isSuccess = true
            }
            
            if i.uuid.uuidString == "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" {
                cbCharacteristic = i
                
                let date = Date()
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("jms")
                result.append("succecced 2. peripheral() Write : \(formatter.string(from: date))\n")
                
                isSuccess = true
            }
        }
        
        if isSuccess == false {
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("!! failed Char 2 : \(formatter.string(from: date))\n")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let notify: CBUUID = CBUUID(string: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")
        if characteristic.uuid.uuidString == notify.uuidString {
            let buffer = [UInt8](characteristic.value!)
            
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("received: \(buffer) \(formatter.string(from: date))\n")
        }
    }
    
    // 6. 書き込まれたことを検知してNotificationが帰ってくる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            let date = Date()
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("jms")
            result.append("error \(error) : \(formatter.string(from: date))\n")
            return
        }
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jms")
        result.append("received Notification : \(formatter.string(from: date))\n")
    }
}
