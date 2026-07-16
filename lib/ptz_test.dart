import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';
import 'package:xml2json/xml2json.dart';

class PtzTest extends StatefulWidget {
  const PtzTest({super.key});

  @override
  State<PtzTest> createState() => _PtzTestState();
}

class _PtzTestState extends State<PtzTest> {
  final _monitorxPlugin = Monitorx();
  String customeResult = "无返回数据";
  late var _data;
  bool isLoginShow = true;
  bool isShow = false;

  late var deviceInfo;
  @override
  void initState() {
    super.initState();
    linkChannel();
  }

  Future<void> linkChannel() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      print("  接收到后台通道：${value.toString()}");
      customeResult = value.toString();
      _data = json.decode(customeResult);

      if (_data['code'] == 2100) {
        var transformer = Xml2Json();
        transformer.parse(_data["info"]);
        deviceInfo = jsonDecode(transformer.toParker());
      }
      if (_data['code'] <= 100) {
        EasyLoading.showToast("成功");
      }

      setState(() {
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
    'did': 'IOTFAA-745433-ZVELM'
  };
  Map<String, String> ptzArgs = <String, String>{'did': 'IOTDAA-731185-LJYSX'};

  @override
  Widget build(BuildContext context) {
    var videoView = [
      if (isShow)
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            color: const Color.fromARGB(255, 243, 241, 237),
            height: 510,
            child: AndroidView(
              viewType: 'mx-video',
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            )),
    ];
    var ptzBtn1 = [
      ElevatedButton(
          onPressed: () {
            ptzArgs["direction"] = "up";
            _monitorxPlugin.ptzNormal(ptzArgs);
          },
          child: const Text("上")),
      ElevatedButton(
          onPressed: () {
            ptzArgs["direction"] = "down";
            _monitorxPlugin.ptzNormal(ptzArgs);
          },
          child: const Text("下")),
      ElevatedButton(
          onPressed: () {
            ptzArgs["direction"] = "left";
            _monitorxPlugin.ptzNormal(ptzArgs);
          },
          child: const Text("左")),
      ElevatedButton(
          onPressed: () {
            ptzArgs["direction"] = "right";
            _monitorxPlugin.ptzNormal(ptzArgs);
          },
          child: const Text("右")),
    ];
    return Scaffold(
        appBar: AppBar(
          title: const Text('云台测试PTZ'),
        ),
        body: Center(
          child: Container(
            color: Colors.amber,
            child: ListView(children: <Widget>[
              Text('当前返回状态：$customeResult'),
              ...videoView,
              if (isShow) ...ptzBtn1,
              testFun()
            ]),
          ),
        ));
  }

// 测试功能  虚拟账号默认密码：Admin1887512357
  Widget testFun() {
    return Wrap(
      spacing: 2.0,
      runSpacing: 2,
      children: [
        // 基本功能列表
        if (isLoginShow)
          //  虚拟账号：13455173658 / Admin1887512357   正式账号：15210395983 / Fqjsm@2025
          ElevatedButton(
              onPressed: () {
                MonitorxPlatform.instance
                    .testLogin('13455173658', 'Admin1887512357'); //'Fqjsm@2025'
              },
              child: const Text("*0登录*")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice("IOTFAA-745433-ZVELM", 0);
            },
            child: const Text("*1连接ZVELM*")),
        ElevatedButton(
            onPressed: () async {
              await _monitorxPlugin.deviceDelete("IOTFAA-745433-ZVELM");
            },
            child: const Text("解绑删除ZVELM")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice("IOTDAA-731185-LJYSX", 0);
            },
            child: const Text("*1连接LJYSX*")),
        ElevatedButton(
            onPressed: () async {
              await _monitorxPlugin.deviceDelete("IOTDAA-731185-LJYSX");
            },
            child: const Text("解绑删除LJYSX")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice("IIOTGDD-184607-HYLLB", 2);
            },
            child: const Text("*1连接HYLLB*")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.deviceInfo("IOTGDD-184607-HYLLB");
            },
            child: const Text("获取设备信息N")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceSleepInfo("IOTFAA-745433-ZVELM");
            },
            child: const Text("获取设备睡眠信息")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.reboot("IOTDAA-731185-LJYSX");
            },
            child: const Text("重启")),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceList();
            },
            child: const Text("列表")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.disconnectDevice('IOTDAA-731185-LJYSX');
            },
            child: const Text("断开")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDevicePTZCap('IOTDAA-731185-LJYSX');
            },
            //  云台测试方法
            child: const Text("*2云台*")),
        // 设置预置点
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsSet('IOTDAA-731185-LJYSX', '1', '0');
            },
            child: const Text("设置预置点0")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsSet('IOTDAA-731185-LJYSX', '1', '1');
            },
            child: const Text("设置预置点1")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsSet('IOTDAA-731185-LJYSX', '1', '2');
            },
            child: const Text("设置预置点2")),
        // 清除预置
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsRemove('IOTDAA-731185-LJYSX', '1', '0');
            },
            child: const Text("清除预置0 ")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsRemove('IOTDAA-731185-LJYSX', '1', '1');
            },
            child: const Text("清除预置1 ")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsRemove('IOTDAA-731185-LJYSX', '1', '2');
            },
            child: const Text("清除预置2 ")),
        ElevatedButton(
            onPressed: () {
              List<String> presets = ['0', '1', ' 2'];
              _monitorxPlugin.ptzClearPresets(
                  'IOTDAA-731185-LJYSX', '1', presets);
            },
            child: const Text("清除所有")),

        //调到指定预置
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsGoto('IOTDAA-731185-LJYSX', '1', '0');
            },
            child: const Text("调到指定预置点 0 ")),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzPresetsGoto('IOTDAA-731185-LJYSX', '1', '1');
            },
            child: const Text("调到指定预置点 1 ")),
        // PTZ校准
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzCalibration('IOTDAA-731185-LJYSX', '1');
            },
            child: const Text("PTZ校准")),
        //获取PTZ状态
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getPTZStatus('IOTDAA-731185-LJYSX', '1');
            },
            child: const Text("获取PTZ状态")),
        //开始巡航
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '0');
            },
            child: const Text('s巡航(0)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '1');
            },
            child: const Text('s巡航(1)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '2');
            },
            child: const Text('s巡航(2)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '3');
            },
            child: const Text('s巡航(3)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '4');
            },
            child: const Text('s巡航(4)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '5');
            },
            child: const Text('s巡航(5)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '6');
            },
            child: const Text('s巡航(6)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '7');
            },
            child: const Text('s巡航(7)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '10');
            },
            child: const Text('s巡航(10)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.startCruise('IOTDAA-731185-LJYSX', '1', '15');
            },
            child: const Text('s巡航(15)')),
        //停止巡航
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.stopCruise('IOTDAA-731185-LJYSX', '1', '0');
            },
            child: const Text('停止巡航')),
        //获取PTZ自动巡航状态
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getCuriseStatus('IOTDAA-731185-LJYSX', '1');
            },
            child: const Text('获取PTZ自动巡航状态')),
        //设置PTZ自动巡航状态
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.setCuriseStatus('IOTDAA-731185-LJYSX', '1');
            },
            child: const Text('设置PTZ自动巡航状态')),
        //自动左右扫描
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzAutoLeftRight(
                  'IOTDAA-731185-LJYSX', '1', '1', '10');
            },
            child: const Text('开始自动左右扫描')),
        //自动左右扫描
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.ptzAutoLeftRight(
                  'IOTDAA-731185-LJYSX', '1', '2', '10');
            },
            child: const Text('关闭自动左右扫描')),

        //获取设备AI能力
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceAICap('IOTDAA-731185-LJYSX', 'IPC', '0');
            },
            child: const Text('获取设备AI能力(0)')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceAICap('IOTDAA-731185-LJYSX', 'IPC', '1');
            },
            child: const Text('获取设备AI能力(1)')),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.addDevice('IOTGDD-184607-HYLLB');
            },
            child: const Text('添加设备IOTGDD-184607-HYLLB')),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.connectDevice('IOTFAA-745433-ZVELM', 0);
            },
            child: const Text('连接设备IOTFAA-745433-ZVELM')),

        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.addDevice('IOTFAA-745433-ZVELM');
            },
            child: const Text('添加设备IOTFAA-745433-ZVELM')),
        ElevatedButton(
            onPressed: () {
              _monitorxPlugin.getDeviceOSD('IOTDAA-731185-LJYSX');
            },
            //  云台测试方法
            child: const Text("获取OSD信息")),

        // 抓图测试
        ElevatedButton(
            onPressed: () {
              generateRemoteImage();
            },
            child: const Text('抓图测试')),
        const Text(
          '注：第一步：登录 \n 第二步：列表，\n第三步：连接设备 \n 第四步：看情况，如果操作云台就先获取云台功能',
          style: TextStyle(fontSize: 8, color: Colors.red),
        ),
      ],
    );
  }

  // 生成远程抓图
  generateRemoteImage() async {
    // for (int i = 2; i > 1; i--) {
    _monitorxPlugin.getRemoteImageCaptureV2(
        'IOTDAA-731185-LJYSX', '2', 1, 'jpg');
    // }
  }
}
