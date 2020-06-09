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
class PeripheralViewController: UIViewController,CBPeripheralManagerDelegate {

    //
    var peripheralManager: CBPeripheralManager!
    
    var characteristic1: CBMutableCharacteristic!
    
    // UI用
    var isAdvertising = false
    var scanButton :UIButton!
    var tempButton :UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        initUi()
    }
    
    // ▶️ペリフェラル化
    @objc func advertiseTapped(_ sender: UIButton){
        
        if !isAdvertising {
            isAdvertising = true
            // 自身をペリフェラルにする
            // ⭐️第二引数：「6-6.イベントディスパッチ用のキューを変更する（ペリフェラル）」
            // ⭐️第三引数：「7-3.アプリが停止しても、代わりにタスクを実行するようシステムに要求する（状態の保存と復元）」
            //　と「8-2.Bluetoothがオフの場合にユーザーにアラートを表示する」参照
            // ▶️ペリフェラル化に成功したら▶️peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {へ
            self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        } else {
            isAdvertising = false
            // ▶️アドバタイズの停止（停止成功時のデリゲートはなし）
            self.peripheralManager.stopAdvertising()
        }
    }
    
    // ▶️ペリフェラルマネージャの状態が変化したときに呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("state: \(peripheral.state)")
        
        // ▶️アドバタイズ = 自分の存在をセントラルに知らせるために電波を発すること
        // ⭐️アドバタイズの仕様詳細は「3-4-5.AdvertisingとScanning」
        // ローカルネーム = セントラル側で目的のペリフェラルかどうかを判定するために使用される
//        let localName = "TestDevice yamayama"
        let localName = "TestDeviceYamayama"
        // ⭐️オプション：アドバタイズ時に、事前にどんなサービスを提供しているかを知らせたい時はアドバタイズにサービスのUUIDを含めることができる
        // セントラルがスキャンしたペリフェラルのうち、目的のサービスを提供しているかをフィルタリングするために利用
        // ⭐️ただし、これを追加しても、セントラル側でどう絞り込めばいいかわからなかった。
        //      ⭐️->解決discoverServicesにserviceのUUIDを渡せばいい「6-1-2」「6-2-1」参照
//        let supplyingServiceUUIDs = [CBUUID(string: "2214")]
        let supplyingServiceUUIDs = [CBUUID(string: "05A89E8A-9EF7-45C0-9E4C-7C0B8BCF9529")]
        // ⭐️他のキーやアドバタイズメントデータに関しての詳細は「8-4.アドバタイズメントデータ詳解」で参照
        let testAdvertisementData = [CBAdvertisementDataLocalNameKey: localName, CBAdvertisementDataServiceUUIDsKey: supplyingServiceUUIDs] as [String : Any]
        // アドバタイズの開始
        // ▶️アドバタイズ成功時は▶️peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {へ
        self.peripheralManager.startAdvertising(testAdvertisementData)
    }
    
    // ▶️アドバタイズ成功時に呼ばれる
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("アドバタイズ成功")
        
        // サービスを生成
        // キャラクタリスティックを追加するため、mutableなサービスであるCBMutableServiceを生成
        // 第一引数は生成するサービスのUUID
        // 実際には128ビットのUUIDを用意する必要がある
        // ⭐️128ビットにしないといけない理由は「8-3.UUID詳解」->BlueToogh SIGが割り当てを決めているため
        // ⭐️128ビットのUUIDの静止絵方法は「10-1.128ビットUUIDを生成するコマンドuuidgen」参照
        // 第二引数はtrueならプライマリサービスに、falseならセカンダリサービスになる
        // ⭐️詳細は「8-7.サービスに他のサービスを組み込む〜「プライマリサービス」と「セカンダリサービス」」参照
