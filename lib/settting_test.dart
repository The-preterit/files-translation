import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:xml2json/xml2json.dart';

class SetttingTest extends StatefulWidget {
  const SetttingTest({super.key});

  @override
  State<SetttingTest> createState() => _SetttingTestState();
}

class _SetttingTestState extends State<SetttingTest> {
  final _monitorxPlugin = Monitorx();
  String customeResult = "无返回数据";
  bool isLoginShow = true;
  final myController = TextEditingController();
  @override
  void initState() {
    super.initState();
    linkChannel();
  }

  Future<void> linkChannel() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      print("  接收到后台通道：${value.toString()}");
      Map<String, dynamic> result = jsonDecode(value.toString());
      if (result["code"] < 100) {
        updateResult(result["message"]);
      } else if (result["code"] == 5100) {
        var data = result["data"];
        Xml2Json xml2json = Xml2Json();
        xml2json.parse(data["info"]);
        var json = jsonDecode(xml2json.toParker());
        print("转换后的JSON: $json");
      } else {
        Map<String, dynamic> result2 = result["data"];
        for (var key in result2.keys) {
          updateResult(key);
        }
      }

      // print("**...****.....****>>>接收到后台通道：***.....***...***>>> ");

      // setState(() {
      //   customeResult = value.toString();
      // });
    });
    // 客户端调动加载设备列表
    // await _monitorxPlugin.getDeviceList();
  }

  updateResult(String result) {
    setState(() {
      customeResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置测试'),
      ),
      body: ListView(
        children: <Widget>[
          Text("返回结果：$customeResult"),
          funList(),
        ],
      ),
    );
  }

  Future<String> _httpGet() async {
    final response = await http.get(
      Uri.parse('http://erp.p6sai.com:8090/UtilERP/device/GetCloudUpgradeHost'),
    );
    if (response.statusCode == 200) {
      print("请求成功: ${response.body}");
    } else {
      print("请求失败: ${response.statusCode}");
    }
    return response.body.toString();
  }

  Widget funList() {
    return Wrap(
      children: [
        ElevatedButton(
          onPressed: () async {
            // 调用设置功能
            MonitorxPlatform.instance.testLogin('15210395983', 'Fqjsm@2025');
          },
          child: const Text("*登录"),
        ),
        TextField(controller: myController),
        ElevatedButton(
            onPressed: () {
              //_monitorxPlugin.connectDevice("IOTDAA-731185-LJYSX");
              if (myController.text.isNotEmpty) {
                _monitorxPlugin.connectDevice(myController.text,0);
              } else {
                print("设备ID不能为空");
              }
            },
            child: const Text("*1连接添加设备*")),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              _monitorxPlugin.disconnectDevice(myController.text);
            } else {
              print("设备ID不能为空");
            }
          },
          child: const Text("*2断开设备连接*"),
        ),
        ElevatedButton(
          onPressed: () {
            _monitorxPlugin.getDeviceList();
          },
          child: const Text("*3获取设备列表*"),
        ),


        
        ElevatedButton(
          onPressed: () {
            _httpGet().then((value) {
              print("HTTP GET 请求结果: $value");
              Map<String, Object> arguments = {
                "did": myController.text,
                "url": "PUT /System/CloudUpgradeServerInfo",
                "body": value
              };

              _monitorxPlugin.switchSettings(arguments);
            }).catchError((error) {
              print("HTTP GET 请求错误: $error");
            });
          },
          child: const Text("固件升级"),
        ),
        ElevatedButton(
          onPressed: () {
            initBluetooth();
          },
          child: const Text("搜索蓝牙设备"),
        ),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              _monitorxPlugin.connectBle(myController.text);
            } else {
              print("设备地址不能为空");
            }
          },
          child: const Text("连接蓝牙设备"),
        ),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              _monitorxPlugin.configureNetwork(myController.text, "12345678");
            } else {
              print("WiFi SSID不能为空");
            }
          },
          child: const Text("配置蓝牙网络"),
        ),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              _monitorxPlugin.getPowerConfig(myController.text);
            } else {}
          },
          child: const Text("获取电源信息"),
        ),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              _monitorxPlugin.getAudioStream(myController.text);
            } else {}
          },
          child: const Text("获取所有音频流配置信息"),
        ),
        ElevatedButton(
          onPressed: () {
            if (myController.text.isNotEmpty) {
              Map<String, String> args = {
                'did': 'IOTGFF-148545-RKNKB',
                'AudioInMethod': 'microphone', // 不修改默认值
                'AudioInCodec': 'G.711U', // 不修改默认值
                'AudioInVolume': '80', // 不修改默认值
                'AudioOutVolume': '99', // 不修改默认值
                'EnableAlarmAudio': 'false', // 是否使用报警
                'EnableAlarmFlashLight': 'false', // 报警闪光灯
                'AlarmVolume': "66", // 报警音量
                'VoiceType': 'welcome', // 报警类型
                'AlarmDuration': '10' // 报警时长
              };
              _monitorxPlugin.setAudioStream(args);
            } else {}
          },
          child: const Text("设置所有音频流配置信息"),
        ),
      ],
    );
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
