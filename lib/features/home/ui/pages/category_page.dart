import 'package:flutter/material.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/service/category_service.dart';
import 'package:mikomi/shared/anime_detil_converter.dart';
import 'package:mikomi/shared/anime_grid_card.dart';
import 'package:mikomi/shared/skeleton.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryService _service = CategoryService();

  CategoryFilters _filters = const CategoryFilters();
  List<HomeAnimeModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final list = await _service.fetchByFilters(
      _filters,
      forceRefresh: forceRefresh,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _items = list;
      _isLoading = false;
    });
  }

  Future<void> _updateFilters({
    String? region,
    String? genre,
    String? year,
    String? status,
  }) async {
    final nextRegion = region ?? _filters.region;
    final regionChanged = region != null && region != _filters.region;

    setState(() {
      _filters = _filters.copyWith(
        region: nextRegion,
        genre: regionChanged ? '全部' : genre,
        year: year,
        status: status,
      );
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          Expanded(
            child: _isLoading
                ? _buildSkeleton(context)
                : RefreshIndicator(
                    onRefresh: () => _load(forceRefresh: true),
                    child: _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.24),
                              Icon(
                                Icons.inbox_outlined,
                                size: 44,
                                color: context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  '当前筛选暂无内容',
                                  style: TextStyle(color: context.colors.onSurfaceVariant),
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.58,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return AnimeGridCard(
                                  title: item.displayName,
                                  imageUrl: item.coverUrl,
                                  heroTag: 'anime_${item.id}',
                                  onTap: () => AnimeDetilConverter.openBangumiDetail(
                                    context,
                                    item,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final genreOptions = _filters.region == '内地'
        ? CategoryService.mainlandGenreOptions
        : CategoryService.genreOptions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.outline.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          _buildFilterRow(
            label: '地区',
            options: CategoryService.regionOptions,
            selected: _filters.region,
            onSelect: (v) => _updateFilters(region: v),
          ),
          _buildFilterRow(
            label: '类型',
            options: genreOptions,
            selected: _filters.genre,
            onSelect: (v) => _updateFilters(genre: v),
          ),
          _buildFilterRow(
            label: '年份',
            options: CategoryService.yearOptions(),
            selected: _filters.year,
            onSelect: (v) => _updateFilters(year: v),
          ),
          _buildFilterRow(
            label: '状态',
            options: CategoryService.statusOptions,
            selected: _filters.status,
            onSelect: (v) => _updateFilters(status: v),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((option) {
                  final active = selected == option;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option),
                      selected: active,
                      showCheckmark: false,
                      onSelected: (_) => onSelect(option),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                      ),
                      selectedColor: context.colors.primary,
                      backgroundColor: context.colors.surfaceContainerHighest,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        itemCount: 12,
        itemBuilder: (context, index) => const SkeletonGridCard(),
      ),
    );
  }
}