//        let serviceUUID = CBUUID(string: "2214")
        let serviceUUID = CBUUID(string: "05A89E8A-9EF7-45C0-9E4C-7C0B8BCF9529")
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // キャラクタリスティックを生成
        // 値を更新するため、mutableなキャラクタリスティックであるCBMutableCharacteristicを生成
        // 第一引数は生成するキャラクタリスティックのUUID
        // 第二引数はread/write/notifyなど、キャラクタリスティックでできること(キャラクタリスティックのプロパティ）を指定
        // ⭐️複数のプロパティを論理和で指定できる
        // 第三引数はキャラクタリスティックの値を指定する
        // ⭐️nilを指定すると、キャラクタリスティックの値を動的に更新することを意味する
        // ⭐️NSDataオブジェクトを渡すと、静的な値を持つことになる「8-6.静的な値を持つキャラクタリスティック」を参照
        // 第四引数は生成するキャラクタリスティックのパーミッションを指定
        // ⭐️複数のパーミッションを論理和で指定できる
        // ⭐️とりあえずここではセントラルにこのキャラクタリスティックを読み込むことを許可するCBAttributePermissions.readableを指定
        // ⁉️⁉️⁉️第二引数=p249と第四引数=p250の違いがわからない⁉️⁉️⁉️
//        let characteristicUUID = CBUUID(string: "8618")
        let characteristicUUID = CBUUID(string: "E7606478-43D6-46B6-93A9-C2BD46F11ADC")
        // ⭐️プロパティ設定（ビット演算の論理和）
        //      read -> 読み込み
        //      write -> 書き込み（完了時にデリゲートメソッドが呼ばれる）
        //      writeWithoutResponse -> 書き込み（完了時にデリゲートメソッドが呼ばれない）
        //      notify -> ペリフェラルからのデータ更新通知（パーミッションはreadで良い）
        // ⭐️writeに関する仕様は「3-9.ATTとGATTの詳細を知る」、「3-10.GATTとService」を参照
        let properties = CBCharacteristicProperties(rawValue: CBCharacteristicProperties.read.rawValue | CBCharacteristicProperties.writeWithoutResponse.rawValue | CBCharacteristicProperties.notify.rawValue)
        // ⭐️パーミッション設定（ビット演算の論理和）
        let permissions = CBAttributePermissions(rawValue: CBAttributePermissions.readable.rawValue | CBAttributePermissions.writeable.rawValue)
//        characteristic1 = CBMutableCharacteristic(type: characteristicUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        characteristic1 = CBMutableCharacteristic(type: characteristicUUID, properties: properties, value: nil, permissions: permissions)
        
        // サービスにキャラクタリスティックを追加(配列で複数指定可)
        service.characteristics = [characteristic1]
        
        // ペリフェラルにサービスを追加
        // ⭐️addServiceを呼ぶタイミングによっては、サービス追加が行われない場合がある詳細は「11.ハマりどころ逆引き辞典　ートラブル3:サービスまたは...」参照
        self.peripheralManager.add(service)
        
        // キャラクタリスティックのvalueにデータを追加
        // ⭐️peripheralManager.add(service)する前に呼ぶと実行エラーになるので注意
        // String -> Data
        let data1 : Data = "Characteristic value test".data(using: String.Encoding.utf8)!
        // Data -> NSData
        // 参考 -> https://program-life.com/1498
        let nsdata : NSData = NSData.init(data: data1)
        characteristic1.value = nsdata as Data

        // ▶️サービス追加成功時は▶️peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    }
    
    // ▶️サービス追加成功時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if (error != nil) {
            print("サービス追加失敗 error: \(String(describing: error))")
            return
        }
        print("サービス追加成功")
    }
        
    // ▶️Readリクエストを受け取った時に呼ばれる
    // 第二引数はセントラルからのReadリクエストを示すCBATTRequest
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Readリクエスト受信 requested service uuid: \(request.characteristic.service.uuid) characteristic uuid: \(request.characteristic.uuid) value:\(String(describing: request.characteristic.value))")
        
        // ⭐️uuidの型はCBUUIDであることに注意
        if request.characteristic.uuid.isEqual(characteristic1.uuid) {
            print("Readリクエストに応答しまーす")
            request.value = self.characteristic1.value
            self.peripheralManager.respond(to: request, withResult: CBATTError.success)
//            self.peripheralManager.respond(to: request, withResult: CBATTError.requestNotSupported)
        }
    }
    
    // ▶️Writeリクエストを受け取った時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        print("\(requests.count)件のwriteリクエストを受信　書き込みます 8618")
        print("\(requests.count)件のwriteリクエストを受信　書き込みます E7606478-43D6-46B6-93A9-C2BD46F11ADC")
        
        // 書き込み開始
        for request in requests {
            if request.characteristic.uuid.isEqual(self.characteristic1.uuid) {
                
                // テスト用
                if let characteristicValueNSData = request.value {
                    let str : String = String.init(data: characteristicValueNSData, encoding: .utf8)!
//                        print("書き込みリクエストの値 8618  \(str)")
                    print("書き込みリクエストの値 E7606478-43D6-46B6-93A9-C2BD46F11ADC  \(str)")
                }
                
                // リクエストの書き込み内容をキャラクタリスティックに反映
                self.characteristic1.value = request.value
//                    print("書き込み完了 8618")
                print("書き込み完了 E7606478-43D6-46B6-93A9-C2BD46F11ADC")
            }
        }
        
        // ▶️セントラルに書き込みが成功した旨を通知
        // ⭐️書き込みリクエストが複数件ある場合、requests[0]に対して応答するだけで良い（Appleのガイドによる）
        // ⭐️もし書き込みが完遂できないリクエストが1件でもある場合は、CBATTError.successは返すべきではなく、error系を返却すること
        // ▶️この後、セントラル側はperipheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.peripheralManager.respond(to: requests[0], withResult: CBATTError.success)
