///是否WIFI环境，此方法在新版本已被移出
//#define isEnableWIFI [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable


///是否WIFI环境
//#define isEnableWIFI ReachableViaWiFi == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus]

///是否能上网（在wifi后判断就是测试是否流量，因为Reachability没有判断是否流量的方法）
#define isEnable4G [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable