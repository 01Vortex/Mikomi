import 'package:flutter/material.dart';
import 'package:mikomi/config/app_theme.dart';
import 'package:mikomi/features/anime/models/character_info_model.dart';
import 'package:mikomi/features/anime/models/character_teasing_model.dart';
import 'package:mikomi/features/anime/models/person_info_model.dart';
import 'package:mikomi/features/anime/models/person_teasing_model.dart';
import 'package:mikomi/features/anime/service/anime_service.dart';
import 'package:mikomi/features/anime/ui/widgets/dy_comment.dart';
import 'package:mikomi/features/anime/ui/widgets/detail_popover_info.dart';

enum InfoType { character, person }

class DetailPopover extends StatefulWidget {
  final int id;
  final InfoType type;

  const DetailPopover({super.key, required this.id, required this.type});

  @override
  State<DetailPopover> createState() => _DetailPopoverState();
}

class _DetailPopoverState extends State<DetailPopover>
    with SingleTickerProviderStateMixin {
  late final AnimeService _animeService;
  late final TabController _tabController;

  CharacterInfoModel? _character;
  PersonInfoModel? _person;
  List<dynamic> _comments = [];
  bool _isLoadingInfo = true;
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animeService = AnimeService();
    _loadInfo();
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    setState(() => _isLoadingInfo = true);

    if (widget.type == InfoType.character) {
      final character = await _animeService.getCharacterInfo(widget.id);
      if (mounted) {
        setState(() {
          _character = character;
          _isLoadingInfo = false;
        });
      }
    } else {
      final person = await _animeService.getPersonInfo(widget.id);
      if (mounted) {
        setState(() {
          _person = person;
          _isLoadingInfo = false;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);

    if (widget.type == InfoType.character) {
      final comments = await _animeService.getCharacterComments(widget.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } else {
      final comments = await _animeService.getPersonComments(widget.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '人物资料'),
              Tab(text: '吐槽箱'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInfo(), _buildComments()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    if (widget.type == InfoType.character) {
      return DetailPopoverInfo(
        imageUrl: _character?.image ?? '',
        name: _character?.name ?? '',
        nameCN: _character?.localizedName ?? '',
        info: _character?.info ?? '',
        summary: _character?.summary ?? '',
        summaryTitle: '角色简介',
        isLoading: _isLoadingInfo,
        onRetry: _loadInfo,
      );
    } else {
      return DetailPopoverInfo(
        imageUrl: _person?.image ?? '',
        name: _person?.name ?? '',
        nameCN: _person?.localizedName ?? '',
        info: _person?.info ?? '',
        summary: _person?.summary ?? '',
        summaryTitle: '人物简介',
        isLoading: _isLoadingInfo,
        onRetry: _loadInfo,
      );
    }
  }

  Widget _buildComments() {
    if (widget.type == InfoType.character) {
      return DyComment<CharacterTeasingModel>(
        comments: _comments.cast<CharacterTeasingModel>(),
        isLoading: _isLoadingComments,
        onRetry: _loadComments,
        getUserNickname: (comment) => comment.user.nickname,
        getUserAvatar: (comment) => comment.user.avatar.large,
        getContent: (comment) => comment.content,
        getCreatedAt: (comment) => comment.createdAt,
        getReplies: (comment) => comment.replies,
      );
    } else {
      return DyComment<PersonTeasingModel>(
        comments: _comments.cast<PersonTeasingModel>(),
        isLoading: _isLoadingComments,
        onRetry: _loadComments,
        getUserNickname: (comment) => comment.user.nickname,
        getUserAvatar: (comment) => comment.user.avatar.large,
        getContent: (comment) => comment.content,
        getCreatedAt: (comment) => comment.createdAt,
        getReplies: (comment) => comment.replies,
      );
    }
  }
}
