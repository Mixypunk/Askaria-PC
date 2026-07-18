import 'package:get_it/get_it.dart';
import 'services/api_service.dart';
import 'services/lyrics_service.dart';
import 'providers/player_provider.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Services
  sl.registerLazySingleton<SwingApiService>(() => SwingApiService());
  sl.registerLazySingleton<LyricsService>(() => LyricsService(sl<SwingApiService>()));

  // Providers
  sl.registerLazySingleton<PlayerProvider>(() => PlayerProvider());
}
