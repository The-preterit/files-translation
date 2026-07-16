import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:monitorx/monitorx.dart';
import 'package:permission_handler/permission_handler.dart';

class DevicePreviewController extends GetxController {
  final _monitorxPlugin = Monitorx();
  final String did;
  final isShow = false.obs;

  // 打开监控音频  false 不播放音频  true 播放音频
  final isPlayAudio = false.obs;
  // 打开对讲  false 不开启对讲  true 开启对讲
  final isSpeak = false.obs;

  DevicePreviewController(this.did);

  @override
  void onInit() {
    super.onInit();
    _listenEvents();
    connect();
  }

  @override
  void onClose() {
    // 页面关闭时，关闭音频和对讲
    if (isSpeak.value) openLiveSpeak();
    if (isPlayAudio.value) openLiveAudio();
    _monitorxPlugin.disconnectDevice(did);
    super.onClose();
  }

  Future<void> _listenEvents() async {
    await _monitorxPlugin.monitorxGeneral((value) {

      print('DevicePreviewController _listenEvents: $value');

      final data = json.decode(value.toString());

      if (data['code'] == 2001) {
        EasyLoading.dismiss();
        isShow.value = !isShow.value;
      }
    });
  }

  Future<void> connect() async {
    EasyLoading.show(status: '连接中...');
    await _monitorxPlugin.connectDevice(did, 0);
  }

  Future<void> disconnect() async {
    await _monitorxPlugin.disconnectDevice(did);
    Get.back();
    super.onClose();
  }

  // 云台方向控制
  Future<void> ptzMove(String direction, {int mType = 1}) async {
    HapticFeedback.mediumImpact();
    Map<String, String> ptzArgs = <String, String>{
      'did': did,
      'direction': direction,
      'channel': '0',
    };
    if (mType == 0) {
      // 长按模式
      ptzArgs['nSpeed'] = '3';
      ptzArgs['action'] = 'start';
    }
    await _monitorxPlugin.ptzNormal(ptzArgs);
  }

  // 云台停止
  Future<void> ptzStop(String direction) async {
    Map<String, String> ptzArgs = <String, String>{
      'did': did,
      'direction': direction,
      'channel': '0',
      'nSpeed': '3',
      'action': 'stop',
    };
    await _monitorxPlugin.ptzNormal(ptzArgs);
  }

  // 打开监控音频
  Future<void> openLiveAudio() async {
    Map<String, Object> arguments = {
      'did': did,
      'eventType': 'live_audio',
      'isPlayAudio': isPlayAudio.value,
      'openChannel': -1,
    };
    await _monitorxPlugin.operateVideoEvent(arguments);
    isPlayAudio.value = !isPlayAudio.value;
  }

  // 打开对讲
  Future<void> openLiveSpeak() async {
    // 检查麦克风权限
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        EasyLoading.showError('需要麦克风权限才能使用对讲功能');
        return;
      }
    }
    Map<String, Object> arguments = {
      'did': did,
      'eventType': 'live_speak',
      'isSpeak': isSpeak.value,
      'openChannel': -1,
    };
    await _monitorxPlugin.operateVideoEvent(arguments);
    isSpeak.value = !isSpeak.value;
  }
}

class DevicePreviewPage extends StatefulWidget {
  final String did;
  final String alias;

  const DevicePreviewPage({
    super.key,
    required this.did,
    required this.alias,
  });

  @override
  State<DevicePreviewPage> createState() => _DevicePreviewPageState();
}

