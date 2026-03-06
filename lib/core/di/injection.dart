import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../features/home/domain/repositories/recipe_repository.dart';
import '../../features/home/domain/services/search_api_service.dart'; 
import '../network/token_interceptor.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.interceptors.add(TokenInterceptor(dio));
    return dio;
  });

  getIt.registerLazySingleton<RecipeRepository>(
      () => RecipeRepository(getIt<Dio>()));

  getIt.registerLazySingleton<SearchApiService>(
      () => SearchApiService(getIt<Dio>()));
}