import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/repositories/home_repository.dart';

class ScheduleService {
  final HomeRepository _homeRepository;

  ScheduleService({HomeRepository? homeRepository})
    : _homeRepository = homeRepository ?? HomeRepository();

  Future<List<List<HomeAnimeModel>>> getWeekSchedule() async {
    try {
      return await _homeRepository.getCalendar();
    } catch (_) {
      return List.generate(7, (_) => <HomeAnimeModel>[]);
    }
  }
}
