import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/pref_service.dart';
import '../network/dio_client.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // 1. External Dependencies
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);

  // 2. Core Storage & Network Services
  sl.registerLazySingleton<PrefService>(() => PrefService(sl<SharedPreferences>()));
  sl.registerLazySingleton<DioClient>(() => DioClient());
}
