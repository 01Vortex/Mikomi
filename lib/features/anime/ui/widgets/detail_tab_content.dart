import 'package:flutter/material.dart';
import 'package:mikomi/config/app_theme.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/anime/models/anime_related_info_model.dart';
import 'package:mikomi/features/anime/models/staff_info_model.dart';
import 'package:mikomi/features/anime/data/bangumi_detail.dart';
import 'package:mikomi/features/anime/ui/widgets/detail_popover.dart';
import 'package:mikomi/shared/scrolling_text.dart';
import 'package:mikomi/shared/skeleton.dart';

class DetailTabContent extends StatefulWidget {
  final Anime anime;

  const DetailTabContent({super.key, required this.anime});

  @override
  State<DetailTabContent> createState() => _DetailTabContentState();
}

class _DetailTabContentState extends State<DetailTabContent> {
  late final BangumiDetail _repository;
  List<AnimeRelatedInfoModel> _characters = [];
  List<StaffInfoModel> _staff = [];
  bool _isLoadingCharacters = false;
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    _repository = BangumiDetail();
    // 不在initState中加载数据，改为懒加载
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingCharacters = true;
      _isLoadingStaff = true;
    });

    debugPrint('开始加载角色和制作人员数据，番剧ID: ${widget.anime.id}');

    final results = await Future.wait([
      _repository.getCharacters(widget.anime.id),
      _repository.getStaff(widget.anime.id),
    ]);

    if (mounted) {
      final characters = results[0] as List<AnimeRelatedInfoModel>;
      final staff = results[1] as List<StaffInfoModel>;

      debugPrint('加载完成 - 角色数量: ${characters.length}, 制作人员数量: ${staff.length}');

      // 角色排序：主角 > 配角 > 客串 > 其他
      characters.sort((a, b) {
        const relationOrder = {'主角': 1, '配角': 2, '客串': 3};

        final orderA = relationOrder[a.relation] ?? 4;
        final orderB = relationOrder[b.relation] ?? 4;

        return orderA.compareTo(orderB);
      });

      // 制作人员排序：原作 > 导演 > 系列构成 > 角色设计 > 音乐 > 其他
      staff.sort((a, b) {
        const positionOrder = {'原作': 1, '导演': 2, '系列构成': 3, '角色设计': 4, '音乐': 5};

        final posA = a.positions.isNotEmpty ? a.positions.first.cn : '';
        final posB = b.positions.isNotEmpty ? b.positions.first.cn : '';

        final orderA = positionOrder[posA] ?? 99;
        final orderB = positionOrder[posB] ?? 99;

        return orderA.compareTo(orderB);
      });

      setState(() {
        _characters = characters;
        _staff = staff;
        _isLoadingCharacters = false;
        _isLoadingStaff = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 懒加载：首次构建时加载数据
    if (!_isLoadingCharacters &&
        !_isLoadingStaff &&
        _characters.isEmpty &&
        _staff.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '角色',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingCharacters)
            _buildSkeletonGrid()
          else if (_characters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '暂无角色信息',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            _buildHorizontalGrid(_characters, _buildCharacterCard),
          const SizedBox(height: 32),
          const Text(
            '制作人员',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_isLoadingStaff)
            _buildSkeletonGrid()
          else if (_staff.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '暂无制作人员信息',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            _buildHorizontalGrid(_staff, _buildStaffCard),
        ],
      ),
    );
  }

  Widget _buildHorizontalGrid<T>(List<T> items, Widget Function(T) builder) {
    final columnCount = (items.length / 2).ceil();

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: columnCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final firstIndex = index * 2;
          final secondIndex = firstIndex + 1;

          return Column(
            children: [
              SizedBox(height: 80, child: builder(items[firstIndex])),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: secondIndex < items.length
                    ? builder(items[secondIndex])
                    : const SizedBox(width: 160),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Column(
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildSkeletonCard(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildSkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          const SkeletonCircle(size: 60),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonText(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(AnimeRelatedInfoModel character) {
    return InkWell(
      onTap: () {
        debugPrint('点击角色卡片: ${character.name}');
        _showCharacterInfoModel(context, character.id);
      },
      child: SizedBox(
        width: 160,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: ClipOval(
                child: character.images.grid.isNotEmpty
                    ? Image.network(
                        character.images.grid,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 30);
                        },
                      )
                    : const Icon(Icons.person, size: 30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ScrollingText(
                          text: character.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          height: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            character.relation,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (character.actors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ScrollingText(
                      text: character.actors.first.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      height: 15,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffInfoModel StaffInfoModel) {
    return InkWell(
      onTap: () {
        debugPrint('点击制作人员卡片: ${StaffInfoModel.staff.name}');
        _showPersonInfoModel(context, StaffInfoModel.staff.id);
      },
      child: SizedBox(
        width: 160,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: ClipOval(
                child: (StaffInfoModel.staff.images?.grid ?? '').isNotEmpty
                    ? Image.network(
                        StaffInfoModel.staff.images!.grid,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, size: 30);
                        },
                      )
                    : const Icon(Icons.person, size: 30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ScrollingText(
                          text: StaffInfoModel.staff.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          height: 18,
                        ),
                      ),
                      if (StaffInfoModel.positionText.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              StaffInfoModel.positionText,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (StaffInfoModel.staff.nameCN.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ScrollingText(
                      text: StaffInfoModel.staff.nameCN,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      height: 15,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCharacterInfoModel(BuildContext context, int characterId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: DetailPopover(id: characterId, type: InfoType.character),
    ),
  );
}

void _showPersonInfoModel(BuildContext context, int personId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: DetailPopover(id: personId, type: InfoType.person),
    ),
  );
}
