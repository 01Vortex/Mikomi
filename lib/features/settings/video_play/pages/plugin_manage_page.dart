import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/shared/message_dialog.dart';

class PluginManagePage extends StatefulWidget {
  const PluginManagePage({super.key});

  @override
  State<PluginManagePage> createState() => _PluginManagePageState();
}

class _PluginManagePageState extends State<PluginManagePage> {
  late final VideoPluginManager _pluginManager;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pluginManager = VideoPluginManager();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    setState(() => _isLoading = true);
    await _pluginManager.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleAdd() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '添加数据源',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('新建规则'),
              subtitle: const Text('从零开始创建新的数据源'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/plugin_editor').then((result) {
                  if (result == true) {
                    setState(() {});
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste_outlined),
              title: const Text('从剪贴板导入'),
              subtitle: const Text('导入 Base64 编码的规则'),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('从 JSON 文件导入'),
              subtitle: const Text('选择本地 json 规则文件导入'),
              onTap: () async {
                Navigator.pop(context);
                await _pickJsonFileAndImport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('从云端获取'),
              subtitle: const Text('浏览并安装云端插件'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/plugin_shop').then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入规则'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '粘贴 Base64 编码的规则',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _pluginManager.importPluginFromBase64(
                controller.text.trim(),
              );
              if (!mounted || !dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              if (success) {
                MessageDialog.success(context, '导入成功');
                setState(() {});
              } else {
                MessageDialog.error(context, '导入失败，请检查格式');
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickJsonFileAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) {
      return;
    }

    final success = await _pluginManager.importPluginFromJsonFile(path);
    if (!mounted) {
      return;
    }

    if (success) {
      MessageDialog.success(context, '导入成功');
      setState(() {});
    } else {
      MessageDialog.error(context, '导入失败，请检查 JSON 文件');
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 条规则吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await _pluginManager.removePlugins(_selectedIds);
              if (!mounted || !dialogContext.mounted) {
                return;
              }
              Navigator.pop(dialogContext);
              setState(() {
                _isMultiSelectMode = false;
                _selectedIds.clear();
              });
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isMultiSelectMode
              ? Text('已选择 ${_selectedIds.length} 项')
              : const Text('数据源管理'),
          centerTitle: true,
          leading: _isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedIds.clear();
                    });
                  },
                )
              : null,
          actions: [
            if (_isMultiSelectMode)
              IconButton(
                onPressed: _selectedIds.isEmpty ? null : _handleDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
              )
            else
              IconButton(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '添加数据源',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pluginManager.plugins.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.extension_off_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无数据源',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击右上角 + 添加第一个数据源',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _handleAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('添加数据源'),
                    ),
                  ],
                ),
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) async {
                  await _pluginManager.reorderPlugins(oldIndex, newIndex);
                  setState(() {});
                },
                padding: const EdgeInsets.all(12),
                itemCount: _pluginManager.plugins.length,
                itemBuilder: (context, index) {
                  final plugin = _pluginManager.plugins[index];
                  final isSelected = _selectedIds.contains(plugin.id);

                  return _PluginCard(
                    key: ValueKey(plugin.id),
                    plugin: plugin,
                    isSelected: isSelected,
                    isMultiSelectMode: _isMultiSelectMode,
                    onLongPress: () {
                      if (!_isMultiSelectMode) {
                        setState(() {
                          _isMultiSelectMode = true;
                          _selectedIds.add(plugin.id);
                        });
                      }
                    },
                    onTap: () {
                      if (_isMultiSelectMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(plugin.id);
                            if (_selectedIds.isEmpty) {
                              _isMultiSelectMode = false;
                            }
                          } else {
                            _selectedIds.add(plugin.id);
                          }
                        });
                      }
                    },
                    onCheckboxChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(plugin.id);
                        } else {
                          _selectedIds.remove(plugin.id);
                          if (_selectedIds.isEmpty) {
                            _isMultiSelectMode = false;
                          }
                        }
                      });
                    },
                    onEdit: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/plugin_editor',
                        arguments: plugin,
                      );
                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    onTest: () async {
                      await Navigator.pushNamed(
                        context,
                        '/plugin_test',
                        arguments: plugin,
                      );
                    },
                    onShare: () async {
                      final base64 = _pluginManager.exportPluginToBase64(
                        plugin,
                      );
                      await Clipboard.setData(ClipboardData(text: base64));
                      if (mounted) {
                        MessageDialog.success(this.context, '已复制到剪贴板');
                      }
                    },
                    onDelete: () async {
                      await _pluginManager.removePlugin(plugin);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    dragHandle: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  final VideoPlugin plugin;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final Function(bool?) onCheckboxChanged;
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final Widget dragHandle;

  const _PluginCard({
    super.key,
    required this.plugin,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onLongPress,
    required this.onTap,
    required this.onCheckboxChanged,
    required this.onEdit,
    required this.onTest,
    required this.onShare,
    required this.onDelete,
    required this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMultiSelectMode)
                    Checkbox(value: isSelected, onChanged: onCheckboxChanged)
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.extension_outlined,
                        color: cs.primary,
                        size: 24,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${plugin.version}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMultiSelectMode) ...[
                    _MoreButton(
                      onEdit: onEdit,
                      onTest: onTest,
                      onShare: onShare,
                      onDelete: onDelete,
                    ),
                    const SizedBox(width: 4),
                    dragHandle,
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plugin.baseURL,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onTest;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _MoreButton({
    required this.onEdit,
    required this.onTest,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'test':
            onTest();
            break;
          case 'share':
            onShare();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 12),
              Text('编辑'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'test',
          child: Row(
            children: [
              Icon(Icons.bug_report_outlined),
              SizedBox(width: 12),
              Text('测试'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined),
              SizedBox(width: 12),
              Text('分享'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 12),
              Text('删除'),
            ],
          ),
        ),
      ],
    );
  }
}
