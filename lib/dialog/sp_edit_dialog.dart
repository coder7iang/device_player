import 'package:device_player/dialog/smart_dialog_utils.dart';
import 'package:device_player/services/adb_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SP 条目类型
enum SpType { string, integer, long, float, boolean, set, nullValue }

/// 一条 SP 记录，记录在原始 XML 中的起止位置，便于精确替换
class SpEntry {
  final SpType type;
  final String key;
  String value; // set 类型用换行分隔多个 string 子项
  final int start; // 在原始 XML 中的起始下标（含）
  final int end; // 在原始 XML 中的结束下标（不含）

  SpEntry({
    required this.type,
    required this.key,
    required this.value,
    required this.start,
    required this.end,
  });

  String get typeLabel {
    switch (type) {
      case SpType.string:
        return 'string';
      case SpType.integer:
        return 'int';
      case SpType.long:
        return 'long';
      case SpType.float:
        return 'float';
      case SpType.boolean:
        return 'boolean';
      case SpType.set:
        return 'set';
      case SpType.nullValue:
        return 'null';
    }
  }

  bool get editable => type != SpType.nullValue && type != SpType.set;
}

/// XML 解析与序列化工具
class SpXmlCodec {
  /// 解析 SP XML，返回条目列表
  static List<SpEntry> parse(String xml) {
    final entries = <SpEntry>[];

    // string: <string name="K">VALUE</string>，VALUE 可能跨行
    final stringRe =
        RegExp(r'<string\s+name="([^"]*)"\s*>([\s\S]*?)</string>');
    for (final m in stringRe.allMatches(xml)) {
      entries.add(SpEntry(
        type: SpType.string,
        key: m.group(1) ?? '',
        value: _unescape(m.group(2) ?? ''),
        start: m.start,
        end: m.end,
      ));
    }

    // 自闭合标签：int / long / float / boolean
    final selfRe = RegExp(
        r'<(int|long|float|boolean)\s+name="([^"]*)"\s+value="([^"]*)"\s*/>');
    for (final m in selfRe.allMatches(xml)) {
      final tag = m.group(1)!;
      SpType type;
      switch (tag) {
        case 'int':
          type = SpType.integer;
          break;
        case 'long':
          type = SpType.long;
          break;
        case 'float':
          type = SpType.float;
          break;
        default:
          type = SpType.boolean;
      }
      entries.add(SpEntry(
        type: type,
        key: m.group(2) ?? '',
        value: m.group(3) ?? '',
        start: m.start,
        end: m.end,
      ));
    }

    // null: <null name="K" />
    final nullRe = RegExp(r'<null\s+name="([^"]*)"\s*/>');
    for (final m in nullRe.allMatches(xml)) {
      entries.add(SpEntry(
        type: SpType.nullValue,
        key: m.group(1) ?? '',
        value: '',
        start: m.start,
        end: m.end,
      ));
    }

    // set: <set name="K">...</set>
    final setRe = RegExp(r'<set\s+name="([^"]*)"\s*>([\s\S]*?)</set>');
    for (final m in setRe.allMatches(xml)) {
      final inner = m.group(2) ?? '';
      final items = RegExp(r'<string\s*>([\s\S]*?)</string>')
          .allMatches(inner)
          .map((sm) => _unescape(sm.group(1) ?? ''))
          .toList();
      entries.add(SpEntry(
        type: SpType.set,
        key: m.group(1) ?? '',
        value: items.join('\n'),
        start: m.start,
        end: m.end,
      ));
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  /// 用新值替换某个条目，返回新的整段 XML
  static String replaceEntry(String xml, SpEntry entry, String newValue) {
    final newElement = _serialize(entry.type, entry.key, newValue);
    return xml.replaceRange(entry.start, entry.end, newElement);
  }

  static String _serialize(SpType type, String key, String value) {
    final escapedKey = _escapeAttr(key);
    switch (type) {
      case SpType.string:
        return '<string name="$escapedKey">${_escapeText(value)}</string>';
      case SpType.integer:
        return '<int name="$escapedKey" value="${_escapeAttr(value)}" />';
      case SpType.long:
        return '<long name="$escapedKey" value="${_escapeAttr(value)}" />';
      case SpType.float:
        return '<float name="$escapedKey" value="${_escapeAttr(value)}" />';
      case SpType.boolean:
        return '<boolean name="$escapedKey" value="${_escapeAttr(value)}" />';
      case SpType.nullValue:
        return '<null name="$escapedKey" />';
      case SpType.set:
        // value 按换行拆为多个 <string>
        final items = value
            .split('\n')
            .map((s) => '        <string>${_escapeText(s)}</string>')
            .join('\n');
        return '<set name="$escapedKey">\n$items\n    </set>';
    }
  }

  static String _escapeText(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static String _escapeAttr(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _unescape(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#10;', '\n')
        .replaceAll('&#9;', '\t')
        .replaceAll('&#13;', '\r')
        .replaceAll('&amp;', '&');
  }
}

/// SP 编辑对话框
class SpEditDialog extends StatefulWidget {
  final List<String> files;
  final String packageName;

  const SpEditDialog({
    Key? key,
    required this.files,
    required this.packageName,
  }) : super(key: key);

  @override
  State<SpEditDialog> createState() => _SpEditDialogState();
}

class _SpEditDialogState extends State<SpEditDialog> {
  late String _currentFile;
  String _xmlContent = '';
  List<SpEntry> _entries = [];
  String _searchText = '';
  late TextEditingController _searchController;
  bool _loading = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.files.first;
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
    _loadFile(_currentFile);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFile(String filename) async {
    setState(() {
      _loading = true;
      _entries = [];
    });
    final content = await AdbService.instance.readSpFile(filename);
    if (!mounted) return;
    if (content == null) {
      SmartDialogUtils.showError('读取 $filename 失败');
      setState(() {
        _loading = false;
        _xmlContent = '';
      });
      return;
    }
    setState(() {
      _xmlContent = content;
      _entries = SpXmlCodec.parse(content);
      _loading = false;
      _dirty = false;
    });
  }

  List<SpEntry> get _filtered {
    if (_searchText.isEmpty) return _entries;
    final q = _searchText.toLowerCase();
    return _entries.where((e) => e.key.toLowerCase().contains(q)).toList();
  }

  Future<void> _editEntry(SpEntry entry) async {
    if (!entry.editable) {
      SmartDialogUtils.showWarning('${entry.typeLabel} 类型暂不支持编辑');
      return;
    }
    final newValue = await _showValueEditor(entry);
    if (newValue == null) return;
    if (newValue == entry.value) return;

    // 替换原始 XML 中对应位置，重新解析以更新所有条目位置
    final newXml = SpXmlCodec.replaceEntry(_xmlContent, entry, newValue);
    setState(() {
      _xmlContent = newXml;
      _entries = SpXmlCodec.parse(newXml);
      _dirty = true;
    });
  }

  Future<String?> _showValueEditor(SpEntry entry) {
    final controller = TextEditingController(text: entry.value);
    String? error;
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: Text('编辑 ${entry.key} (${entry.typeLabel})'),
              content: SizedBox(
                width: 400,
                child: _buildEditorField(entry, controller, (v) {
                  setStateDialog(() {
                    error = _validate(entry.type, v);
                  });
                }),
              ),
              actions: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: error != null
                      ? null
                      : () {
                          final v = controller.text;
                          final err = _validate(entry.type, v);
                          if (err != null) {
                            setStateDialog(() => error = err);
                            return;
                          }
                          Navigator.of(ctx).pop(v);
                        },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEditorField(
    SpEntry entry,
    TextEditingController controller,
    void Function(String) onChanged,
  ) {
    if (entry.type == SpType.boolean) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final isTrue = controller.text == 'true';
          return Row(
            children: [
              const Text('值：'),
              const SizedBox(width: 12),
              Switch(
                value: isTrue,
                onChanged: (v) {
                  final s = v ? 'true' : 'false';
                  controller.text = s;
                  setLocal(() {});
                  onChanged(s);
                },
              ),
              const SizedBox(width: 8),
              Text(
                controller.text,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      );
    }
    final isNumeric = entry.type == SpType.integer ||
        entry.type == SpType.long ||
        entry.type == SpType.float;
    return TextField(
      controller: controller,
      autofocus: true,
      maxLines: entry.type == SpType.string ? null : 1,
      minLines: entry.type == SpType.string ? 1 : 1,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(signed: true, decimal: true)
          : TextInputType.text,
      inputFormatters: entry.type == SpType.integer || entry.type == SpType.long
          ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9]'))]
          : null,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: onChanged,
    );
  }

  String? _validate(SpType type, String value) {
    switch (type) {
      case SpType.integer:
        final v = int.tryParse(value);
        if (v == null) return '请输入合法的 int 值';
        // int32 范围
        if (v < -2147483648 || v > 2147483647) return '超出 int 范围';
        return null;
      case SpType.long:
        if (int.tryParse(value) == null) return '请输入合法的 long 值';
        return null;
      case SpType.float:
        if (double.tryParse(value) == null) return '请输入合法的 float 值';
        return null;
      case SpType.boolean:
        if (value != 'true' && value != 'false') return '只能为 true 或 false';
        return null;
      default:
        return null;
    }
  }

  Future<void> _save() async {
    if (!_dirty) {
      SmartDialogUtils.showInfo('没有修改');
      return;
    }
    final ok = await SmartDialogUtils.showConfirm(
      title: '保存 SP',
      content: '保存将强制停止应用以避免内存缓存覆盖修改，是否继续？',
    );
    if (!ok) return;
    SmartDialogUtils.showLoading('正在保存...');
    final success = await AdbService.instance
        .writeSpFile(_currentFile, _xmlContent);
    SmartDialogUtils.hideLoading();
    if (success) {
      SmartDialogUtils.showSuccess('保存成功');
      if (mounted) setState(() => _dirty = false);
    } else {
      SmartDialogUtils.showError('保存失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 500,
          maxWidth: MediaQuery.of(context).size.width * 0.85,
          minHeight: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildFileSelector(),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索 key',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildList()),
              const SizedBox(height: 12),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'SharedPreferences  ·  ${widget.packageName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: '关闭',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFileSelector() {
    if (widget.files.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _currentFile,
          style: const TextStyle(color: Colors.black87),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          initialSelection: _currentFile,
          width: constraints.maxWidth,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          menuHeight: 320,
          leadingIcon: const Icon(Icons.search, size: 20),
          inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          dropdownMenuEntries: widget.files
              .map((f) => DropdownMenuEntry<String>(value: f, label: f))
              .toList(),
          onSelected: (v) async {
            if (v == null || v == _currentFile) return;
            if (_dirty) {
              final discard = await SmartDialogUtils.showConfirm(
                title: '切换文件',
                content: '当前文件有未保存的修改，是否丢弃？',
              );
              if (!discard) return;
            }
            setState(() => _currentFile = v);
            await _loadFile(v);
          },
        );
      },
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          _entries.isEmpty ? '该文件没有可识别的条目' : '没有匹配的 key',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = items[index];
        return ListTile(
          dense: true,
          title: _highlight(e.key, _searchText),
          subtitle: Text(
            e.type == SpType.nullValue ? '<null>' : e.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: e.editable ? Colors.black54 : Colors.grey,
              fontSize: 12,
            ),
          ),
          leading: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor(e.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              e.typeLabel,
              style: TextStyle(
                fontSize: 11,
                color: _typeColor(e.type),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: e.editable
              ? const Icon(Icons.edit, size: 18, color: Colors.grey)
              : null,
          onTap: () => _editEntry(e),
        );
      },
    );
  }

  Color _typeColor(SpType type) {
    switch (type) {
      case SpType.string:
        return Colors.blue;
      case SpType.integer:
      case SpType.long:
        return Colors.deepPurple;
      case SpType.float:
        return Colors.teal;
      case SpType.boolean:
        return Colors.orange;
      case SpType.set:
        return Colors.brown;
      case SpType.nullValue:
        return Colors.grey;
    }
  }

  Widget _highlight(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) return Text(text);
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              backgroundColor: Colors.yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      children: [
        Text(
          _dirty ? '有未保存的修改' : '共 ${_entries.length} 项',
          style: TextStyle(
            color: _dirty ? Colors.orange : Colors.grey,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _loading ? null : () => _loadFile(_currentFile),
          child: const Text('重新读取'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _loading || !_dirty ? null : _save,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('保存'),
        ),
      ],
    );
  }
}
