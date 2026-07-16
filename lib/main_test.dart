import 'package:flutter/material.dart';
import 'package:monitorx_example/ext_test.dart';
import 'package:monitorx_example/push_subscrible_test.dart';
import 'package:monitorx_example/settting_test.dart';

import 'bluetooth_test.dart';
import 'ptz_test.dart';
import 'video_test.dart';

class MainTest extends StatefulWidget {
  const MainTest({super.key});

  @override
  State<MainTest> createState() => _MainTestState();
}

class _MainTestState extends State<MainTest> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHomePage());
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: ListView(
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              print(" ===> PTZ 测试");
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PtzTest()));
            },
            child: const Text("PTZ 测试"),
          ),
          ElevatedButton(
            onPressed: () {
              print(" ===> 视频 测试");
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const VideoTest()));
            },
            child: const Text("视频 测试"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ExtTest()));
            },
            child: const Text("扩展功能"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SetttingTest()));
            },
            child: const Text("设置测试"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BluetoothTest()));
            },
            child: const Text("蓝牙测试"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PushSubscribleTest()));
            },
            child: const Text("推送订阅测试"),
          ),
        ],
      ),
    );
  }
}
