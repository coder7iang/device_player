import 'package:device_player/page/flie/file_manager_provider.dart';
import 'package:device_player/page/flie/file_model.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class FileManagerPage extends ConsumerStatefulWidget {
  final String deviceId;

  const FileManagerPage(this.deviceId, {Key? key}) : super(key: key);

  @override
  ConsumerState<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends ConsumerState<FileManagerPage> {
  @override
  void initState() {
    super.initState();
    // 初始化文件管理页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileManagerProvider(widget.deviceId).notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileManagerNotifier = ref.read(fileManagerProvider(widget.deviceId).notifier);
    
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            title: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(fileManagerProvider(widget.deviceId));
                var title = state.currentPath.substring(
                    state.currentPath.lastIndexOf("/", state.currentPath.lastIndexOf("/") - 1) + 1,
                    state.currentPath.lastIndexOf("/"));
                return Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                );
              },
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black38),
              onPressed: () {
                fileManagerNotifier.backFolder();
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black38),
                onPressed: () {
                  fileManagerNotifier.refresh();
                },
              ),
            ],
          ),
          Expanded(
            child: DropTarget(
              onDragDone: (data) {
                fileManagerNotifier.onDragDone(data, -1);
              },
              child: Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(fileManagerProvider(widget.deviceId));
                  if (state.files.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            "images/ic_empty_file.svg",
                            width: 500,
                            height: 500,
                          ),
                          const Text(
                            "暂无文件",
                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.files.length,
                    itemBuilder: (context, index) {
                      return itemView(state.files[index], index, fileManagerNotifier);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget itemView(FileModel model, int index, FileManagerNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: model.isSelect
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Listener(
        onPointerDown: (event) {
          notifier.onPointerDown(context, event, index);
        },
        child: ListTile(
          tileColor: model.isSelect ? Theme.of(context).hoverColor : null,
          hoverColor: Colors.transparent,
          leading: model.icon == null
              ? null
              : Icon(
                  model.icon,
                  color: model.type == FileManagerNotifier.typeFolder
                      ? Colors.blue
                      : Colors.grey,
                ),
          title: Text(model.name),
          onTap: () {
            notifier.openFolder(model);
          },
        ),
      ),
    );
  }
}
