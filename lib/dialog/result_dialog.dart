import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ResultDialog extends StatefulWidget {
  final String? title;
  final String? content;

  const ResultDialog({Key? key, this.title, this.content}) : super(key: key);

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? "提示"),
      content: SelectableText(
        widget.content ?? "",
      ),
      actions: <Widget>[
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
