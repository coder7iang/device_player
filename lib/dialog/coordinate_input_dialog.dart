import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CoordinateInputDialog extends StatefulWidget {
  const CoordinateInputDialog({Key? key}) : super(key: key);

  @override
  State<CoordinateInputDialog> createState() => _CoordinateInputDialogState();
}

class _CoordinateInputDialogState extends State<CoordinateInputDialog> {
  late final TextEditingController _xController;
  late final TextEditingController _yController;
  final FocusNode _yFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _xController = TextEditingController();
    _yController = TextEditingController();
    _xController.addListener(_onChanged);
    _yController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _xController.removeListener(_onChanged);
    _yController.removeListener(_onChanged);
    _xController.dispose();
    _yController.dispose();
    _yFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit =>
      _xController.text.trim().isNotEmpty &&
      _yController.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final x = _xController.text.trim();
    final y = _yController.text.trim();
    SmartDialog.dismiss(result: '$x,$y');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '屏幕点击坐标',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
            Row(
              children: [
                Expanded(child: _buildField('X', _xController, autofocus: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Y', _yController, focusNode: _yFocus)),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '坐标原点 (0,0) 在屏幕左上角，向右 X 增大，向下 Y 增大',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => SmartDialog.dismiss(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _canSubmit ? _submit : null,
                  icon: const Icon(Icons.touch_app, size: 16),
                  label: const Text('点击'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      focusNode: focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      textInputAction:
          autofocus ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (autofocus) {
          _yFocus.requestFocus();
        } else {
          _submit();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        hintText: '0',
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
