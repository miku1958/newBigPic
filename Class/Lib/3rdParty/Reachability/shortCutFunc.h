///�Ƿ�WIFI�������˷������°汾�ѱ��Ƴ�
//#define isEnableWIFI [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable


///�Ƿ�WIFI����
//#define isEnableWIFI ReachableViaWiFi == [[Reachability reachabilityForInternetConnection] currentReachabilityStatus]

///�Ƿ�����������wifi���жϾ��ǲ����Ƿ���������ΪReachabilityû���ж��Ƿ������ķ�����
#define isEnable4G [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable