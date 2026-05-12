import 'package:device_player/common/key_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

typedef RemoteControlTapCallback = Function(KeyCode);

class RemoteControlDialog extends StatelessWidget {
  final RemoteControlTapCallback? onTap;

  const RemoteControlDialog({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: keyboardListener,
        child: Container(
          width: 240,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: buildCloseView(context),
              ),
              _buildDirectionWidget(),
              const SizedBox(height: 12),
              _buildVolumeWidget(),
              const SizedBox(height: 12),
              _buildManagerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionWidget() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(150),
      ),
      child: Column(
        children: [
          buildDirectionView(
            width: 56,
            height: 56,
            icon: Icons.keyboard_arrow_up,
            radius: BorderRadius.circular(80),
            onTap: () {
              _onTapKey(KeyCode.dpadUp);
            },
          ),
          Expanded(
            child: Row(
              children: [
                buildDirectionView(
                  width: 56,
                  height: 56,
                  radius: BorderRadius.circular(80),
                  icon: Icons.keyboard_arrow_left,
                  onTap: () {
                    _onTapKey(KeyCode.dpadLeft);
                  },
                ),
                buildOKButton(),
                buildDirectionView(
                  width: 56,
                  height: 56,
                  radius: BorderRadius.circular(80),
                  icon: Icons.keyboard_arrow_right,
                  onTap: () {
                    _onTapKey(KeyCode.dpadRight);
                  },
                ),
              ],
            ),
          ),
          buildDirectionView(
            width: 56,
            height: 56,
            radius: BorderRadius.circular(80),
            icon: Icons.keyboard_arrow_down,
            onTap: () {
              _onTapKey(KeyCode.dpadDown);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeWidget() {
    return Container(
      width: 200,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Row(
        children: [
          Expanded(
            child: buildDirectionView(
              width: 90,
              height: 44,
              radius: BorderRadius.circular(60),
              icon: Icons.volume_down,
              onTap: () {
                _onTapKey(KeyCode.volumeDown);
              },
            ),
          ),
          Expanded(
            child: buildDirectionView(
              width: 90,
              height: 44,
              radius: BorderRadius.circular(60),
              icon: Icons.volume_up,
              onTap: () {
                _onTapKey(KeyCode.volumeUp);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerWidget() {
    return SizedBox(
      height: 48,
      width: 200,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(60),
            ),
            child: buildDirectionView(
              width: 44,
              height: 44,
              radius: BorderRadius.circular(60),
              icon: Icons.arrow_back,
              onTap: () {
                _onTapKey(KeyCode.back);
              },
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(60),
            ),
            child: buildDirectionView(
              width: 44,
              height: 44,
              radius: BorderRadius.circular(60),
              icon: Icons.home,
              onTap: () {
                _onTapKey(KeyCode.home);
              },
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(60),
            ),
            child: buildDirectionView(
              width: 44,
              height: 44,
              radius: BorderRadius.circular(60),
              icon: Icons.menu,
              onTap: () {
                _onTapKey(KeyCode.menu);
              },
            ),
          )
        ],
      ),
    );
  }

  void keyboardListener(KeyEvent event) {
    if (event is KeyUpEvent) {
      if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
        _onTapKey(KeyCode.dpadUp);
      } else if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
        _onTapKey(KeyCode.dpadDown);
      } else if (event.physicalKey == PhysicalKeyboardKey.arrowLeft) {
        _onTapKey(KeyCode.dpadLeft);
      } else if (event.physicalKey == PhysicalKeyboardKey.arrowRight) {
        _onTapKey(KeyCode.dpadRight);
      } else if (event.physicalKey == PhysicalKeyboardKey.enter) {
        _onTapKey(KeyCode.dpadCenter);
      }
    }
  }

  Widget buildCloseView(BuildContext context) {
    return IconButton(
      onPressed: () => SmartDialog.dismiss(),
      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
      tooltip: '关闭',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  Widget buildOKButton() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(120),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _onTapKey(KeyCode.dpadCenter);
            },
            borderRadius: BorderRadius.circular(120),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.black45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDirectionView({
    required double width,
    required double height,
    required IconData icon,
    required BorderRadius radius,
    GestureTapCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: width,
          child: Icon(
            icon,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }

  void _onTapKey(KeyCode keyCode) {
    onTap?.call(keyCode);
  }
}