class _DevicePreviewPageState extends State<DevicePreviewPage> {
  late final controller = Get.put(DevicePreviewController(widget.did));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alias.isNotEmpty ? widget.alias : widget.did),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => controller.disconnect(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 视频区域 + 底部工具栏
          Obx(() => controller.isShow.value
              ? SizedBox(
                  height: MediaQuery.sizeOf(context).height / 2,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // 视频
                      Container(
                        color: Colors.black,
                        child: AndroidView(
                          viewType: 'mx-video',
                          creationParams: <String, dynamic>{'did': widget.did},
                          creationParamsCodec: const StandardMessageCodec(),
                        ),
                      ),
                      // 底部工具栏：语音、对讲
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildVideoToolbar(),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: MediaQuery.sizeOf(context).height / 2,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在连接设备...'),
                      ],
                    ),
                  ),
                )),
          Expanded(
            child: Center(
              child: _buildJoystick(),
            ),
          ),
        ],
      ),
    );
  }

  // 视频底部工具栏（语音、对讲）
  Widget _buildVideoToolbar() {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      height: 40,
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 语音播放
          InkWell(
            onTap: () => controller.openLiveAudio(),
            child: Obx(
              () => Icon(
                controller.isPlayAudio.value
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: controller.isPlayAudio.value
                    ? Colors.lightGreen
                    : Colors.white,
                size: 25,
              ),
            ),
          ),
          // 对讲
          InkWell(
            onTap: () => controller.openLiveSpeak(),
            child: Obx(
              () => Icon(
                controller.isSpeak.value ? Icons.mic : Icons.mic_off,
                color: controller.isSpeak.value
                    ? Colors.lightGreenAccent
                    : Colors.white,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 摇杆组件 — 参考前端 CustomRocker 和全屏页面摇杆设计
  Widget _buildJoystick() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 摇杆外圈
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade600,
                width: 2,
              ),
            ),
            child: CustomPaint(
              painter: _JoystickCrossPainter(),
            ),
          ),
          // 四个方向按钮 — 带长按/点击双重支持
          _buildDirectionButton('up', 8, 160 / 2 - 22),
          _buildDirectionButton('left', 8, null),
          _buildDirectionButton('right', null, null),
          _buildDirectionButton('down', null, 160 - 38),
          // 中心拖动指示
          const Positioned(
            top: 160 / 2 - 18,
            left: 160 / 2 - 18,
            child: Icon(
              Icons.blur_on,
              size: 36,
              color: Color.fromARGB(112, 186, 183, 183),
            ),
          ),
        ],
      ),
    );
  }

  // 方向按钮 — 带旋转角度，匹配前端 CustomRocker 样式
  Widget _buildDirectionButton(String direction, double? top, double? left) {
    double angle;
    switch (direction) {
      case 'up':
        angle = 45;
        break;
      case 'left':
        angle = -45;
        break;
      case 'right':
        angle = 135;
        break;
      case 'down':
        angle = 225;
        break;
      default:
        angle = 0;
    }

    // 根据 direction 计算位置
    double? calcTop = top;
    double? calcLeft = left;
    double? calcRight;
    double? calcBottom;

    if (direction == 'up') {
      calcTop = 8;
      calcLeft = 160 / 2 - 22;
    } else if (direction == 'down') {
      calcBottom = 8;
      calcLeft = 160 / 2 - 22;
    } else if (direction == 'left') {
      calcTop = 160 / 2 - 22;
      calcLeft = 8;
    } else if (direction == 'right') {
      calcTop = 160 / 2 - 22;
      calcRight = 8;
    }

    return Positioned(
      top: calcTop,
      left: calcLeft,
      right: calcRight,
      bottom: calcBottom,
      child: _DirectionButton(
        angle: angle,
        direction: direction,
        onLongPressStart: () {
          controller.ptzMove(direction, mType: 0);
        },
        onLongPressEnd: () {
          controller.ptzStop(direction);
        },
        onTap: () {
          controller.ptzMove(direction);
        },
      ),
    );
  }
}

// 方向按钮组件 — 支持长按（连续转动）和点击（步进转动）
class _DirectionButton extends StatefulWidget {
  final double angle;
  final String direction;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final VoidCallback onTap;

  const _DirectionButton({
    required this.angle,
    required this.direction,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onTap,
  });

  @override
  State<_DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<_DirectionButton> {
  bool _isPressed = false;
  bool _isLongPress = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        setState(() {
          _isPressed = true;
          _isLongPress = true;
        });
        widget.onLongPressStart();
      },
      onLongPressEnd: (details) {
        setState(() {
          _isPressed = false;
          _isLongPress = false;
        });
        widget.onLongPressEnd();
      },
      onTapDown: (details) {
        setState(() => _isPressed = true);
        // 延迟检测是否为点击（非长按）
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isLongPress && mounted) {
            setState(() => _isPressed = false);
          }
        });
      },
      onTapUp: (details) {
        if (!_isLongPress) {
          widget.onTap();
        }
      },
      onTap: () {
        // 点击事件由 onTapUp 中的逻辑处理
      },
      child: Transform.rotate(
        angle: widget.angle * math.pi / 180,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isPressed
                ? const Color.fromARGB(159, 14, 14, 14)
                : const Color.fromARGB(99, 59, 57, 57),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(44),
              bottomLeft: Radius.circular(44),
              topLeft: Radius.circular(14),
              topRight: Radius.circular(44),
            ),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 1, 1, 1),
                Color.fromARGB(0, 248, 248, 249),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
        ),
      ),
    );
  }
}

// 摇杆十字线绘制
class _JoystickCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickCrossPainter oldDelegate) => false;
}
