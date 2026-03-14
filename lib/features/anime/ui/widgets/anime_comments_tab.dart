import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/models/comment_item.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/anime/data/datasources/comment_remote_datasource.dart';
import 'package:mikomi/features/anime/data/repositories/comment_repository_impl.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:intl/intl.dart';

class AnimeCommentsTab extends StatefulWidget {
  final BangumiItem bangumiItem;

  const AnimeCommentsTab({super.key, required this.bangumiItem});

  @override
  State<AnimeCommentsTab> createState() => _AnimeCommentsTabState();
}

class _AnimeCommentsTabState extends State<AnimeCommentsTab> {
  late final CommentRepositoryImpl _repository;
  List<CommentItem> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    final dataSource = CommentRemoteDataSourceImpl(DioClient());
    _repository = CommentRepositoryImpl(dataSource);
    // 不在initState中加载数据，改为懒加载
  }

  Future<void> _loadComments({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _comments.isNotEmpty)) return;

    setState(() => _isLoading = true);

    final newComments = await _repository.getBangumiComments(
      widget.bangumiItem.id,
      limit: _limit,
      offset: loadMore ? _offset : 0,
    );

    if (mounted) {
      setState(() {
        if (loadMore) {
          _comments.addAll(newComments);
        } else {
          _comments = newComments;
        }
        _offset = _comments.length;
        _hasMore = newComments.length >= _limit;
        _isLoading = false;
      });
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 懒加载：首次构建时加载数据
    if (!_isLoading && _comments.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadComments();
        }
      });
    }

    if (_isLoading && _comments.isEmpty) {
      return _buildSkeletonList();
    }

    if (_comments.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无评论'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadComments(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
              _hasMore &&
              !_isLoading) {
            _loadComments(loadMore: true);
          }
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _comments.length + (_hasMore && _isLoading ? 3 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          if (index >= _comments.length) {
            return _buildSkeletonComment();
          }
          return _buildCommentItem(_comments[index]);
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) => _buildSkeletonComment(),
    );
  }

  Widget _buildSkeletonComment() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonCircle(size: 48),
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
    );
  }

  Widget _buildCommentItem(CommentItem commentItem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: CachedImage(
            imageUrl: commentItem.user.avatar.large,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                commentItem.user.nickname,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                commentItem.comment.comment,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(commentItem.comment.updatedAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
