import 'package:flutter/material.dart';
import 'package:mikomi/config/app_theme.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/anime/models/anime_teasing_model.dart';
import 'package:mikomi/features/anime/repository/anime_repository.dart';
import 'package:mikomi/shared/comment_card.dart';
import 'package:mikomi/shared/skeleton.dart';

class AnimeTeasingContent extends StatefulWidget {
  final Anime anime;

  const AnimeTeasingContent({super.key, required this.anime});

  @override
  State<AnimeTeasingContent> createState() => _AnimeTeasingContentState();
}

class _AnimeTeasingContentState extends State<AnimeTeasingContent> {
  late final AnimeRepository _repository;
  final ScrollController _scrollController = ScrollController();
  List<CommentItem> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _repository = AnimeRepository();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final comments = await _repository.getSubjectComments(
      widget.anime.id,
      limit: _limit,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        _comments = comments;
        _offset = comments.length;
        _hasMore = comments.length >= _limit;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final comments = await _repository.getSubjectComments(
      widget.anime.id,
      limit: _limit,
      offset: _offset,
    );

    if (mounted) {
      setState(() {
        _comments.addAll(comments);
        _offset += comments.length;
        _hasMore = comments.length >= _limit;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _comments.isEmpty) {
      return _buildSkeletonList();
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无吐槽',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length + (_isLoading && _hasMore ? 3 : 0),
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index >= _comments.length) {
          return _buildSkeletonComment();
        }
        return CommentCard(commentItem: _comments[index]);
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) => _buildSkeletonComment(),
    );
  }

  Widget _buildSkeletonComment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonCircle(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 100, height: 14),
                const SizedBox(height: 8),
                SkeletonText(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                SkeletonText(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                SkeletonText(width: 200, height: 14),
                const SizedBox(height: 8),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
