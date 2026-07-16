import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';

import 'device_preview_page.dart';
import 'main_test.dart';
import 'r.dart';

class DeviceInfo {
  final String did;
  final String alias;
  final String? status;
  DeviceInfo({required this.did, required this.alias, this.status});

  DeviceInfo copyWith({String? alias, String? status}) => DeviceInfo(
        did: did,
        alias: alias ?? this.alias,
        status: status ?? this.status,
      );
}

class DeviceListController extends GetxController {
  final _monitorxPlugin = Monitorx();
  final devices = <DeviceInfo>[].obs;

  @override
  void onInit() {
    super.onInit();
    _listenEvents();
    _monitorxPlugin.getDeviceList();
  }

  @override
  void onClose() {
    // 缺少：取消 _listenEvents 订阅的代码
    super.onClose();
  }

  Future<void> _listenEvents() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      R r;
      print("收到事件----------: $value");
      if (value is Map) {
        r = R.fromMap(value as Map<String, dynamic>);
      } else {
        r = R.fromJson(value.toString());
      }
      if (r.code == 1000) {
        _parseDeviceList(r.datas);
      } else if (r.code == 1002) {
        EasyLoading.dismiss();
        EasyLoading.showSuccess('设备添加成功');
        _monitorxPlugin.getDeviceList();
      } else if (r.code == 1008) {
        print('--------------设备删除成功--------');
        EasyLoading.dismiss();
        EasyLoading.showSuccess('设备删除成功');
        _monitorxPlugin.getDeviceList();
      } else if (r.code == 2007 || r.code == 2005 || r.code == 2006) {
        _parseDeviceStatus(r.datas);
      }
    });
  }

  void _parseDeviceList(String? data) {
    if (data == null || data.isEmpty) return;
    try {
      final json = jsonDecode(data);
      if (json is Map && json['entries'] is List) {
        final entries = json['entries'] as List;
        devices.clear();
        for (var item in entries) {
          if (item is Map) {
            devices.add(DeviceInfo(
              did: item['did']?.toString() ?? '',
              alias: item['alias']?.toString() ?? '',
              status: item['status']?.toString(),
            ));
          }
        }
        // 加载完列表后，主动查询每台设备的在线状态
        for (final device in devices) {
          MonitorxPlatform.instance.checkServerStatus(device.did);
        }
      }
    } catch (e) {
      EasyLoading.showToast('解析设备列表失败: $e');
    }
  }

  void _parseDeviceStatus(String? data) {
    if (data == null || data.isEmpty) return;
    try {
      final json = jsonDecode(data);
      String? did;
      String? status;
      if (json is Map) {
        did = json['did']?.toString() ??
            json['deviceId']?.toString() ??
            json['id']?.toString();
        if (json['status'] != null) {
          status = json['status']?.toString();
        } else if (json['isOnline'] != null) {
          status = json['isOnline'] == true ? '1' : '2';
        } else if (json['online'] != null) {
          status = json['online'] == true ? '1' : '2';
        } else if (json['state'] != null) {
          status = json['state']?.toString();
        }
      }
      if (did != null) {
        final idx = devices.indexWhere((d) => d.did == did);
        if (idx != -1) {
          devices[idx] = devices[idx].copyWith(status: status);
          devices.refresh();
        }
      }
    } catch (e) {
      EasyLoading.showToast('解析设备状态失败: $e');
    }
  }

  Future<void> preview(String did, String alias) async {
    await Get.to(() => DevicePreviewPage(did: did, alias: alias));
    // 从预览页返回后，重新注册事件监听（预览页的 _listenEvents 会覆盖回调）
    _listenEvents();
    // 返回后刷新设备列表和状态
    _monitorxPlugin.getDeviceList();
  }

  Future<void> deleteDevice(String did, String alias) async {
    EasyLoading.show(status: '删除中...');
    await _monitorxPlugin.deviceDelete(did);
    // 解绑结果通过事件通道 code=1008 异步返回，由 _listenEvents 统一处理
  }

  void showAddDeviceDialog() {
    final controller = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('添加设备'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入设备ID (did)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final did = controller.text.trim();
              if (did.isEmpty) {
                EasyLoading.showError('请输入设备ID');
                return;
              }
              Get.back();
              _addDevice(did);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDevice(String did) async {
    EasyLoading.show(status: '添加中...');
    await _monitorxPlugin.addDevice(did);
  }

  @override
  void refresh() {
    _monitorxPlugin.getDeviceList();
  }
}

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final controller = Get.put(DeviceListController());

  Color _statusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    if (status == '1') return Colors.green;
    if (status == '-6' || status == '2') return Colors.red;
    return Colors.grey;
  }

  String _statusText(String? status) {
    if (status == null || status.isEmpty) return '未知';
    if (status == '1') return '在线';
    if (status == '-6') return '离线';
    if (status == '2') return '离线';
    if (status == '-3') return '超时';
    if (status == '0') return '已连接';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => controller.showAddDeviceDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Get.to(() => const MainTest()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                      '共 ${controller.devices.length} 台设备',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    )),
                ElevatedButton.icon(
                  onPressed: () => controller.refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('刷新'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() => controller.devices.isEmpty
                ? const Center(
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices, size: 48, color: Colors.grey),
                      SizedBox(width: 16),
                      Text('暂无设备',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 16),
                      Text('请点击右上角 "+" 添加设备',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ))
                : ListView.builder(
                    itemCount: controller.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.devices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.devices),
                              title: Text(device.alias.isNotEmpty
                                  ? device.alias
                                  : device.did),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(device.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _statusColor(device.status),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _statusText(device.status),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _statusColor(device.status)),
                                    ),
                                  ],
                                ),
                              ),
                              subtitle: Text(device.did),
                            ),
                            OverflowBar(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => controller.preview(
                                      device.did, device.alias),
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('预览'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => controller.deleteDevice(
                                      device.did, device.alias),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('删除设备'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )),
          ),
        ],
      ),
    );
  }
}
