//
//  AppDelegate.swift
//  BluetoothTest
//
//  Created by 山本真寛 on 2020/03/21.
//  Copyright © 2020 山本真寛. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Add -start
        //画面サイズに合わせてウィンドウを生成
        window = UIWindow(frame: UIScreen.main.bounds)
        //ビューコントローラーの生成
        let viewController = ViewController()
        //ビューコントローラーをルートビューコントローラーに設定
        window?.rootViewController = viewController
        //対象のウィンドウをキーウィンドウにする
        window?.makeKeyAndVisible()
        // Add -end
        return true
    }

    // Mod -start
//    // MARK: UISceneSession Lifecycle
//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }
    
    //アプリがアクティブでなくなる直前
    func applicationWillResignActive(_ application: UIApplication) {
    }

    //アプリがバックグラウンドになった時
    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    //アプリがフォアグラウンドになる直前
    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    //アプリがアクティブになった時
    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    //アプリが終了される時
    func applicationWillTerminate(_ application: UIApplication) {
    }
    // Mod -end

}

