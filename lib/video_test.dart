import 'package:flutter/material.dart';

class VideoTest extends StatefulWidget {
  const VideoTest({super.key});

  @override
  State<VideoTest> createState() => _VideoTestState();
}

class _VideoTestState extends State<VideoTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('视频测试'),
          ),
      body: Center(
        child: Container(
          color: Colors.green,
        ),
      ),
    );
  }
}
