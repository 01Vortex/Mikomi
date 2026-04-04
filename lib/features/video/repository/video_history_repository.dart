import 'package:mikomi/features/my/models/history_model.dart';
import 'package:mikomi/features/my/service/watch_history_service.dart';

class VideoHistoryRepository {
  final HistoryModelService _historyService;

  VideoHistoryRepository({HistoryModelService? historyService})
    : _historyService = historyService ?? HistoryModelService();

  void save(HistoryModel history) {
    _historyService.addHistory(history);
  }
}
