//
//  ViewController.swift
//  AeromatRemote
//
//  Created by Mitchell Gu on 5/25/18.
//  Copyright © 2018 Mitchell Gu. All rights reserved.
//

import UIKit
import CoreBluetooth
let aeromatServiceCBUUID = CBUUID(string: "A6A00000-59A7-4906-AD27-0C57FBD5D643")
let aeromatIDCharacteristicCBUUID = CBUUID(string: "A6A00001-59A7-4906-AD27-0C57FBD5D643")
let aeromatIPCharacteristicCBUUID = CBUUID(string: "A6A00010-59A7-4906-AD27-0C57FBD5D643")
let aeromatSSIDCharacteristicCBUUID = CBUUID(string: "A6A00011-59A7-4906-AD27-0C57FBD5D643")
let aeromatPaircodeCharacteristicCBUUID = CBUUID(string: "A6A00012-59A7-4906-AD27-0C57FBD5D643")
let aeromatPressureCharacteristicCBUUID = CBUUID(string: "A6A00020-59A7-4906-AD27-0C57FBD5D643")
let aeromatCommandCharacteristicCBUUID = CBUUID(string: "A6A00021-59A7-4906-AD27-0C57FBD5D643")

class ViewController: UIViewController, UITextFieldDelegate {
    // MARK: Properties
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var ssidLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    
    @IBOutlet weak var lSNLabel: UILabel!
    @IBOutlet weak var rSNLabel: UILabel!
    @IBOutlet weak var tSNLabel: UILabel!
    @IBOutlet weak var bSNLabel: UILabel!

    @IBOutlet weak var cmdTextField: UITextField!
    
    var centralManager: CBCentralManager!
    var aeromatPeripheral: CBPeripheral!
    var aeromatIDCharacteristic: CBCharacteristic!
    var aeromatIPCharacteristic: CBCharacteristic!
    var aeromatSSIDCharacteristic: CBCharacteristic!
    var aeromatPaircodeCharacteristic: CBCharacteristic!
    var aeromatPressureCharacteristic: CBCharacteristic!
    var aeromatCommandCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        cmdTextField.delegate = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO
    }
    
    @IBAction func getPaircodeAction(_ sender: UIButton) {
        let url = URL(string: "http://am.mitchgu.com/\(idLabel.text ?? "x")/paircode")
        print("http://am.mitchgu.com/controller/\(idLabel.text ?? "x")/paircode")
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            var valStr: String
            if data != nil {
                valStr = String(data: data!, encoding: .utf8) ?? " ?"
            } else {
                valStr = "?"
            }
            let alert = UIAlertController(title: "New Paircode", message: valStr, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        task.resume()
        if aeromatPaircodeCharacteristic != nil {
            aeromatPeripheral.readValue(for: aeromatPaircodeCharacteristic)
        }
    }
    
    @IBAction func stopAction(_ sender: UIButton) {
        aeromatPeripheral.writeValue("STP".data(using: .utf8)!,
                                     for: aeromatCommandCharacteristic,
                                     type: CBCharacteristicWriteType.withoutResponse)
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central state is unknown")
        case .resetting:
            print("central state is resetting")
        case .unsupported:
            print("central state is unsupported")
        case .unauthorized:
            print("central state is unauthorized")
        case .poweredOff:
            print("central state is poweredoff")
        case .poweredOn:
            print("central state is poweredon")
            centralManager.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Aeromat BT" {
            print("Found aeromat controller:", peripheral)
            aeromatPeripheral = peripheral
            aeromatPeripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(aeromatPeripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected!")
        aeromatPeripheral.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == aeromatServiceCBUUID {
                print("Found aeromat service:", service)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid {
            case aeromatIDCharacteristicCBUUID:
                aeromatIDCharacteristic = characteristic
                print("Found ID characteristic")
                peripheral.readValue(for: characteristic)
            case aeromatIPCharacteristicCBUUID:
                aeromatIPCharacteristic = characteristic
                print("Found IP characteristic")
                peripheral.readValue(for: characteristic)
            case aeromatSSIDCharacteristicCBUUID:
                aeromatSSIDCharacteristic = characteristic
                print("Found SSID characteristic")
                peripheral.readValue(for: characteristic)
            case aeromatPaircodeCharacteristicCBUUID:
                aeromatPaircodeCharacteristic = characteristic
                print("Found Paircode characteristic")
            case aeromatPressureCharacteristicCBUUID:
                aeromatPressureCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Found Pressure characteristic")
            case aeromatCommandCharacteristicCBUUID:
                aeromatCommandCharacteristic = characteristic
                print("Found Command characteristic")
            default:
                print("Found unknown characteristic:", characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let valStr = String(data: characteristic.value!, encoding: .utf8)
        switch characteristic.uuid {
        case aeromatIDCharacteristicCBUUID:
            idLabel.text = valStr ?? "?"
            print("ID: \(valStr ?? "?")")
        case aeromatIPCharacteristicCBUUID:
            ipLabel.text = "IP: \(valStr ?? "?")";
            print("IP: \(valStr ?? "?")")
        case aeromatSSIDCharacteristicCBUUID:
            ssidLabel.text = "SSID: \(valStr ?? "?")";
            print("SSID: \(valStr ?? "?")")
        case aeromatPaircodeCharacteristicCBUUID:
            print("Paircode: \(valStr ?? "?")")
        case aeromatPressureCharacteristicCBUUID:
            print("Pressure: \(valStr ?? "?")")
            let pressureArr = valStr!.components(separatedBy: " ")
            if pressureArr.count == 8 {
                lSNLabel.text = pressureArr[1]
                rSNLabel.text = pressureArr[3]
                tSNLabel.text = pressureArr[5]
                bSNLabel.text = pressureArr[7]
            }
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

