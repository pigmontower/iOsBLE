# iOsBLE
**＜できること＞**

2つのiPhoneにて、Bluetooth Low Energy(BLE)経由でBLEデータベースの値の変更を行うテストアプリ

**＜使い方＞**

1.iPhoneを2つ用意（端末A/B)

2.それぞれBluetoothTestアプリを立ち上げる。(端末AはXcodeから起動し、ログを表示しておく）

3.端末Aにて「change roll」ボタンを押下
<div align="left">
<img width="300" alt="スクリーンショット 2020-06-09 18 03 25" src="https://user-images.githubusercontent.com/66576691/84131115-1bab4880-aa7f-11ea-8ee7-6495d9d62e8b.png">
</div>

4.端末Aにて「start advertising」ボタンを押下
<div align="left">
<img width="300" alt="スクリーンショット 2020-06-09 18 30 02" src="https://user-images.githubusercontent.com/66576691/84131342-65942e80-aa7f-11ea-80f4-c155d7423c78.png">
</div>

5.端末Bにて「start scaning」ボタンを押下
<div align="left">
<img width="300" alt="スクリーンショット 2020-06-09 18 30 50" src="https://user-images.githubusercontent.com/66576691/84131350-688f1f00-aa7f-11ea-90ea-89708487d161.png">
</div>

6.端末Aにて「書き込み完了」のログが出たら書き込みが完了(端末AのBLEデータベースに「"test write without response"」というデータが書き込まれます）
<div align="left">
<img width="556" alt="スクリーンショット 2020-06-09 18 38 15" src="https://user-images.githubusercontent.com/66576691/84132108-6bd6da80-aa80-11ea-8c89-24b219dd3188.png">
</div>
