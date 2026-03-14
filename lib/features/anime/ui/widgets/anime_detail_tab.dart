import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/models/character_item.dart';
import 'package:mikomi/core/models/staff_item.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/anime/data/datasources/detail_remote_datasource.dart';
import 'package:mikomi/features/anime/data/repositories/detail_repository_impl.dart';
import 'package:mikomi/features/anime/ui/pages/anime_more_info.dart';
import 'package:mikomi/shared/widgets/cached_image.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';

class AnimeDetailTab extends StatefulWidget {
  final BangumiItem bangumiItem;

  const AnimeDetailTab({super.key, required this.bangumiItem});

  @override
  State<AnimeDetailTab> createState() => _AnimeDetailTabState();
}

class _AnimeDetailTabState extends State<AnimeDetailTab> {
  late final DetailRepositoryImpl _repository;
  List<CharacterItem> _characters = [];
  List<StaffItem> _staff = [];
  bool _isLoadingCharacters = false;
  bool _isLoadingStaff = false;

  @override
  void initState() {
    super.initState();
    final dataSource = DetailRemoteDataSourceImpl(DioClient());
    _repository = DetailRepositoryImpl(dataSource);
    // 不在initState中加载数据，改为懒加载
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingCharacters = true;
      _isLoadingStaff = true;
    });

    print('开始加载角色和制作人员数据，番剧ID: ${widget.bangumiItem.id}');

    final results = await Future.wait([
      _repository.getCharacters(widget.bangumiItem.id),
      _repository.getStaff(widget.bangumiItem.id),
    ]);

    if (mounted) {
      final characters = results[0] as List<CharacterItem>;
      final staff = results[1] as List<StaffItem>;

      print('加载完成 - 角色数量: ${characters.length}, 制作人员数量: ${staff.length}');

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
    // 交替分配到两行，保持重要角色在前面的同时分散到两行
    final firstRow = <T>[];
    final secondRow = <T>[];

    for (int i = 0; i < items.length; i++) {
      if (i % 2 == 0) {
        firstRow.add(items[i]);
      } else {
        secondRow.add(items[i]);
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: firstRow.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => builder(firstRow[index]),
          ),
        ),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: secondRow.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => builder(secondRow[index]),
            ),
          ),
        ],
      ],
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

  Widget _buildCharacterCard(CharacterItem character) {
    return InkWell(
      onTap: () {
        print('点击角色卡片: ${character.name}');
        _showCharacterDetail(context, character.id);
      },
      child: SizedBox(
        width: 160,
        child: Row(
          children: [
            ClipOval(
              child: CachedImage(
                imageUrl: character.images.medium,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
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

  Widget _buildStaffCard(StaffItem staffItem) {
    return InkWell(
      onTap: () {
        print('点击制作人员卡片: ${staffItem.staff.name}');
        _showPersonDetail(context, staffItem.staff.id);
      },
      child: SizedBox(
        width: 160,
        child: Row(
          children: [
            ClipOval(
              child: CachedImage(
                imageUrl: staffItem.staff.images?.medium ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
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
                          text: staffItem.staff.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          height: 18,
                        ),
                      ),
                      if (staffItem.positionText.isNotEmpty) ...[
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
                              staffItem.positionText,
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
                  if (staffItem.staff.nameCN.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ScrollingText(
                      text: staffItem.staff.nameCN,
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

void _showCharacterDetail(BuildContext context, int characterId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: AnimeMoreInfo(id: characterId, type: InfoType.character),
    ),
  );
}

void _showPersonDetail(BuildContext context, int personId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: AnimeMoreInfo(id: personId, type: InfoType.person),
    ),
  );
}
