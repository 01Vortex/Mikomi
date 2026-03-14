import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/person_detail.dart';
import 'package:mikomi/core/models/person_comment.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/anime/data/datasources/detail_remote_datasource.dart';
import 'package:mikomi/features/anime/data/repositories/detail_repository_impl.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:intl/intl.dart';

class PersonDetailPage extends StatefulWidget {
  final int personId;

  const PersonDetailPage({super.key, required this.personId});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage>
    with SingleTickerProviderStateMixin {
  late final DetailRepositoryImpl _repository;
  late final TabController _tabController;
  PersonDetail? _person;
  List<PersonComment> _comments = [];
  bool _isLoadingPerson = true;
  bool _isLoadingComments = true;
  final Set<int> _expandedComments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final dataSource = DetailRemoteDataSourceImpl(DioClient());
    _repository = DetailRepositoryImpl(dataSource);
    _loadPerson();
    _loadComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerson() async {
    setState(() => _isLoadingPerson = true);

    final person = await _repository.getPersonDetail(widget.personId);

    if (mounted) {
      setState(() {
        _person = person;
        _isLoadingPerson = false;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);

    final comments = await _repository.getPersonComments(widget.personId);

    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
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
              children: [_buildPersonInfo(), _buildComments()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonInfo() {
    if (_isLoadingPerson) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_person == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPerson, child: const Text('重试')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedImage(
              imageUrl: _person!.image,
              width: 120,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _person!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_person!.nameCN.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _person!.nameCN,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_person!.info.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '基本信息',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _person!.info,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (_person!.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '人物简介',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _person!.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    if (_isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无评论'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadComments, child: const Text('重试')),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment, index);
      },
    );
  }

  Widget _buildCommentItem(PersonComment comment, int index) {
    final isExpanded = _expandedComments.contains(index);
    final hasReplies = comment.replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: CachedImage(
                imageUrl: comment.user.avatar.large,
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
                    comment.user.nickname,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasReplies) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedComments.remove(index);
                } else {
                  _expandedComments.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Row(
                children: [
                  Container(width: 40, height: 1, color: AppColors.divider),
                  const SizedBox(width: 8),
                  Text(
                    isExpanded
                        ? '收起${comment.replies.length}条回复'
                        : '展开${comment.replies.length}条回复',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (isExpanded && hasReplies) ...[
          const SizedBox(height: 16),
          ...comment.replies.map(
            (reply) => Padding(
              padding: const EdgeInsets.only(left: 60, bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: CachedImage(
                      imageUrl: reply.user.avatar.large,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply.user.nickname,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply.content,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(reply.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
