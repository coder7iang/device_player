import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PopUpMenuButton<T extends PopUpMenuItem> extends ConsumerStatefulWidget {
  final PopUpMenuButtonViewModel<T> viewModel;

  final String menuTip;
  final Color? color;

  final Function(T)? onSelected;

  const PopUpMenuButton({
    Key? key,
    required this.viewModel,
    required this.menuTip,
    this.onSelected,
    this.color,
  }) : super(key: key);

  @override
  ConsumerState<PopUpMenuButton<T>> createState() => _PopUpMenuButtonState<T>();
}

class _PopUpMenuButtonState<T extends PopUpMenuItem>
    extends ConsumerState<PopUpMenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: "",
      child: _menuTitleWidget(context),
      onSelected: (model) {
        widget.viewModel.selectValue = model;
        widget.onSelected?.call(model);
      },
      itemBuilder: (context) {
        List<PopupMenuItem<T>> items = [];
        for (var element in widget.viewModel.list) {
          PopupMenuItem<T> item = PopupMenuItem(
            value: element,
            child: Text(element.menuItemTitle),
          );
          items.add(item);
        }
        return items;
      },
    );
  }

  Widget _menuTitleWidget(BuildContext context) {
    var text = widget.viewModel.selectValue?.menuItemTitle ?? widget.menuTip;
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(
              minWidth: 60,
            ),
            child: Text(
              text,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: widget.color ?? const Color(0xFF666666),
              ),
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: widget.color ?? const Color(0xFF666666),
          ),
        ],
      ),
    );
  }
}

class PopUpMenuItem {
  String menuItemTitle;

  PopUpMenuItem(this.menuItemTitle);
}

class PopUpMenuButtonViewModel<T extends PopUpMenuItem> {
  List<T> list = [];

  T? selectValue;

  PopUpMenuButtonViewModel();

  void setData(List<T> data) {
    list = data;
  }
}
