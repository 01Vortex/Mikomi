import 'package:mikomi/core/models/character_item.dart';
import 'package:mikomi/core/models/staff_item.dart';

abstract class DetailRepository {
  Future<List<CharacterItem>> getCharacters(int id);
  Future<List<StaffItem>> getStaff(int id);
}
