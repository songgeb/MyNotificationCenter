# MyNotificationCenter

用Swift实现的一个NotificationCenter

功能列表

- 基础功能
	- 单例
	- addObserver(支持接收selector作为参数)
	- addObserver(支持接收closure作为回调参数)
	- postNotification
	- removeObserver
- 多线程，必须保证多线程安全
- 进阶功能，使用addObserver(selector)注册observer后，如果忘记removeObserver，NotificationCenter内部可以自动clean up（系统NotificationCenter的API就是这样做的）
