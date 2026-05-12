import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class InputDialog extends StatefulWidget {
  final String? title;
  final String? hintText;
  final String? helperText;
  final String submitLabel;

  const InputDialog({
    Key? key,
    this.title,
    this.hintText,
    this.helperText,
    this.submitLabel = '确定',
  }) : super(key: key);

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    final text = _controller.text;
    if (text.isEmpty) return;
    SmartDialog.dismiss(result: text);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 460,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title ?? '输入',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => SmartDialog.dismiss(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '关闭',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: widget.hintText ?? '请输入内容',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        onPressed: () => _controller.clear(),
                        icon: const Icon(Icons.clear, size: 16),
                        tooltip: '清空',
                      )
                    : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.helperText != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.helperText!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => SmartDialog.dismiss(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasText ? _submit : null,
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
