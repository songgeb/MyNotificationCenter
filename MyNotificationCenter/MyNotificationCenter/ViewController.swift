//
//  ViewController.swift
//  MyNotificationCenter
//
//  Created by songgeb on 2022/8/6.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        testCustomNotificationCenter()
    }
    
    private func testCustomNotificationCenter() {
        let center = MyNotificationCenter.default
        
        let name = "songgeb"
        // 测试1：先addobserver，post--ok
//        center.addObserver(self, selector: #selector(handleNotification(_:)), name: name, object: nil)
//        center.post(name: name, object: nil, userInfo: ["a": 1])
//        center.removeAllObservers()
        
        // 测试2：removeObserver是否好使
        testRemoveObserver(center)
        func testRemoveObserver(_ center: MyNotificationCenter) {
            var observer = center.addObserver(forName: name, object: nil, queue: nil) { _ in
                print("sss")
            }
            center.removeObserver(observer, name: name, object: nil)
            center.post(name: name)
            let obj = NSObject()
            observer = center.addObserver(forName: name, object: obj, queue: nil) { _ in
                print("what")
            }
//            center.removeObserver(observer, name: "123", object: obj)
//            center.removeObserver(self, name: "nil", object: nil)
//            center.removeObserver(self, name: nil, object: NSObject())
            center.post(name: name, object: obj, userInfo: nil)
            center.removeAllObservers()
        }
        
        // 测试3：addObserver(closure)是否好使
        func testAddObserverClosure(_ center: MyNotificationCenter) {
            center.addObserver(forName: name, object: nil, queue: nil) { notification in
                print("收到通知--内容为--\(notification.userInfo)")
            }
            center.post(name: name, object: nil, userInfo: [1:2])
            center.removeAllObservers()
        }
        
        // 测试4：object是否好使
        func testObjectParameter(_ center: MyNotificationCenter) {
            print("测试object是否好使")
            let obj = NSObject()
            // add observer with object, only received notification with object
            center.addObserver(self, selector: #selector(handleNotification(_:)), name: name, object: obj)
            center.post(name: name, object: nil, userInfo: [1:"没有object"])
            center.post(name: name, object: obj, userInfo: [1:"有object"])
            center.removeAllObservers()
            // add observer with nil object, received all notification with same name
            center.addObserver(forName: name, object: nil, queue: nil) { notification in
                print("收到通知--内容为--\(notification.userInfo)")
            }
            center.post(name: name, object: nil, userInfo: [1:"没有object"])
            center.post(name: name, object: obj, userInfo: [1:"有object"])
            center.removeAllObservers()
        }
        
        // 测试5：测试name是否好用
        func testNameParamter(_ center: MyNotificationCenter) {
            print("测试name字段是否好用")
            // add observer with nil name, received all notification
            center.addObserver(forName: nil, object: nil, queue: nil) { notification in
                print("应收到所有通知--内容为--\(notification.userInfo)")
            }
            center.addObserver(forName: name, object: nil, queue: nil) { notification in
                print("收到name为\(name)的通知-")
            }
            center.post(name: name, userInfo: [1: 2])
            center.removeAllObservers()
        }
        
        // 测试6：测试queue
        func testQueueParamter() {
            print("测试queue")
            let queue = OperationQueue()
            center.addObserver(forName: name, object: nil, queue: queue) { notification in
                print("收到通知--当前线程为--\(Thread.current)")
            }
            center.post(name: name, object: nil, userInfo: nil)
            center.removeAllObservers()
        }
        
        // 测试7：测试多线程安全性
        func testThreadSafety() {
            print("测试多线程安全性")
            let queue = OperationQueue()
            let q = DispatchQueue(label: "123", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
            for _ in 0...100 {
                q.async {
                    center.addObserver(forName: "123", object: nil, queue: queue) { notification in
                        print("收到--通知--\(notification.userInfo)")
                    }
                    center.post(name: "dfdd")
                }

                q.async {
                    center.addObserver(self, selector: #selector(self.handleNotification(_:)), name: "123", object: nil)
                    center.post(name: "123")
                    center.addObserver(forName: "dfdd", object: nil, queue: queue) { notification in
                        print("收到00通知--\(notification.userInfo)")
                    }
                    center.post(name: "fgfgf")
                }
            }
        }
    }
    
    @objc private func handleNotification(_ notification: MyNotification) {
        print("收到通知---userinfo is \(notification.userInfo)")
    }

}

