import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:monitorx/monitorx.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'r.dart';

class BluetoothTest extends StatefulWidget {
  const BluetoothTest({super.key});

  @override
  State<BluetoothTest> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<BluetoothTest> {
  final _monitorxPlugin = Monitorx();
  final wifiNameController = TextEditingController();
  final wifiPwdController = TextEditingController();
  String customeResult = "无返回数据";
  Map<String, dynamic> dataMap = {};
  bool isConnected = false; // 蓝牙连接状态

  @override
  void initState() {
    super.initState();
    linkChannel();
  }

  Future<void> linkChannel() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      print("  接收到后台通道：${value.toString()}");
      R r;
      if (value is Map) {
        //  jsonEncode(value);
        r = R.fromMap(value as Map<String, dynamic>);
      } else {
        r = R.fromJson(value.toString());
      }
      if (r.code == 5006) {
        EasyLoading.showError("未打开蓝牙，蓝牙操作失败");
        return;
      } else if (r.code == 5002) {
        setState(() async {
          isConnected = true;
          final info = NetworkInfo();
          final wname = await info.getWifiName(); // "FooNetwork"
          wifiNameController.text = wname!.replaceAll("\"", "");
        });
        //蓝牙连接成功
        return;
      } else if (r.code == 5003) {
        //蓝牙连接失败
        EasyLoading.showError("蓝牙连接失败");
        return;
      } else if (r.code == 5004) {
        Map<String, dynamic> result = jsonDecode(r.datas ?? "{}");
        if (result["status"] == 0) {
          //配置成功
          EasyLoading.showSuccess("WiFi配置成功,开启配置wifi密码");
          String base64pwd = base64Encode(utf8.encode(wifiPwdController.text));
          _monitorxPlugin.setBlueWifiPwd(base64pwd);
        }
        if (result["status"] == 1) {
          EasyLoading.showToast("wifi配置完成！，开始连接设备....");
        }
        // 发送密码
        return;
      } else if (r.code == 5020) {
        EasyLoading.dismiss();
        EasyLoading.showInfo("未扫描到芯睿士设备");
        return;
      }

      // for (var entry in dataMap.entries) {
      //   print('key: ${entry.key}, value: ${entry.value}');
      // }

      setState(() {
        customeResult = r.datas ?? "无返回数据";
        dataMap = jsonDecode(r.datas ?? "{}");
      });
    });
    // 客户端调动加载设备列表
    // await _monitorxPlugin.getDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('蓝牙测试'),
        ),
        body: Center(
          child: ListView(
            children: [
              ElevatedButton(
                onPressed: () {
                  EasyLoading.show(status: "正在搜索蓝牙设备...");
                  initBluetooth();
                },
                child: const Text("搜索蓝牙设备"),
              ),
              if (isConnected)
                TextField(
                    controller: wifiNameController,
                    decoration: const InputDecoration(hintText: "WiFi名称")),
              if (isConnected)
                TextField(
                    controller: wifiPwdController,
                    decoration: const InputDecoration(hintText: "WiFi密码")),
              if (isConnected)
                ElevatedButton(
                  onPressed: () {
                    if (wifiNameController.text.isNotEmpty &&
                        wifiPwdController.text.isNotEmpty) {
                      String base64ssid =
                          base64Encode(utf8.encode(wifiNameController.text));
                      _monitorxPlugin.setBlueWifiSsid(base64ssid);
                      // _monitorxPlugin.configureNetwork(base64ssid, base64pwd);
                    } else {
                      print("WiFi SSID不能为空");
                    }
                  },
                  child: const Text(
                    "配置蓝牙网络",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dataMap.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
                itemBuilder: (BuildContext context, int index) {
                  var key = dataMap.keys.elementAt(index); // 蓝牙地址
                  var value = dataMap[key]; // 蓝牙名称
                  return ListTile(
                    title: Text(key),
                    subtitle: Text(value),
                    trailing: IconButton(
                        onPressed: () {
                          _monitorxPlugin.connectBle(key);
                        },
                        icon: const Text("连接",
                            style: TextStyle(color: Colors.blue))),
                  );
                },
              ),
            ],
          ),
        ));
  }

// 在需要使用蓝牙的地方调用此函数
  void initBluetooth() async {
    final hasPermissions = await requestBluetoothPermissions();
    if (hasPermissions) {
      // 权限已获取，可以开始蓝牙操作
      _monitorxPlugin.getBTDeviceList();
    } else {
      // 权限被拒绝，处理这种情况
      print("蓝牙权限未获取");
    }
  }

  Future<bool> requestBluetoothPermissions() async {
    // 检查并请求蓝牙扫描权限（适用于 Android 12+）
    if (await Permission.bluetoothScan.isDenied) {
      final status = await Permission.bluetoothScan.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // 检查并请求蓝牙连接权限（适用于 Android 12+）
    if (await Permission.bluetoothConnect.isDenied) {
      final status = await Permission.bluetoothConnect.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // 检查并请求定位权限（适用于 Android 6-11）
    if (await Permission.location.isDenied) {
      final status = await Permission.location.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // 所有必要权限均已获取
    return true;
  }
}

