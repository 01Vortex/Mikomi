import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/character_detail.dart';
import 'package:mikomi/core/models/character_comment.dart';
import 'package:mikomi/core/models/person_detail.dart';
import 'package:mikomi/core/models/person_comment.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/anime/data/datasources/detail_remote_datasource.dart';
import 'package:mikomi/features/anime/data/repositories/detail_repository_impl.dart';
import 'package:mikomi/features/anime/ui/widgets/comment_list_widget.dart';
import 'package:mikomi/features/anime/ui/widgets/person_info_widget.dart';

enum InfoType { character, person }

class AnimeMoreInfo extends StatefulWidget {
  final int id;
  final InfoType type;

  const AnimeMoreInfo({super.key, required this.id, required this.type});

  @override
  State<AnimeMoreInfo> createState() => _AnimeMoreInfoState();
}

class _AnimeMoreInfoState extends State<AnimeMoreInfo>
    with SingleTickerProviderStateMixin {
  late final DetailRepositoryImpl _repository;
  late final TabController _tabController;

  CharacterDetail? _character;
  PersonDetail? _person;
  List<dynamic> _comments = [];
  bool _isLoadingInfo = true;
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final dataSource = DetailRemoteDataSourceImpl(DioClient());
    _repository = DetailRepositoryImpl(dataSource);
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
      final character = await _repository.getCharacterDetail(widget.id);
      if (mounted) {
        setState(() {
          _character = character;
          _isLoadingInfo = false;
        });
      }
    } else {
      final person = await _repository.getPersonDetail(widget.id);
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
      final comments = await _repository.getCharacterComments(widget.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } else {
      final comments = await _repository.getPersonComments(widget.id);
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
      return PersonInfoWidget(
        imageUrl: _character?.image ?? '',
        name: _character?.name ?? '',
        nameCN: _character?.nameCN ?? '',
        info: _character?.info ?? '',
        summary: _character?.summary ?? '',
        summaryTitle: '角色简介',
        isLoading: _isLoadingInfo,
        onRetry: _loadInfo,
      );
    } else {
      return PersonInfoWidget(
        imageUrl: _person?.image ?? '',
        name: _person?.name ?? '',
        nameCN: _person?.nameCN ?? '',
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
      return CommentListWidget<CharacterComment>(
        comments: _comments.cast<CharacterComment>(),
        isLoading: _isLoadingComments,
        onRetry: _loadComments,
        getUserNickname: (comment) => comment.user.nickname,
        getUserAvatar: (comment) => comment.user.avatar.large,
        getContent: (comment) => comment.content,
        getCreatedAt: (comment) => comment.createdAt,
        getReplies: (comment) => comment.replies,
      );
    } else {
      return CommentListWidget<PersonComment>(
        comments: _comments.cast<PersonComment>(),
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
