import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';

import 'r.dart';

class PushSubscribleTest extends StatefulWidget {
  const PushSubscribleTest({super.key});

  @override
  State<PushSubscribleTest> createState() => _PushSubscribleTestState();
}

class _PushSubscribleTestState extends State<PushSubscribleTest> {
  final _monitorxPlugin = Monitorx();
  String data = "无推送数据";
  bool loginState = false; // 登录状态 true 已登录， false 未登录
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
      if (r.code == 4) {
        // 登录成功
        setState(() {
          loginState = true;
        });
        EasyLoading.showSuccess("登录成功");
        return;
      }

      if (r.code! < 100) {
        EasyLoading.showInfo(r.message ?? "收到推送消息");
        setState(() {
          data = r.message ?? "无推送数据";
        });
        return;
      }
      setState(() {
        data = r.datas ?? "无推送数据";
      });
    });
    // 客户端调动加载设备列表
    // await _monitorxPlugin.getDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推送订阅测试'),
      ),
      body: Center(
        child: ListView(
          children: [
            Text("订阅：$data"),
            if (!loginState)
              //  虚拟账号：13455173658 / Admin1887512357   正式账号：15210395983 / Fqjsm@2025
              ElevatedButton(
                  onPressed: () {
                    MonitorxPlatform.instance
                        .testLogin('15210395983', 'Fqjsm@2025'); //'Fqjsm@2025'
                  },
                  child: const Text("1*0登录*")),
            ElevatedButton(
                onPressed: () {
                  _monitorxPlugin.getDeviceList();
                },
                child: const Text("2*列表*")),
            ElevatedButton(
                onPressed: () {
                  _monitorxPlugin.connectDevice("IOTFAA-745433-ZVELM", 0);
                },
                child: const Text("3*1连接ZVELM*")),
            ElevatedButton(
                onPressed: () {
                  _monitorxPlugin
                      .deviceSubscribePushMessage("IOTFAA-745433-ZVELM");
                },
                child: const Text("ZVELM订阅推送")),
            ElevatedButton(
                onPressed: () {
                  _monitorxPlugin.stopMsgReceive();
                },
                child: const Text("关闭DPS消息推送")),
            ElevatedButton(
                onPressed: () async {
                  bool status = await _monitorxPlugin.getMsgReceiveStatus();
                  EasyLoading.showInfo("DPS推送状态：${status ? "已开启" : "已关闭"}");
                },
                child: const Text("查看DPS推送状态")),
          ],
        ),
      ),
    );
  }
}
