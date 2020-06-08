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
            print("サービス追加失敗 error: \(error)")
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
        for obj in requests {
            if let request = obj as? CBATTRequest {
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
        print("Notify開始リクエストを受信 Notify中のセントラル: \(self.characteristic1.subscribedCentrals)")
        
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
        print("Notify停止リクエスト受信 Notify中のセントラル \(self.characteristic1.subscribedCentrals)")
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
    
    
    //
    
//    var rxTableView = UITableView()
//    var testTableItems: [String] = ["茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県"]
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

        //
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
//
//        // --------------------------------------------
//
//
//        // ＜＜Observableオブジェクトの生成と監視3＞＞
//        // Observableを直接生成しないケース：
//        //     RxSwiftではUIなどからすぐに利用できるObservableが存在するため、それを利用
//        let ovservableSwitch = UISwitch()
//        ovservableSwitch.isOn = true
//        self.view.addSubview(ovservableSwitch)
//        ovservableSwitch.translatesAutoresizingMaskIntoConstraints = false
//
//        ovservableSwitch.widthAnchor.constraint(equalTo: observableButton.widthAnchor, multiplier: 1.0).isActive = true
//        ovservableSwitch.topAnchor.constraint(equalTo: observableButton.bottomAnchor, constant: 10).isActive = true
//        ovservableSwitch.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//
//        // Observableの生成と監視
//        let observable_switch_tap_Jikkousha_Shuppannsha = ovservableSwitch.rx.isOn
//        let tapDisposal = observable_switch_tap_Jikkousha_Shuppannsha.subscribe(
//            onNext:{ bool in
//                print(bool ? "ON" : "OFF")
//            },
//            onCompleted: {
//                print("completed")
//            }
//        )
//        tapDisposal.disposed(by: disposeBag)
//        // 以下のようにメソッドチェーンで書く方がわかりやすい
////        testSwitch.rx.isOn.subscribe(
////            onNext:{ bool in
////                print(bool ? "ON" : "OFF")
////            },
////            onCompleted: {
////                print("completed")
////            }
////        ).disposed(by: disposeBag)
//
//
//
//        // --------------------------------------------
//
//        // ＜＜データバインド＞＞
//        // Observableを直接生成しないケース：
//        //     RxSwiftではUIなどからすぐに利用できるObservableが存在するため、それを利用
//        // textFieldの値とlabeの値をバインディングしている（入力したら即時反映）
//        let databindTextField = UITextField()
//        databindTextField.borderStyle = UITextField.BorderStyle.bezel
//        databindTextField.textAlignment = NSTextAlignment.right
//        databindTextField.placeholder = "databindTextField"
//        databindTextField.keyboardType = UIKeyboardType.default
//        databindTextField.returnKeyType = UIReturnKeyType.default
////            self.textField.delegate = self
//        self.view.addSubview(databindTextField)
//
//        //制約
//        databindTextField.translatesAutoresizingMaskIntoConstraints = false
////        databindTextField.widthAnchor.constraint(equalTo: observableButton.widthAnchor, multiplier: 1.0).isActive = true
//        databindTextField.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
//        databindTextField.topAnchor.constraint(equalTo: ovservableSwitch.bottomAnchor, constant: 10).isActive = true
//        databindTextField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//
//        // ラベルを定義
//        let databindLabel = UILabel()
//        databindLabel.text = "databindLabel"
//        self.view.addSubview(databindLabel)
//
//        //制約
//        databindLabel.translatesAutoresizingMaskIntoConstraints = false
//        databindLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0).isActive = true
//        databindLabel.heightAnchor.constraint(equalTo: databindTextField.heightAnchor, multiplier: 1.0).isActive = true
//        databindLabel.topAnchor.constraint(equalTo: databindTextField.bottomAnchor, constant: 10).isActive = true
//        databindLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//
//        // Observableの生成と監視
//        let observable_button_text_Jikkousha_Shuppannsha = databindTextField.rx.text
//        let bindDisposal = observable_button_text_Jikkousha_Shuppannsha.bind(to:databindLabel.rx.text)
//        bindDisposal.disposed(by: disposeBag)
//        // シンプルに書くなら以下
////        databindTextField.rx.text
////                   .bind(to:testLabel.rx.text)      // bund(_:)メソッドで2つの値を結合
////                   .disposed(by: disposeBag)        // 解放
//
//
//        // --------------------------------------------
//
//
//        // ＜＜Observableオブジェクトの生成と監視2＞＞
//
//        // ＜オペレータ（概要）＞
//        // データストリームは配列として扱える。
//        // その配列の要素を操作するメソッドをオペレーターと呼びます
//        // filter:条件に合致したもの以外を廃棄
//        // merge:複数のデータストリームを統合
//        // map:別のデータストリームを任意の型で変換
//        // flatMap:別のデータストリームをObservableとして変換。イベントが発生すると、処理が完了していない前のデータストリームをキャンセルしない
//        // flatMapLatest:別のデータストリームをObservableとして変換。イベントが発生すると、処理が完了していない前のデータストリームをキャンセルする
//        // zip:複数のデータストリームが存在する場合に全ての処理が終わるまで待って統合????
//        // flatMapは理解できなかったので、以下を参考にした
//        // https://qiita.com/crea/items/d46360e1eac709d6a632
//        // https://qiita.com/shintax/items/9f3f7452e4fb0a6ed78a
//        // orEmptyで、空文字なら後続をスキップさせる
//        let observable_operator_Jikkousha_Shuppannsha = databindTextField.rx.text.orEmpty
//        let disposal_operator = observable_operator_Jikkousha_Shuppannsha
//            .filter { text in  text.count >= 3 }             // 条件に合致したもの以外を廃棄
////            .filter { $0.count >= 3 }                      // 条件に合致したもの以外を廃棄
//            .map { text in "入力した文字数は\(text.count)です"}  // 別のデータストリームを任意の型で変換
////            .map { "入力した文字数は\($0.count)です"}          // 別のデータストリームを任意の型で変換
//            .bind(to: databindLabel.rx.text)                     // データバインド
//        disposal_operator.disposed(by: disposeBag)
//        //シンプルに書くなら以下
////        databindTextField.rx.text.orEmpty
////            .filter { $0.count >= 3 }                // 制限
////            .map { "入力した文字数は＼\($0.count)です"}  // 加工
////            .bind(to: testLabel.rx.text)             // 結合
////            .disposed(by: disposeBag)
//
//
//        // --------------------------------------------
//
//
//        // ＜＜オペレータ（詳細）＞＞
//        let observable_ope1 = Observable.of(1, 2, 3)
//        // 値が変わる（イベントが発生する）度に実行される。当然、mapからfilterまで実行してから次のイベントが発生
//        // 出力結果：2 20 20 4 40 40 6 60
//        let observable_ope1_disposal1 = observable_ope1
//            .map { $0 * 2 }
//            .do(onNext: { print("map \($0)") })// 2 4 6
//            .flatMap { Observable.just($0 * 10) }   //flatMap:別のデータストリームをObservableとして変換。イベントが発生すると、処理が完了していない前のデータストリームをキャンセルしない
//            .do(onNext: { print("flatMap \($0)") }) // 20 40 60
//            .filter { $0 <= 50 }
//            .do(onNext: { print("filter \($0)") }) // 20 40
//            .subscribe()        // 購読開始
//        observable_ope1_disposal1.disposed(by: disposeBag)
//
//        // merge:複数のデータストリームを統合
//        let observable_a = Observable.of("a1", "a2", "a3", "a4")
//        let observable_b = Observable.of("b1", "b2", "b3")
//        let observable_ope1_disposal2 = Observable.merge(observable_a, observable_b)
//            .do(onNext: { print("merge \($0)") }) // a1 b1 a2 b2 a3 b3 a4
//            .subscribe()
//        observable_ope1_disposal2.disposed(by: disposeBag)
//
//        // zip:複数のデータストリームが存在する場合に同じインデックスが揃った時に結合
//        let observable_ope1_disposal3 = Observable.zip(observable_a, observable_b) { $0 + $1 }
//            .do(onNext: { print("zip \($0)") }) // a1b1 a2b2 a3b3
//            .subscribe()
//        observable_ope1_disposal3.disposed(by: disposeBag)
//
//        // ????
//        let observable_ope1_disposal4 = Observable.combineLatest(observable_a, observable_b) { $0 + $1 }
//            .do(onNext: { print("combineLatest \($0)") }) // a1b1 a2b1 a2b2 a3b2 a3b3 a4b3
//            .subscribe()
//        observable_ope1_disposal4.disposed(by: disposeBag)
//
//
//        // --------------------------------------------
//
//
//        // ＜＜Driverオブジェクトの生成と監視＞＞
//        // Driverオブジェクトは、UI専用のObservableのようなもの。
//        //     エラー通知はしない（UIはエラーが発生しても処理を止めれないので）
//        //     イベントの通知をメインスレッドで行うため、結果をすぐUIに反映できる
//        var driverButton = UIButton()
//        driverButton = UIButton(type: UIButton.ButtonType.system)
//        driverButton.setTitle("driverButton", for: UIControl.State.normal)
//        driverButton.backgroundColor = UIColor.blue
//        driverButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
//        //hilight
//        driverButton.setTitle("hilight", for: UIControl.State.highlighted)
//        driverButton.setTitleColor(UIColor.red, for: UIControl.State.highlighted)
//        self.view.addSubview(driverButton)
//        let driverSwitch = UISwitch()
//        driverSwitch.isOn = true
//        self.view.addSubview(driverSwitch)
//        driverSwitch.translatesAutoresizingMaskIntoConstraints = false
//
//        //制約
//        driverButton.translatesAutoresizingMaskIntoConstraints = false
//        driverButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
//        driverButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
//        driverButton.topAnchor.constraint(equalTo: databindLabel.bottomAnchor, constant: 10).isActive = true
//        driverSwitch.widthAnchor.constraint(equalTo: observableButton.widthAnchor, multiplier: 1.0).isActive = true
//        driverSwitch.topAnchor.constraint(equalTo: driverButton.bottomAnchor, constant: 10).isActive = true
//        driverSwitch.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//        // Driverの生成と監視
//        let driver_button_tap_Jikkousha_Shuppannsha = driverButton.rx.tap.asDriver()
//        let driverDisposal1 = driver_button_tap_Jikkousha_Shuppannsha.drive(
//            onNext:{
//                print("tap_drive")
//                //次の画面をモーダル表示
////                let webViewController = TabViewController()
////                self.present(webViewController, animated: true, completion: {
////                //ボタンが押され終わった後の処理
////                self.view.backgroundColor = UIColor.yellow})
//            },
//            onCompleted: {
//                print("completed_tap_drive")
//            }
//        )
//        driverDisposal1.disposed(by: disposeBag)
//        // Driverの生成と監視
//        let driver_switch_tap_Jikkousha_Shuppannsha = driverSwitch.rx.isOn.asDriver()
//        let driver_tapDisposal2 = driver_switch_tap_Jikkousha_Shuppannsha.drive(
//            onNext:{ bool in
//                print(bool ? "ON_drive" : "OFF_drive")
//            },
//            onCompleted: {
//                print("completed_switch_drive")
//            }
//        )
//        driver_tapDisposal2.disposed(by: disposeBag)
//
//
//        // --------------------------------------------
//
//
//        // ＜＜Subjectオブジェクトの生成と監視：PublishSubject＞＞
//        // Observableはイベントを定義し、講読するときに発生したイベントに対する対処を行う
//        // Subjectは、生成時にイベント発生時の対処を定義し、あとでイベントを発生させる
//        // 初期化
//        let subject = PublishSubject<String>()
//        // subscribeでイベントが発生した際の処理を先に定義
//        // ※注意：ここでのsubscribeは、Ovservableのsubscribeとは違う
//        // この説明微妙？->PublishSubjectでは講読という意味ではなく、イベント発生時の処理を定義するメソッド
//        // こっちで理解したい->PublishSubjectではsubscribeの時点ではイベントは発生せず、イベント発生時の処理だけ定義
//        let disposalSubject = subject.subscribe(
//            { print($0) }
//        )
//        disposalSubject.disposed(by: disposeBag)
//        // イベントを発生させる
//        subject.on(.next("a"))     // 「next(a)」という文字を出力
//        subject.on(.next("b"))     // 「next(b)」という文字を出力
//        subject.on(.next("c"))     // 「next(c)」という文字を出力
//        subject.onCompleted()  //  「completed」という文字を出力
//        print("bbbb")
//
//
//
//        // --------------------------------------------
//
//
//
//        // ＜＜Subjectオブジェクトの生成と監視：Variable＞＞
//        // valueプロパティで指定する値が変化した時にonNextイベントが発生する
//        // 監視は、一旦Observableに変換して、sbscribeすることで監視開始
//        // Variableクラス自体は、RxSwiftの仕様から削除される予定だが、Variableクラスを採用したRx関連ライブラリが多数存在するため確認
//        // Observableはイベントを定義し、講読するときに発生したイベントに対する対処を行う
//        // Subjectは、生成時にイベント発生時の対処を定義し、あとでイベントを発生させる
//        // 初期値を指定して初期化
//        let variable = Variable<String>("variableText")
//        // Observableに変換
//        let variableObservable = variable.asObservable()
//        // subscribeで監視を開始。
//        let variableDisposal = variableObservable.subscribe(
//            onNext: { print($0)} // この時点でイベントが発生し、初期値の「variableText」が出力される
//        )
//        variableDisposal.disposed(by: disposeBag)
//        // 値を置き換えるとonNextイベントを発生する
//        variable.value = "variableA"  // 「variableA」が出力される
//        variable.value = "variableB"  // 「variableB」が出力される
//
//
//
//        // --------------------------------------------
//
//
//        // ＜＜Subject/Driver/ObservableをUIに連携する例＞＞
//        //制約
//        var subjectTextView = UITextView()      // 入力欄
//        subjectTextView.layer.borderWidth = 1.0
//        self.view.addSubview(subjectTextView)
//        subjectTextView.translatesAutoresizingMaskIntoConstraints = false
//        subjectTextView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
//        subjectTextView.heightAnchor.constraint(equalTo: observableButton.heightAnchor, multiplier: 2.0).isActive = true
//        subjectTextView.topAnchor.constraint(equalTo: driverSwitch.bottomAnchor, constant: 10).isActive = true
//        subjectTextView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//
//        //制約
//        var subjectRestLabel = UILabel()         // 文字数表示ラベル
//        subjectRestLabel.text = "残り文字数"
//        self.view.addSubview(subjectRestLabel)
//        subjectRestLabel.translatesAutoresizingMaskIntoConstraints = false
//        subjectRestLabel.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0).isActive = true
//        subjectRestLabel.topAnchor.constraint(equalTo: subjectTextView.bottomAnchor, constant: 10).isActive = true
//        subjectRestLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
//
//        var subjectButton = UIButton() // 送信ボタン
//        subjectButton = UIButton(type: UIButton.ButtonType.system)
//        subjectButton.setTitle("subjectButton", for: UIControl.State.normal)
//        subjectButton.backgroundColor = UIColor.blue
//        subjectButton.setTitleColor(UIColor.white, for: UIControl.State.normal)
//        self.view.addSubview(subjectButton)
//
//        //制約
//        subjectButton.translatesAutoresizingMaskIntoConstraints = false
//        subjectButton.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.3).isActive = true
//        subjectButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
//        subjectButton.topAnchor.constraint(equalTo: subjectRestLabel.bottomAnchor, constant: 10).isActive = true
//        subjectButton.widthAnchor.constraint(equalTo: observableButton.widthAnchor, multiplier: 1.0).isActive = true
//
//        // 入力テキスト用
//        let inputTextVariagle = Variable<String>("")
//        // 入力欄の内容をinputTextにbind
//        let textViewObservable = subjectTextView.rx.text.orEmpty
//        let dis = textViewObservable.bind(to: inputTextVariagle)
//        dis.disposed(by: disposeBag)    // -------（1）
//
//        // inputTextを監視
//        let variableObservable2 = inputTextVariagle.asObservable()
//        let dis2 = variableObservable2.subscribe(onNext: { [weak self] str in     // -------（2）
//            subjectButton.isEnabled = str.count > 10
//            subjectRestLabel.text = "残り\(200-str.count)文字"
//        })
//        dis2.disposed(by: disposeBag)
//
//        // 送信ボタン押下時に実行される処理を定義
//        let submitTriggerSubject = PublishSubject<Void>()  // 送信処理定義用
//        let dis3 = submitTriggerSubject    // -------（3）
//            .subscribe(onNext: {
//                print("送信処理を実行します")
//             })
//        dis3.disposed(by: disposeBag)
//
//        // 送信ボタン押下時にsubmitTriggerの処理内容を実行
//        let driver = subjectButton.rx.tap.asDriver()
//        let dis4 = driver.drive(submitTriggerSubject)  // -------（4）driveはObserverが引数のメソッドもある driveのonNext通知発生時に Obververのイベントを発生させるっぽい（これは説明ないので、このまま動きで理解しておく）
//        //　⭐️ただ、driverやsubjectを使うメリットはいまいちわからない。ここでは、わざわざsubmitTriggerSubjectを介さずに直接onNextの処理を書けばいい気がする
//        // とりあえず、ここでは使い方と挙動だけ確認し、実際の使い所は、次のサンプルで確認
//        dis4.disposed(by: disposeBag)
//
//
//        // --------------------------------------------
//
//
//        // ＜＜オペレータ（textFieldの値をwikipediaで検索してtableViewに表示する例＞＞
//        // ->失敗して、textFieldの値をwikipediaで検索するだけの例になった
//        // Observableの生成と監視
//        databindTextField.rx.text.orEmpty
//            .filter { $0.count >= 1 }    // -------（1）// 条件に合致したもの以外を廃棄
//            .do(onNext: { print("test1 \($0)") })
//            .map {
//                let urlStr = "https://ja.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=\($0)"
//                return URL(string:urlStr.addingPercentEncoding(withAllowedCharacters:
//                   NSCharacterSet.urlQueryAllowed)!)!
//            }       // -------（2）// 別のデータストリームに変更(URLに変換)
//            .do(onNext: { print("test2 \($0)") })
//            .flatMapLatest {
////                print("oooo \($0)")       // ここに何か書くとコンパイルエラー
////                let aa = ""               // ここに何か書くとコンパイルエラー
//                URLSession.shared.rx.json(url: $0) }    // -------（3）jsonメソッドで通信し、Json型のOvservable型が得、それをデータストリームに変換
//        //flatMapLatest:別のデータストリームをObservableとして変換。イベントが発生すると、処理が完了していない前のデータストリームをキャンセルする
//            .do(onNext: { print("test3 \($0)") })
//            .map { self.parseJson($0) }    // -------（4）Jsonオブジェクトを配列に変換
//            .do(onNext: { print("test4 \($0)") })
//            .subscribe() // ------------------------ bindは実行エラーになるからbindせずにsubscribeにした
////            .bind(to: rxTableView.rx.items(cellIdentifier: "Cell")) { index, result, cell in
////                cell.textLabel?.text = result.title
////                cell.detailTextLabel?.text = "https://ja.wikipedia.org/w/index.php?curid=＼(result.pageid)"
////            }     // -------（5） 本当はtableViewに表示したいが、エラーになったため、とりあえず飛ばす
//            .disposed(by: disposeBag)
//
//
//        // --------------------------------------------
//
//
//        // ＜＜MVVMの実装＞＞
//        // 以下参考サイト
//        // RxSwiftの仕組みを利用して、MVVMモデルを導入しよう
//        // https://codezine.jp/article/detail/11203
//
//        // WikipediaSearchAPIViewModel内のVariableにbindされない
//        // また、variableをbindさせるときの挙動を理解できていない
//        // でも以下の理由から、ここでハマるのはもったいない
//        // MVVMでbindしたりObserveする挙動だけ
//        // 軽く確認することにする（動作確認もしない）
//
//        // 理由1:Variableは非推奨となった
//        // 理由2:Variable は Rx に一般的に存在するものではなく、
//        // RxSwift が提供している独自のもの
//
//        // ＜各コンポーネントの構成＞
//        // ■View :WikipediaSearchAPIViewController
//        // 検索バー、テーブルを表示
//        // 検索キーワード／検索結果をViewModelのオブジェクトとbind
//        // 唯一UIKitフレームワークをimportする
//        // Viewではデータバインドでオブジェクトを結合する、あるいはイベント発生時に呼び出す処理を定義するだけ
//        // つまり、ViewModelの処理はViewから直接呼ぶのではなく、
//        // ViewでbindしたViewModelにて
//        // onNextイベント発生で検知するようにする
//
//        // ■ViewModel :WikipediaSearchAPIViewModel
//        // 検索バーからの値の受け取り／ObserveパターンでWikipedia API検索／検索結果の返却
//        // ViewModelで検索を実行する前に、以下の制限を課す
//        // ・入力文字が3文字以内なら無視
//        // ・一定時間delay
//        // ・入力中に次の入力があったら前のものはキャンセル(flatMapLatestで)
//
//        // ■Model :WikipediaSearchAPIModel
//        // WikipediaAPIClientを使って検索処理し、結果を生成
//
//        // ■MVVM以外 :WikipediaAPIClient
//        // Wikipwdia APIへのHTTPリクエスト汎用クラス
//
//
//        // 以下、意味深だが、variableの仕様を抑えてないのでわからない（無視）
//        //        　最初に戻って見方を変えると、メソッドの戻り値はObservable<[Result]>型の変数ですが、これはonNextに[Result]型の変数を渡すことと同じ意味です。今回のサンプルのように非同期で行う処理でObservableオブジェクトを扱う時には、途中で何を渡すべきか忘れてしまうこともあるので注意してください。
//
//        var mvvmSearchBar = UISearchBar()
//
//        mvvmSearchBar.barStyle = UIBarStyle.default
//        mvvmSearchBar.tintColor = UIColor.gray
//        mvvmSearchBar.placeholder = "mvvmSearchBar"
//        mvvmSearchBar.keyboardType = UIKeyboardType.default
//
//        self.view.addSubview(mvvmSearchBar)
//        mvvmSearchBar.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8).isActive = true
//        mvvmSearchBar.translatesAutoresizingMaskIntoConstraints = false
//        mvvmSearchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10.0).isActive = true
//        mvvmSearchBar.topAnchor.constraint(equalTo: subjectButton.bottomAnchor, constant: 10.0).isActive = true
////        mvvmSearchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10.0).isActive = true
//
//        // tableViewの位置が画面上部になってハマったが、以下のautoLayout適用で解決
//        //https://stackoverflow.com/questions/45311714/how-to-add-programmatic-constraints-to-a-uitableview
//        // tableViewのつくりかたは以下
//        // https://qiita.com/abouch/items/3617ce37c4dd86932365
//        self.rxTableView.frame = view.bounds
//        self.rxTableView.dataSource = self
//        view.addSubview(self.rxTableView)
//
//        //制約
//        self.rxTableView.translatesAutoresizingMaskIntoConstraints = false
//        self.rxTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        self.rxTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        self.rxTableView.topAnchor.constraint(equalTo: mvvmSearchBar.bottomAnchor).isActive = true
//        self.rxTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32.0).isActive = true
//
//        // 検索欄の入力値とViewModelのsearchWordをbind    // -------（2）
//        let viewModel     = WikipediaSearchAPIViewModel()
//        mvvmSearchBar.rx.text.orEmpty
//           .bind(to: viewModel.searchWord)
//           .disposed(by: self.disposeBag)
//
//        // 検索結果とテーブルのセルをbind
//        // エラーになるのでコメント
////       viewModel.items.asObservable()    // -------（3）
////           .bind(to: self.rxTableView.rx.items(cellIdentifier: "Cell")) { index, result, cell in
////               cell.textLabel?.text = result.title
////               cell.detailTextLabel?.text = "https://ja.wikipedia.org/w/index.php?curid=＼(result.pageid)"
////           }
////           .disposed(by: self.disposeBag)
//
    }
//
//    func parseJson(_ json: Any) -> [Result] {
//        guard let items = json as? [String: Any] else { return [] }
//        var results = [Result]()
//        // JSONの階層を追って検索結果を配列で返す
//        if let queryItems = items["query"] as? [String:Any] {
//            if let searchItems  = queryItems["search"] as? [[String: Any]] { // -------（4-1）
//                searchItems.forEach{
//                    guard let title = $0["title"] as? String,
//                            let pageid = $0["pageid"] as? Int else { return }
//                    results.append(Result(title: title, pageid: pageid))    // -------（4-2）
//                }
//            }
//        }
//        return results  // -------（4-3）
//    }
//
//    @objc func scanTapped(_ sender: UIButton){
//        let alert = UIAlertController(title: "タイトル", message: "アラートサンプル", preferredStyle: .alert)
//        //OKボタン
//        let okButton = UIAlertAction(title: "OK", style: .default,
//            handler: {
//                (action: UIAlertAction!) -> Void in
//                print("OK-")
//            }
//        )
//        alert.addAction(okButton)
//        //Cancelボタン
//        let cancelButton = UIAlertAction(title: "Cancel", style: .default, handler: nil)
//        alert.addAction(cancelButton)
//        present(alert, animated: false, completion: nil)
//
//    }
//
//    private func dbaccess() {
//        // get path of /Documents
//        let paths = NSSearchPathForDirectoriesInDomains( .documentDirectory, .userDomainMask, true)
//
//        // generate to /Documents/swift2objectc.db
//        let _path = paths[0].stringByAppendingPathComponent(path: "swift2objectc.db")
//
//        // make instance of FMDatabase
//        let db = FMDatabase(path: _path)
//
//        // database open and create database
//        db.open()
//
//        // トランザクションの開始（使いたければ使う）
////        db.beginTransaction()
////        var success = true
//
//        //create table
//        var sql = "CREATE TABLE IF NOT EXISTS sample (user_id INTEGER PRIMARY KEY, user_name TEXT);"
//        let creRet = db.executeUpdate(sql, withArgumentsIn: [])
//        print("DBtest1 creRet \(creRet)")
//
//        // insert data
//        sql = "INSERT INTO sample (user_id, user_name) VALUES (?, ?);"
//        let insRet = db.executeUpdate(sql, withArgumentsIn: [2, "userTest2"])
//        print("DBtest2 insRet \(insRet)")
//
//        // update data
//        sql = "UPDATE sample SET user_name = :NAME WHERE user_id = :ID;"
//        let updRet = db.executeUpdate(sql, withParameterDictionary: ["ID":2, "NAME":"Wonderplanet"])
//        print("DBtest3 updRet \(updRet)")
//        // ->存在しないレコードを更新してもtrueが変える
//
//        // delete data
//        sql = "DELETE FROM sample WHERE user_id = ?;"
//        let delRet = db.executeUpdate(sql, withArgumentsIn: [2])
//        print("DBtest4 updRet \(delRet)")
//        // ->存在しないレコードを削除してもtrueが変える
//
//        // read data
//        sql = "SELECT user_id, user_name FROM sample ORDER BY user_id;"
//        let readRet = db.executeQuery(sql, withArgumentsIn: [])
//        print("DBtest5 readRet \(readRet)")
//        if let results = readRet {
//            while results.next() {
//                let user_id = results.int(forColumn: "user_id")
//                let user_name = results.string(forColumnIndex: 1)
//                // print data
//                print("DBTest5 user_id = \(user_id), user_name = \(user_name)")
//            }
//        }
//
//        // トランザクションの終了（使いたければ使う）
////        if success {
////            // 全てのINSERT文が成功した場合はcommit
////            db.commit()
////        } else {
////           // 1つでも失敗したらrollback
////           db.rollback()
////        }
//
//        // database close
//        db.close()
//    }
}
//
//extension ViewController: UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return testTableItems.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        // detailTextLabelが表示されなくてハマったが、以下のサイトで
//        // .subtitleを指定すれば良いことがわかった
//        // Swift – UITableViewの基礎を学ぼう (セルのスタイルの種類について)
//        // https://weblabo.oscasierra.net/swift-uitableview-2/
////        let cell = UITableViewCell()
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
//        cell.textLabel?.text = testTableItems[indexPath.row]
//        cell.detailTextLabel?.text = "aaaaa"
//        return cell
//    }
//}
//
//// 検索結果を格納する構造体
//struct Result {
//    let title: String
//    let pageid: Int
//}
//
//
//extension String {
//
//    /// String -> NSString に変換する
//    func to_ns() -> NSString {
//        return (self as NSString)
//    }
//
////    func substringFromIndex(index: Int) -> String {
////        return to_ns().substringFromIndex(index)
////    }
//
////    func substringToIndex(index: Int) -> String {
////        return to_ns().substringToIndex(index)
////    }
//
////    func substringWithRange(range: NSRange) -> String {
////        return to_ns().substringWithRange(range)
////    }
//
//    var lastPathComponent: String {
//        return to_ns().lastPathComponent
//    }
//
//    var pathExtension: String {
//        return to_ns().pathExtension
//    }
//
////    var stringByDeletingLastPathComponent: String {
////        return to_ns().stringByDeletingLastPathComponent
////    }
//
////    var stringByDeletingPathExtension: String {
////        return to_ns().stringByDeletingPathExtension
////    }
//
//    var pathComponents: [String] {
//        return to_ns().pathComponents
//    }
//
////    var length: Int {
////        return self.characters.count
////    }
//
//    func stringByAppendingPathComponent(path: String) -> String {
//        return to_ns().appendingPathComponent(path)
//    }
//
//    func stringByAppendingPathExtension(ext: String) -> String? {
//        return to_ns().appendingPathExtension(ext)
//    }
//
//}


