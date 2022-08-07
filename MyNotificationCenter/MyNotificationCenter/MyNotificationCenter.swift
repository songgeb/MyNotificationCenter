//
//  MyNotificationCenter.swift
//  Test-Swift
//
//  Created by songgeb on 2022/8/5.
//  Copyright © 2022 songgeb.MyNotificationCenter. All rights reserved.
//

import Foundation

class MyNotification: NSObject {
    let name: String
    var userInfo: [AnyHashable: Any]?
    
    init(name: String, userInfo: [AnyHashable: Any]? = nil) {
        self.name = name
        self.userInfo = userInfo
    }
}

/// 模仿系统NotificationCenter实现的自定义通知中心
class MyNotificationCenter: NSObject {
    // MARK: - public properties
    typealias CallbackBlockType = (MyNotification) -> Void
    static let `default` = MyNotificationCenter.init()
    
    // MARK: - private properties
    private class ObserverInfo {
        
        enum CallbackType {
            case selector(Selector)
            case block(block: CallbackBlockType, queue: OperationQueue?)
        }
        
        weak var observer: AnyObject?
        let callback: CallbackType
        
        init(observer: AnyObject?, callback: CallbackType) {
            self.observer = observer
            self.callback = callback
        }
    }
    private var observerInfos: [String?: [ObjectIdentifier?: [ObserverInfo]]] = [:]
    private let syncQueue = DispatchQueue(label: "com.MyNotificationCenter.safeaccess.serial")
    
    override private init() { }
    
    // MARK: - public
    @discardableResult
    func addObserver(forName name: String?,
                     object obj: AnyObject?,
                     queue: OperationQueue?,
                     using block: @escaping CallbackBlockType) -> NSObjectProtocol {
        let observer = NSObject()
        let observerInfo = ObserverInfo(observer: observer, callback: .block(block: block, queue: queue))
        syncQueue.sync {
            observerInfos[name, default: [:]][obj == nil ? nil : ObjectIdentifier(obj!), default: []].append(observerInfo)
        }
        return observer
    }
               
    func addObserver(_ observer: AnyObject,
            selector aSelector: Selector,
                name aName: String?,
                     object anObject: AnyObject?) {
        let observerInfo = ObserverInfo(observer: observer, callback: .selector(aSelector))
        syncQueue.sync {
            observerInfos[aName, default: [:]][anObject == nil ? nil : ObjectIdentifier(anObject!), default: []].append(observerInfo)
        }
    }
    
    func post(name: String, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil) {
        // 如果参数object不为空，符合条件的observer有两部分：object与参数object相等的，object为nil
        // 如果参数object为空，符合条件的observer是object为nil的
        let observers: [ObserverInfo] = syncQueue.sync {
            var observers: [ObserverInfo] = []
            if let obj = object {
                observers = observerInfos[name, default: [:]][ObjectIdentifier(obj), default: []]
                let objNilObservers = observerInfos[name, default: [:]][nil, default: []]
                observers.append(contentsOf: objNilObservers)
                // 还要通知所有name为nil的observer
                let nameNilObservers = observerInfos[nil, default: [:]][ObjectIdentifier(obj), default: []]
                observers.append(contentsOf: nameNilObservers)
            } else {
                observers = observerInfos[name, default: [:]][nil, default: []]
                // 还要通知所有name为nil的observer
                let nameNilObservers = observerInfos[nil, default: [:]][nil, default: []]
                observers.append(contentsOf: nameNilObservers)
            }
            
            if observers.isEmpty { return [] }
            return observers
        }
        let notification = MyNotification(name: name, userInfo: userInfo)
        
        observers.forEach { info in
            switch info.callback {
            case .selector(let selector) where info.observer != nil:
                if let observer = info.observer as? NSObjectProtocol,
                   observer.responds(to: selector) {
                    observer.perform(selector, with: notification)
                }
            case .block(block: let block, queue: let queue):
                if let queue = queue {
                    queue.addOperation({
                        block(notification)
                    })
                } else {
                    block(notification)
                }
            default:
                break
            }
        }
        
        // clean destroyed observers
        syncQueue.async {
            self.cleanDestoryedObserverInfos()
        }
    }
    
    func removeObserver(_ observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        syncQueue.sync {
            if let aName = aName, let anObject = anObject {
                observerInfos[aName, default: [:]][ObjectIdentifier(anObject), default: []].removeAll { info in
                    return info.observer === observer
                }
            } else if let aName = aName {
                observerInfos[aName, default: [:]].forEach { info in
                    var info = info
                    var observers = info.value
                    observers.removeAll(where: {
                        $0.observer === observer
                    })
                    info.value = observers
                    observerInfos[aName, default: [:]][info.key] = observers
                }
            } else if let anObject = anObject {
                observerInfos.forEach { nameAndInfo in
                    var objAndInfos = nameAndInfo.value
                    objAndInfos.forEach { objAndInfo in
                        guard let identifier = objAndInfo.key else { return }
                        if identifier == ObjectIdentifier(anObject) {
                            var observers = objAndInfo.value
                            observers.removeAll(where: { $0.observer === observer })
                            objAndInfos[identifier] = observers
                        }
                    }
                    observerInfos[nameAndInfo.key] = objAndInfos
                }
            } else {
                observerInfos.forEach { nameAndInfo in
                    var objAndInfos = nameAndInfo.value
                    objAndInfos.forEach { objAndInfo in
                        var observers = objAndInfo.value
                        observers.removeAll(where: { $0.observer === observer })
                        objAndInfos[objAndInfo.key] = observers
                    }
                    observerInfos[nameAndInfo.key] = objAndInfos
                }
            }
        }
    }
    
    func removeAllObservers() {
        syncQueue.sync {
            observerInfos.removeAll()
        }
    }
    
    // MARK: - private functions
    private func cleanDestoryedObserverInfos() {
        observerInfos.values.forEach { info in
            var info = info
            info.forEach { (key: ObjectIdentifier?, value: [ObserverInfo]) in
                var v = value
                v.removeAll(where: {
                    switch $0.callback {
                    case .selector(_) where $0.observer == nil:
                        return true
                    default:
                        return false
                    }
                })
                info[key] = v
            }
        }
    }
}
