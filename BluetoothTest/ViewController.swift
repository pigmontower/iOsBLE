//
//  ViewController.swift
//  BluetoothTest
//
//  Created by 山本真寛 on 2020/03/21.
//  Copyright © 2020 山本真寛. All rights reserved.
//

import UIKit
import CoreBluetooth

// ペリフェラル：スキャンで発見される側のデバイス
//      ->ペリフェラルは1つ以上のサービスを持つ
//          ->サービスは1つ以上のキャラクタリスティックを持つ
//              ->キャラクタリスティックのvalueにはデータが格納されている
//      ex) ほとんどのケースでは、スマートウォッチとかイヤホンなどの周辺機器
// セントラル：スキャン・接続を行う側のデバイス（高度な処理が要求されないため、コストを抑えられる）
//      ->セントラルはペリフェラルに対して以下を行う
//          ->スキャン
//              ->スキャン結果を受け取るにはCBCentralManagerDelegateを実装
//          ->接続
//          ->サービス一覧を取得
//          ->キャラクタリスティック一覧を取得
//              ->サービス・キャラクタリスティックの一覧を取得するにはCBPeripheralDelegateを実装
//          ->データを読み出す(Read)
//              ->キャラクタリスティックのvalueを取得する
//          ->データを書き込む(Write)
//              ->Write権限のあるキャラクタリスティックのvalueを変更する
//      ex) ほとんどのケースでは、スマホ
class ViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate {

    // スキャンや接続などを行うクラス
    var centralManager: CBCentralManager!
    
    // 周辺デバイス = ペリフェラル
    // ⭐️ペリフェラルの仕様は「3-8.GAPの詳細を知る」参照
    var peripheral: CBPeripheral!
    
    // UI用
    var isScanning = false
    var scanButton :UIButton!
    var tempButton :UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        initUi()
    }
    
    // ▶️周辺デバイス(= ペリフェラル)のスキャン
    @objc func scanTapped(_ sender: UIButton){
        
        if !isScanning {
            isScanning = true
            scanButton.setTitle("stop scanning", for: UIControl.State.normal)
            // ▶️初期化 = スキャンできるようにする = 自分自身をセントラルにする
            // ▶️スキャンできるようになった = セントラル化に成功したら▶️centralManagerDidUpdateStateに処理がいく
            // ⭐️第二引数の詳細は「6-4.イベントディスパッチ用のキューを変更する（セントラル）」を参照
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            isScanning = false
            scanButton.setTitle("start scanning", for: UIControl.State.normal)
            // スキャン停止
            // スキャンは自動的に停止しないため、タイムアウト時間を設けるなり、停止ボタンを提供するなどする必要がある
            // ⭐️「6-1-1.スキャンを明示的に停止する」参照
            self.centralManager.stopScan()
        }
    }
    
    // 画面切り替え
    @objc func tempTapped(_ sender: UIButton){
        //次の画面をモーダル表示
        let webViewController = PeripheralViewController()
        self.present(webViewController, animated: true, completion: {
        //ボタンが押され終わった後の処理
//        self.view.backgroundColor = UIColor.yellow
        })
                
    }
    
    // ▶️CBCentralManagerの状態が変化すると、このメソッドが呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            // この状態になっているとスキャン等を開始できる
            // 以下のタイプはdeplecatedになっていた
            // CBCentralManagerStatePoweredOn
            // https://developer.apple.com/documentation/corebluetooth/cbcentralmanagerstate/cbcentralmanagerstatepoweredon?language=objc
            // https://forums.developer.apple.com/thread/51222
            // http://harumi.sakura.ne.jp/wordpress/2018/11/05/ble-scan/
            print("scan可能: \(central.state)")
            
            // ▶️スキャン可能なので、スキャン開始
            // ⭐️スキャンの詳細は「3-4-5.AdvertisingとScanning」参照
            // ⭐️第二引数は、基本的にnilが推奨
            // ⭐️-----理由start------
            // ⭐️スキャンによって検出したペリフェラルが検出済みであろうとなかろうと都度検出してしまう
            // ⭐️ペリフェラルは一定時間赫赫で何度もアドバタイズパケットを送信するため、基本はnilが推奨
            // ⭐️なお、nilにしても、アドバタイズ内容が変わったら再度検出される
            // ⭐️「6-1-3.できるだけスキャンの検出イベントをまとめる」
            // ⭐️-------理由end--------
            // ⭐️第一引数にnilを渡す場合は、全てのサービスをスキャン対象にする