//        print("書き込み完了通知送信 8618")
        print("書き込み完了通知送信 E7606478-43D6-46B6-93A9-C2BD46F11ADC")
    }
    
    // ▶️Notify（データ更新通知受け取り）開始リクエストを受け取った時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        // characteristic1.subscribedCentralsには、Notify中のセントラルが自動で入ってくる
        print("Notify開始リクエストを受信 Notify中のセントラル: \(String(describing: self.characteristic1.subscribedCentrals))")
        
        // 値の更新
        let nsdata = "test notify updated".data(using: String.Encoding.utf8)!
        self.characteristic1.value = nsdata
        // セントラルへ更新を通知
        // ⭐️第三引数にnilを渡すと、Notify中の全てのセントラルに通知する。セントラルを指定すると、特定のセントラルのみに通知する
        // ⭐️注意：以下ではあくまでセントラルに通知をするだけで、キャラクタリスティックの更新はしていない。更新はself.characteristic1.value = nsdata
        let isNotifySuccess = self.peripheralManager.updateValue(nsdata, for: self.characteristic1, onSubscribedCentrals: nil)
        print("Notify 成功 \(isNotifySuccess)")
    }
    
    // ▶️Notify（データ更新通知受け取り）開始リクエストを受け取った時に呼ばれる
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        // これを受け取った時点で自動的にNotifyは停止される
        print("Notify停止リクエスト受信 Notify中のセントラル \(String(describing: self.characteristic1.subscribedCentrals))")
    }
    
    // 画面切り替え
    @objc func tempTapped(_ sender: UIButton){
        //次の画面をモーダル表示
        let webViewController = ViewController()
        self.present(webViewController, animated: true, completion: {
        //ボタンが押され終わった後の処理
//        self.view.backgroundColor = UIColor.yellow
        })
                
    }
    
    private func initUi(){

        self.view.backgroundColor = UIColor.white
    
        // ラベル
        let titleLabel = UILabel()
        titleLabel.text = "Peripheral = スキャンされる側"
        self.view.addSubview(titleLabel)

        //制約
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 88.0).isActive = true

        // スキャンボタン
        scanButton = UIButton()
        scanButton = UIButton(type: UIButton.ButtonType.system)
        if isAdvertising {
            scanButton.setTitle("stop advertising", for: UIControl.State.normal)
        } else {
            scanButton.setTitle("start advertising", for: UIControl.State.normal)
        }
        scanButton.backgroundColor = UIColor.purple
        scanButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.view.addSubview(scanButton)

        //制約
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
        scanButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
        scanButton.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 88.0).isActive = true
        scanButton.addTarget(self, action: #selector(advertiseTapped(_:)), for: .touchUpInside)

        // ペリフェラル<->セントラル切り替え
        tempButton = UIButton()
        tempButton = UIButton(type: UIButton.ButtonType.system)
        tempButton.setTitle("change roll", for: UIControl.State.normal)
        tempButton.backgroundColor = UIColor.purple
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
