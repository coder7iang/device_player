import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class InputDialog extends StatelessWidget {
  final String? title;
  final String? hintText;

  final TextEditingController _controller = TextEditingController();

  InputDialog({Key? key, this.title, this.hintText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? ""),
      content: TextField(
        autofocus: true,
        controller: _controller,
        decoration: InputDecoration(hintText: hintText),
        onSubmitted: (String value) {
          SmartDialog.dismiss(result: value);
        },
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("确定"),
          onPressed: () {
            SmartDialog.dismiss(result: _controller.text);
          },
        ),
      ],
    );
  }
}
