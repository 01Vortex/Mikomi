import 'package:flutter/foundation.dart';
import 'package:mikomi/features/home/repositories/home_repository.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

class HomeState {
  final List<HomeAnimeModel> recommendations;
  final List<HomeAnimeModel> banners;
  final bool isLoading;

  const HomeState({
    this.recommendations = const [],
    this.banners = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    List<HomeAnimeModel>? recommendations,
    List<HomeAnimeModel>? banners,
    bool? isLoading,
  }) {
    return HomeState(
      recommendations: recommendations ?? this.recommendations,
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HomeCubit extends ValueNotifier<HomeState> {
  final HomeRepository _repository = HomeRepository();

  HomeCubit() : super(const HomeState());

  Future<void> loadInitial({int pageSize = 12}) async {
    value = value.copyWith(isLoading: true);

    final results = await Future.wait([
      _repository.getRecommendedList(limit: pageSize, offset: 0),
      _repository.getBannerList(count: 5),
    ]);

    final recommendations = results[0];
    final banners = results[1];

    value = value.copyWith(
      recommendations: recommendations,
      banners: banners.isNotEmpty ? banners : recommendations.take(5).toList(),
      isLoading: false,
    );
  }
}
