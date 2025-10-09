import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ConfirmDialog extends StatelessWidget {
  final String? title;
  final String? content;

  const ConfirmDialog(
      {Key? key, this.title, this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? "提示"),
      content: Text(content ?? ""),
      actions: <Widget>[
        TextButton(
          child: const Text(
            "取消",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          onPressed: () {
            SmartDialog.dismiss();
          },
        ),
        TextButton(
          child: const Text("确定"),
          onPressed: () {
            SmartDialog.dismiss(result: true);
          },
        ),
      ],
    );
  }
}