//            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            // ⭐️第一引数にUUIDを渡す場合は、UUIDに該当するサービスだけをスキャン対象にする「6-1-2.特定のサービスを指定してスキャンする」参照
//            let scanningServiceUUIDs = [CBUUID(string: "2214")]
            let scanningServiceUUIDs = [CBUUID(string: "05A89E8A-9EF7-45C0-9E4C-7C0B8BCF9529")]
            self.centralManager.scanForPeripherals(withServices: scanningServiceUUIDs, options: nil)
            // ▶️スキャンに成功すると以下にいく
            // ▶️centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
            
        default:
            print("scan不可能: \(central.state)")
        }
    }
    
    // ▶️周辺にあるデバイス(=ペリフェラル)が見つかると呼ばれる（このメソッドは周辺デバイスが見つかるたびに呼ばれる）
    // ⭐️同じペリフェラルが複数回見つかっても、その都度このメソッドが呼ばれるようにするかはスキャン開始時のoptionで決まる。「6-1-3.できるだけスキャンの検出イベントをまとめる」
    // 第二引数：didDiscover peripheral -> 発見したデバイス
    // 第三引数：advertisementData -> アドバタイズメントデータ。以下を参照
    // ⭐️「5-1.セントラルから発見されるようにする（アドバタイズの開始）」「5.3.サービスをアドバタイズする」「8-4.アドバタイズメントデータ詳解」参照
    // 第四引数：rssi RSSI -> 受信信号強度（Received Signal Strength Indicotor)を表すNSNumberオブジェクトが入ってくる
    // RSSIの単位はデシベルで、対数表現のためマイナス値をとる。信号強度はデバイス間の距離によって減衰するため、本値はペリフェラルまでの近接度を判断に利用される
    // CBPeripheralのreadRSSIメソッドで取得することも可能
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //　⭐️関連：「8-5.CBPeripheralのnameが示すデバイス名について」
        // 周囲にあるデバイス = ペリフェラル
        print("発見したデバイス: \(peripheral)")
        
        // 発見したCBPeripheralオブジェクトを解放されてしまわないように、保持しておく
        // ⭐️参照を保持しないと発生するトラブルは「11.ハマりどころ逆引き辞典 - トラブル2:接続に失敗する」参照
        self.peripheral = peripheral
        // ▶️接続開始
        // ⭐️optionは「7-4.バックグラウンド実行モードを使用せず、バックグラウンドでのイベントの発生をアラート表示する」参照
        // ▶️接続に失敗すると▶️func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
        // ▶️接続に成功すると▶️func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.centralManager.connect(self.peripheral, options: nil)
    }
    
    // ▶️ペリフェラルへの接続が失敗すると呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("接続失敗 \(String(describing: error))")
    }
    
    // ▶️ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        // 接続の必要がなくなり次第、すぐに接続を切断することが推奨されている
        // ⭐️「切断方法は6-3-1.接続の必要が無くなり次第すぐに切断する/ ペンディングされている接続要求をキャンセルする」参照
        
        // サービス一覧取得結果を受け取るためのデリゲート
        self.peripheral.delegate = self
        // ▶️サービス一覧取得開始
        // ⭐️nilを渡す場合は全てのサービスが探索結果となる。必要なサービスのみ探索するには「6-2-1.必要なサービスのみ探索する」参照
//        self.peripheral.discoverServices(nil)
        // ⭐️UUIDを渡す場合は、UUIDに該当するサービスだけがヒットするようになる「6-2-1.必要なサービスのみ検索する」参照
//        let searchTargetServiceUUIDs = [CBUUID(string: "2214")]
        let searchTargetServiceUUIDs = [CBUUID(string: "05A89E8A-9EF7-45C0-9E4C-7C0B8BCF9529")]
        self.peripheral.discoverServices(searchTargetServiceUUIDs)
        // ▶️サービス結果取得後は▶️func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {へ
        
    }
    
    // ▶️サービス一覧取得時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            print("\(services.count)個のサービスを発見: \(services)")
            for service in services {
                // ▶️キャラクタリスティック一覧取得
                // 第一引数には探索対象のキャラクタリスティックのUUIDを配列で渡せるが、nilを渡す場合は全てのキャラクタリスティックが対象となる
                // ⭐️「6-2-2.必要なキャラクタリスティックのみ探索する」参照
                // 第二引数にはどのサービスについて探索するかを指定
                peripheral.discoverCharacteristics(nil, for: service)
                // ⭐️第一引数にUUIDを渡す場合は、該当するキャラクタリスティックだけを検索対象にする「6-2-2.必要なキャラクタリスティックのみ探索する」参照
//                    let searchTargetCharacteristicUUIDs = [CBUUID(string: "8618")]
//                    let searchTargetCharacteristicUUIDs = [CBUUID(string: "E7606478-43D6-46B6-93A9-C2BD46F11ADC")]
//                    peripheral.discoverCharacteristics(searchTargetCharacteristicUUIDs, for: service)
                // ▶️キャラクタリスティック一覧取得後は▶️peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            }
        }
    }
    
    // ▶️キャラクタリスティック一覧取得時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("\(characteristics.count)個のキャラクタリスティックを発見 \(characteristics)")
            for characteristic in characteristics {
                // ▶️Readに対応するキャラクタリスティックを読み出す
//                    if ((characteristic.properties & CBCharacteristicProperties.read) != 0) {
                if ((characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0) {
                // Read専用のキャラクタリスティックのみ読み出す場合は以下
//                    if characteristic.properties == CBCharacteristicProperties.read {
                    
//                        print("読み出しリクエスト 8618（レスポンスあり）")
                    print("読み出しリクエスト E7606478-43D6-46B6-93A9-C2BD46F11ADC（レスポンスあり）")
                    // ▶️キャラクタリスティックのvalueを取得
                    // ▶️value取得後は▶️peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
                    peripheral.readValue(for: characteristic)
                }
                // ▶️Writeに対応するキャラクタリスティックに書き込みを行う
                // ⭐️writeに関する仕様は「3-9.ATTとGATTの詳細を知る」、「3-10.GATTとService」を参照
                if ((characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0) {
                    // ⭐️CBCharacteristicProperties.write.rawValueの場合は、書き込み完了レスポンスあり
//                        print("書き込みリクエスト 8618（レスポンスあり）")
                    print("書き込みリクエスト E7606478-43D6-46B6-93A9-C2BD46F11ADC（レスポンスあり）")
                    // 書き込み対象データ（結果レスポンスなし）
                    let nsdata = "test write with response".data(using: String.Encoding.utf8)!
                    // 第一引数：書き込み対象データ
                    // 第二引数：データ書き込みを行う対象のキャラクタリスティック
                    // 第三引数：以下のいずれか
                    //      .withResponse -> 書き込み完了時にデリゲートメソッドが呼ばれる
                    //      .withoutResponse -> 書き込み完了時にデリゲートメソッドが呼ばれない
                    // ▶️.withResponseを指定し、かつ書き込み成功時は▶️peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {へ
                    peripheral.writeValue(nsdata, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                } else if ((characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0) {
                    // ⭐️CBCharacteristicProperties.writeWithoutResponse.rawValueの場合は、書き込み完了レスポンスなし
//                        print("書き込みリクエスト 8618（レスポンスなし）")
                    print("書き込みリクエスト E7606478-43D6-46B6-93A9-C2BD46F11ADC（レスポンスなし）")
                    // 書き込み対象データ（結果レスポンスあり）
                    let nsdata = "test write without response".data(using: String.Encoding.utf8)!
                    // ▶️.withoutResponseを指定した場合、書き込み成功時は通知されない
                    peripheral.writeValue(nsdata, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                }
                // ▶️Notifyに対応するキャラクタリスティックに書き込みを行う
                // Notifyはペリフェラルからデータの更新通知を受け取り、データ自体も受け取ること
                // Readとの違いは、セントラルがデータを受け取るトリガーがペリフェラル側にあること
                // ⭐️writeに関する仕様は「3-9.ATTとGATTの詳細を知る」、「3-10.GATTとService」を参照
                if ((characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0) {
//                        print("Notify（データ更新通知受け取り）リクエスト 8618（レスポンスあり）")
                    print("Notify（データ更新通知受け取り）リクエスト E7606478-43D6-46B6-93A9-C2BD46F11ADC（レスポンスあり）")
                    // ▶️Notifyリクエストを送信
                    //
                    // ▶️データ更新通知受け取り開始/停止処理がペリフェラル側で受け付けると▶️peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {へ
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    // ▶️Notify（データ更新通知受け取り）の開始/停止処理がペリフェラル側で受け付けた時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Notify（データ更新通知受け取り）状態更新失敗 error: \(String(describing: error))")
        } else {
            // ▶️Notify（データ更新String(describing: 通知)受け取り）リクエスト中のデータが更新された時は
            // ▶️peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            print("Notify状態更新成功 isNotifying: \(characteristic.isNotifying)")
        }
    }
    
    // ▶️キャラクタリスティックのvalueを取得した時に呼ばれる(パターンは以下)
    // ▶️->Readの成功時
    // ▶️->Notify（データ更新通知受け取り）リクエスト中のデータが更新された時
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            print("読み出し失敗 service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid), value:\(String(describing: characteristic.value)) error:\(String(describing: error))")
            return
        }
        
        // ⭐️ここでString(describing: 取)得するvalueはNSData型のため、ペリフェラルの仕様に応じてStringやIntなどに変換しないと、何を表しているかわからない
        print("読み出し成功 service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid), value:\(String(describing: characteristic.value)) プロパティ \(characteristic.properties)")
        
        // 読み取ったvalueを、stringに変換（ここではキャラクタリスティックが8618の時だけstringにしている）
        // 読み取ったvalueを、stringに変換（ここではキャラクタリスティックがE7606478-43D6-46B6-93A9-C2BD46F11ADCの時だけstringにしている）
        // ⭐️uuidの型はCBUUIDであることに注意
//        if characteristic.uuid.isEqual(CBUUID(string: "8618")) {
        if characteristic.uuid.isEqual(CBUUID(string: "E7606478-43D6-46B6-93A9-C2BD46F11ADC")) {
            // NSData -> String
            if let characteristicValueNSData = characteristic.value {
                let str : String = String.init(data: characteristicValueNSData, encoding: .utf8)!
//                print("characteristic 8618 value is converted!! \(str)")
                print("characteristic E7606478-43D6-46B6-93A9-C2BD46F11ADC value is converted!! \(str)")
            }
        }
        
        // Nofifyの場合、ここでNotifyを停止
        // ⭐️これは必須ではなく、テストするために実装
        if ((characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0) {
            print("Notify停止要求")
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
    
    // ▶️キャラクタリスティックの更新に成功した時に呼ばれる※.withResponseを指定した場合
    // ▶️->Writeの成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("書き込み完了通知受信")
        // ⭐️ここでcharacteristicのvlueは、書き込み後の値が反映されていないため、使用すべきではない
        // ⭐️書き込み後の値を取得したければ、改めてreadするか、notifyを利用すること
        // 「11.ハマりどころ逆引き辞典 - トラブル5:キャラクタリスティックの値がおかしい」参照
    }
    
    private func initUi(){

        self.view.backgroundColor = UIColor.white
    
        // ラベル
        let titleLabel = UILabel()
        titleLabel.text = "1Central = スキャン側"
        self.view.addSubview(titleLabel)

        //制約
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 88.0).isActive = true

        // スキャンボタン
        scanButton = UIButton()
        scanButton = UIButton(type: UIButton.ButtonType.system)
        if isScanning {
            scanButton.setTitle("stop scanning", for: UIControl.State.normal)
        } else {
            scanButton.setTitle("start scaning", for: UIControl.State.normal)
        }
        scanButton.backgroundColor = UIColor.blue
        scanButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.view.addSubview(scanButton)

        //制約
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
        scanButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
        scanButton.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 88.0).isActive = true
        scanButton.addTarget(self, action: #selector(scanTapped(_:)), for: .touchUpInside)

        // ペリフェラル<->セントラル切り替え
        tempButton = UIButton()
        tempButton = UIButton(type: UIButton.ButtonType.system)
        tempButton.setTitle("change roll", for: UIControl.State.normal)
        tempButton.backgroundColor = UIColor.blue
        tempButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.view.addSubview(tempButton)

        //制約
        tempButton.translatesAutoresizingMaskIntoConstraints = false
        tempButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
        tempButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
        tempButton.topAnchor.constraint(equalTo: self.scanButton.topAnchor, constant: 88.0).isActive = true
        tempButton.addTarget(self, action: #selector(tempTapped(_:)), for: .touchUpInside)
    }
}
