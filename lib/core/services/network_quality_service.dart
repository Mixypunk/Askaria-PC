class NetworkQualityService {
  static final NetworkQualityService instance = NetworkQualityService._internal();
  NetworkQualityService._internal();
  bool get isOffline => false;
}