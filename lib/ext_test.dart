import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';

// 扩展功能测试
class ExtTest extends StatefulWidget {
  const ExtTest({super.key});

  @override
  State<ExtTest> createState() => _ExtTestState();
}

class _ExtTestState extends State<ExtTest> {
  final _monitorxPlugin = Monitorx();
  String customeResult = "无返回数据";
  var _data;
  bool isLoginShow = true;
  bool isShow = false;
  @override
  void initState() {
    super.initState();
    linkChannel();
  }

  Future<void> linkChannel() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      print("  接收到后台通道：${value.toString()}");

      setState(() {
        customeResult = value.toString();
        _data = json.decode(customeResult);
        if (_data['code'] == 4) {
          isLoginShow = !isLoginShow;
        } else if (_data['code'] == 2001) {
          isShow = !isShow;
        }
      });
    });
    // 客户端调动加载设备列表
    // await _monitorxPlugin.getDeviceList();
  }

  final Map<String, dynamic> creationParams = <String, dynamic>{
    'did': 'IOTGFF-148545-RKNKB'
  };
  Map<String, String> ptzArgs = <String, String>{'did': 'IOTGFF-148545-RKNKB'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('扩展功能测试'),
        ),
        body: Center(
          child: Container(
            color: Colors.amber,
            child: ListView(children: <Widget>[testFun()]),
          ),
        ));
  }

// 测试功能
  Widget testFun() {
    return Wrap(
      spacing: 2.0,
      runSpacing: 2,
      children: [
        SizedBox(
          width: double.infinity,
          height: 100,
          child: Text(customeResult),
        ),

        // 基本功能列表
        if (isLoginShow)
          ElevatedButton(
              onPressed: () {
                MonitorxPlatform.instance.testLogin('15210395983', '123456');
              },
              child: const Text("*0登录*")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice("IOTGDD-184607-HYLLB", 2);
            },
            child: const Text("*1连接*")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.reboot("IOTGFF-148545-RKNKB");
            },
            child: const Text("重启")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getServerPath();
            },
            child: const Text("获取唤醒服务器地址")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceList();
            },
            child: const Text("列表")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.disconnectDevice('IOTGFF-148545-RKNKB');
            },
            child: const Text("断开")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDevicePTZCap('IOTGFF-148545-RKNKB');
            },
            //  云台测试方法
            child: const Text("*2云台*")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceSIMCardInfo('IOTGFF-148545-RKNKB');
            },
            //  云台测试方法
            child: const Text("获取SIM信息")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceMultiOSD('IOTGFF-148545-RKNKB');
            },
            //  云台测试方法
            child: const Text("获取多行OSD信息")),

        ElevatedButton(
            onPressed: () {
              Map<String, Object> displayTime = {
                'Enable': true, // 不修改默认值
                'PosX': 1, // 不修改默认值
                'PosY': 20, // 不修改默认值
              };
              Map<String, Object> displayName = {
                'Enable': true,
                'PosX': 600,
                'PosY': 575,
                'Name': '测试'
              };
              Map<String, Object> displayBadAir = {
                'Enable': true,
                'PosX': 21,
                'PosY': 40,
              };

              Map<String, Object> displayBatteryInfo = {
                'Enable': true,
                'PosX': 41,
                'PosY': 60,
              };
              Map<String, Object> signalStrengthInfo = {
                'Enable': true,
                'PosX': 61,
                'PosY': 80,
              };
              Map<String, Object> osd = {
                'channel': '1',
                'DisplayTime': displayTime,
                'DisplayName': displayName,
                'DisplayBadAir': displayBadAir,
                'DisplayBatteryInfo': displayBatteryInfo,
                'SignalStrengthInfo': signalStrengthInfo
              };

              _monitorxPlugin.setDeviceOSD('IOTGFF-148545-RKNKB', osd);
            },
            //  云台测试方法
            child: const Text("设置单行OSD信息")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceOSD('IOTGFF-148545-RKNKB');
            },
            //  云台测试方法
            child: const Text("获取指定通道OSD配置")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getAudioAlarmConfigV1('IOTGFF-148545-RKNKB', '1');
            },
            //  云台测试方法
            child: const Text("获取音频报警配置")),

        // ------------------获取哭声叫声侦测配置---------------------------------------------
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice('IOTFAA-741510-SFKTF', 0);
            },
            //  云台测试方法
            child: const Text("连接-SFKTF")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getCryDetectConfig('IOTFAA-741510-SFKTF');
            },
            //  云台测试方法
            child: const Text("获取哭声配置-SFKTF")),

        // ------------------检测设置--------------------------------------------
        // 获取PIR检测配置： GET /Pictures/1/PIRDetect
        ElevatedButton(
            onPressed: () {
              excutMethod('IOTGDD-184607-HYLLB', 'GET /Pictures/1/PIRDetect');
            },
            //  云台测试方法
            child: const Text("PIR检测")),
        // 获取人物探测相关信息V1 ：GET /Pictures/1/PeopleDetectV1
        ElevatedButton(
            onPressed: () {
              excutMethod(
                  'IOTGDD-184607-HYLLB', 'GET /Pictures/1/PeopleDetectV1');
            },
            //  云台测试方法
            child: const Text("人物探测")),
        // 获取车形探测配置：GET /Pictures/1/CarDetect
        ElevatedButton(
            onPressed: () {
              excutMethod('IOTGDD-184607-HYLLB', 'GET /Pictures/1/CarDetect');
            },
            //  云台测试方法
            child: const Text("车形探测")),
        // ------------------获取指示灯信息--------------------------------------------
        ElevatedButton(
            onPressed: () {
              excutMethod('IOTGDD-184607-HYLLB', 'GET /Images/1/IrCutFilter');
            },
            //  云台测试方法
            child: const Text("指示灯信息")),

        // ------------------添加三目--------------------------------------------
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.addDevice(
                  "IOTGDD-246034-JBZHH"); //connectDevice("IOTGDD-246034-JBZHH", 2);
            },
            child: const Text("i")),
      ],
    );
  }

  // 设置设备参数
  excutMethod(did, url) {
    Map<String, Object> arguments = {"did": did, "url": url};
    _monitorxPlugin.switchSettings(arguments);
  }
}
