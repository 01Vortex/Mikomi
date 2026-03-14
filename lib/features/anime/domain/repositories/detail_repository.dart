import 'package:mikomi/core/models/character_item.dart';
import 'package:mikomi/core/models/character_detail.dart';
import 'package:mikomi/core/models/character_comment.dart';
import 'package:mikomi/core/models/person_detail.dart';
import 'package:mikomi/core/models/person_comment.dart';
import 'package:mikomi/core/models/staff_item.dart';

abstract class DetailRepository {
  Future<List<CharacterItem>> getCharacters(int id);
  Future<List<StaffItem>> getStaff(int id);
  Future<CharacterDetail?> getCharacterDetail(int characterId);
  Future<List<CharacterComment>> getCharacterComments(int characterId);
  Future<PersonDetail?> getPersonDetail(int personId);
  Future<List<PersonComment>> getPersonComments(int personId);
}
