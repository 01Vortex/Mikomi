import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/data/models/video_plugin.dart';
import 'package:mikomi/features/settings/video_settings/service/plugin_manager_service.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class PluginManagePage extends StatefulWidget {
  const PluginManagePage({super.key});

  @override
  State<PluginManagePage> createState() => _PluginManagePageState();
}

class _PluginManagePageState extends State<PluginManagePage> {
  final VideoPluginManager _pluginManager = VideoPluginManager();
  bool _isMultiSelectMode = false;
  final Set<String> _selectedNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新建规则'),
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
              leading: const Icon(Icons.content_paste),
              title: const Text('从剪贴板导入'),
              onTap: () {
                Navigator.pop(context);
                _showImportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入规则'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '粘贴Base64编码的规则'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: context.colors.outline)),
          ),
          TextButton(
            onPressed: () async {
              final success = await _pluginManager.importPluginFromBase64(
                controller.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? '导入成功' : '导入失败,请检查格式')),
                );
                if (success) {
                  setState(() {});
                }
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除选中的 ${_selectedNames.length} 条规则吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: context.colors.outline)),
          ),
          TextButton(
            onPressed: () async {
              await _pluginManager.removePlugins(_selectedNames);
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedNames.clear();
                });
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (_isMultiSelectMode) {
          setState(() {
            _isMultiSelectMode = false;
            _selectedNames.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isMultiSelectMode
              ? Text('已选择 ${_selectedNames.length} 项')
              : const Text('规则管理'),
          leading: _isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedNames.clear();
                    });
                  },
                )
              : null,
          actions: [
            if (_isMultiSelectMode)
              IconButton(
                onPressed: _selectedNames.isEmpty ? null : _handleDelete,
                icon: const Icon(Icons.delete),
              )
            else
              IconButton(
                onPressed: _handleAdd,
                icon: const Icon(Icons.add),
                tooltip: '添加规则',
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
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无可用规则',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.colors.textSecondary,
                      ),
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
                itemCount: _pluginManager.plugins.length,
                itemBuilder: (context, index) {
                  final plugin = _pluginManager.plugins[index];
                  final isSelected = _selectedNames.contains(plugin.name);

                  return Card(
                    key: ValueKey(plugin.name),
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor: context.colors.primaryContainer,
                      onLongPress: () {
                        if (!_isMultiSelectMode) {
                          setState(() {
                            _isMultiSelectMode = true;
                            _selectedNames.add(plugin.name);
                          });
                        }
                      },
                      onTap: () {
                        if (_isMultiSelectMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedNames.remove(plugin.name);
                              if (_selectedNames.isEmpty) {
                                _isMultiSelectMode = false;
                              }
                            } else {
                              _selectedNames.add(plugin.name);
                            }
                          });
                        }
                      },
                      title: Text(
                        plugin.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Version: ${plugin.version}',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isMultiSelectMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedNames.add(plugin.name);
                                  } else {
                                    _selectedNames.remove(plugin.name);
                                    if (_selectedNames.isEmpty) {
                                      _isMultiSelectMode = false;
                                    }
                                  }
                                });
                              },
                            )
                          else
                            _buildPopupMenu(plugin),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPopupMenu(VideoPlugin plugin) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            final result = await Navigator.pushNamed(
              context,
              '/plugin_editor',
              arguments: plugin,
            );
            if (result == true && mounted) {
              setState(() {});
            }
            break;
          case 'test':
            await Navigator.pushNamed(
              context,
              '/plugin_test',
              arguments: plugin,
            );
            break;
          case 'share':
            final base64 = _pluginManager.exportPluginToBase64(plugin);
            await Clipboard.setData(ClipboardData(text: base64));
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
            }
            break;
          case 'delete':
            await _pluginManager.removePlugin(plugin);
            if (mounted) {
              setState(() {});
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [Icon(Icons.edit), SizedBox(width: 8), Text('编辑')],
          ),
        ),
        const PopupMenuItem(
          value: 'test',
          child: Row(
            children: [
              Icon(Icons.bug_report_outlined),
              SizedBox(width: 8),
              Text('测试'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [Icon(Icons.share), SizedBox(width: 8), Text('分享')],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [Icon(Icons.delete), SizedBox(width: 8), Text('删除')],
          ),
        ),
      ],
    );
  }
}
