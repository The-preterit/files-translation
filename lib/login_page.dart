import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:monitorx/monitorx.dart';
import 'package:monitorx/monitorx_platform_interface.dart';

import 'device_list_page.dart';
import 'r.dart';

class LoginController extends GetxController {
  final _monitorxPlugin = Monitorx();
  final userName = ''.obs;
  final pwd = ''.obs;
  final pwdVisible = false.obs;

  // 注册相关状态
  final showRegister = false.obs;
  final isPhoneRegister = true.obs; // true=手机号, false=邮箱
  final registerAccount = ''.obs; // 手机号或邮箱
  final registerPwd = ''.obs;
  final registerConfirmPwd = ''.obs;

  // 图形验证码（仅手机号）
  final uuid = ''.obs;
  final imageCodeData = ''.obs; // base64 图片数据
  final imageCode = ''.obs;

  // 短信/邮箱验证码
  final verifyCode = ''.obs;

  // 倒计时
  final countdown = 0.obs;
  Timer? _countdownTimer;

  // 发送状态
  final isSendingCode = false.obs;

  void _startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
        isSendingCode.value = false;
      }
    });
  }

  void _resetRegisterState() {
    uuid.value = '';
    imageCodeData.value = '';
    imageCode.value = '';
    verifyCode.value = '';
    countdown.value = 0;
    isSendingCode.value = false;
    _countdownTimer?.cancel();
  }

  void switchRegisterType(bool phone) {
    isPhoneRegister.value = phone;
    _resetRegisterState();
  }

  Future<void> login() async {
    if (userName.value.isEmpty) {
      EasyLoading.showError('请输入账号');
      return;
    }
    if (pwd.value.isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }
    EasyLoading.show(status: '登录中...');
    await MonitorxPlatform.instance.testLogin(userName.value, pwd.value);
  }

  /// 获取图形验证码（手机号注册第一步）
  Future<void> getImageCodeForSms() async {
    if (registerAccount.value.isEmpty) {
      EasyLoading.showError('请输入手机号');
      return;
    }
    isSendingCode.value = true;
    uuid.value = DateTime.now().millisecondsSinceEpoch.toString();
    await MonitorxPlatform.instance.getImageCode(uuid.value);
  }

  /// 发送短信验证码（手机号注册第二步）
  Future<void> sendSmsCode() async {
    if (imageCode.value.isEmpty) {
      EasyLoading.showError('请输入图形验证码');
      return;
    }
    isSendingCode.value = true;
    await MonitorxPlatform.instance.sendSms(
      uuid.value,
      registerAccount.value,
      imageCode.value,
      1, // 1=注册
    );
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode() async {
    if (registerAccount.value.isEmpty) {
      EasyLoading.showError('请输入邮箱');
      return;
    }
    if (!registerAccount.value.contains('@')) {
      EasyLoading.showError('请输入正确的邮箱地址');
      return;
    }
    isSendingCode.value = true;
    await MonitorxPlatform.instance.sendEmailCode(registerAccount.value, 1);
  }

  /// 注册
  Future<void> register() async {
    if (registerAccount.value.isEmpty) {
      EasyLoading.showError(isPhoneRegister.value ? '请输入手机号' : '请输入邮箱');
      return;
    }
    if (verifyCode.value.isEmpty) {
      EasyLoading.showError('请输入验证码');
      return;
    }
    if (registerPwd.value.isEmpty) {
      EasyLoading.showError('请输入密码');
      return;
    }
    if (registerConfirmPwd.value.isEmpty) {
      EasyLoading.showError('请再次输入密码');
      return;
    }
    if (registerPwd.value != registerConfirmPwd.value) {
      EasyLoading.showError('两次密码输入不一致');
      return;
    }

    EasyLoading.show(status: '注册中...');
    if (isPhoneRegister.value) {
      await MonitorxPlatform.instance
          .registerByPhone(registerAccount.value, verifyCode.value, registerPwd.value);
    } else {
      await MonitorxPlatform.instance
          .registerByEmail(registerAccount.value, verifyCode.value, registerPwd.value);
    }
  }

  Future<void> initListener() async {
    await _monitorxPlugin.monitorxGeneral((value) {
      R r;
      if (value is Map) {
        r = R.fromMap(value as Map<String, dynamic>);
      } else {
        r = R.fromJson(value.toString());
      }

      switch (r.code) {
        case 4: // 登录成功
          EasyLoading.showSuccess('登录成功');
          Get.offAll(() => const DeviceListPage());
          break;
        case 1021: // 图形验证码获取成功
          isSendingCode.value = false;
          if (r.datas != null && r.datas!.isNotEmpty) {
            imageCodeData.value = r.datas!;
          }
          break;
        case 1022: // 图形验证码获取失败
          isSendingCode.value = false;
          EasyLoading.showError(r.message ?? '获取图形验证码失败');
          break;
        case 1023: // 短信发送成功
          _startCountdown();
          EasyLoading.showSuccess('短信验证码已发送');
          break;
        case 1024: // 短信发送失败
          isSendingCode.value = false;
          EasyLoading.showError(r.message ?? '短信验证码发送失败');
          break;
        case 1025: // 邮箱验证码发送成功
          _startCountdown();
          EasyLoading.showSuccess('邮箱验证码已发送');
          break;
        case 1026: // 邮箱验证码发送失败
          isSendingCode.value = false;
          EasyLoading.showError(r.message ?? '邮箱验证码发送失败');
          break;
        case 1027: // 注册成功
          EasyLoading.showSuccess('注册成功');
          showRegister.value = false;
          userName.value = registerAccount.value;
          _resetRegisterState();
          break;
        case 1028: // 注册失败
          EasyLoading.showError(r.message ?? '注册失败');
          break;
        default:
          if (r.code != null && r.code! < 100 && r.code != 4) {
            EasyLoading.showError(r.message ?? '登录失败');
          }
          break;
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    initListener();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controller = Get.put(LoginController());
  final _userNameCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _registerAccountCtrl = TextEditingController();
  final _registerPwdCtrl = TextEditingController();
  final _registerConfirmPwdCtrl = TextEditingController();
  final _imageCodeCtrl = TextEditingController();
  final _verifyCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ever(controller.userName, (v) {
      if (_userNameCtrl.text != v) {
        _userNameCtrl.text = v;
      }
    });
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _pwdCtrl.dispose();
    _registerAccountCtrl.dispose();
    _registerPwdCtrl.dispose();
    _registerConfirmPwdCtrl.dispose();
    _imageCodeCtrl.dispose();
    _verifyCodeCtrl.dispose();
    super.dispose();
  }

  /// 构建图形验证码图片
  Widget _buildImageCodeWidget() {
    return Obx(() {
      if (controller.imageCodeData.value.isEmpty) {
        return const SizedBox.shrink();
      }
      try {
        var imageData = controller.imageCodeData.value;
        // Android 返回的是 data URL 格式: data:image/png;base64,xxxx
        // 需要去掉前缀才能 base64 解码
        if (imageData.contains('base64,')) {
          imageData = imageData.split('base64,').last;
        }
        final bytes = base64Decode(imageData);
        return GestureDetector(
          onTap: () => controller.getImageCodeForSms(),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 100,
            height: 40,
            fit: BoxFit.fill,
          ),
        );
      } catch (e) {
        debugPrint('图形验证码解码失败: $e, data=${controller.imageCodeData.value}');
        return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Flutter 插件 监控',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // 登录区域
              TextField(
                controller: _userNameCtrl,
                decoration: const InputDecoration(
                  labelText: '账号',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (v) => controller.userName.value = v,
              ),
              const SizedBox(height: 20),
              Obx(() => TextField(
                    controller: _pwdCtrl,
                    obscureText: !controller.pwdVisible.value,
                    decoration: InputDecoration(
                      labelText: '密码',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(controller.pwdVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            controller.pwdVisible.value = !controller.pwdVisible.value,
                      ),
                    ),
                    onChanged: (v) => controller.pwd.value = v,
                  )),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => controller.login(),
                  child: const Text('登录', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  final show = !controller.showRegister.value;
                  controller.showRegister.value = show;
                  if (show) {
                    controller._resetRegisterState();
                  }
                },
                child: Obx(() => Text(
                      controller.showRegister.value ? '收起注册' : '没有账号？点击注册',
                      style: const TextStyle(fontSize: 14),
                    )),
              ),
              // 注册区域
              Obx(() => controller.showRegister.value
                  ? _buildRegisterForm()
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Divider(),
        // 注册类型切换
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildTypeTab(
                    '手机号注册',
                    controller.isPhoneRegister.value,
                    () => controller.switchRegisterType(true),
                  )),
            ),
            Expanded(
              child: Obx(() => _buildTypeTab(
                    '邮箱注册',
                    !controller.isPhoneRegister.value,
                    () => controller.switchRegisterType(false),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 手机号/邮箱输入
        TextField(
          controller: _registerAccountCtrl,
          keyboardType: controller.isPhoneRegister.value
              ? TextInputType.phone
              : TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: controller.isPhoneRegister.value ? '手机号' : '邮箱',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(controller.isPhoneRegister.value
                ? Icons.phone_android
                : Icons.email),
          ),
          onChanged: (v) => controller.registerAccount.value = v,
        ),
        const SizedBox(height: 16),
        // 手机号：图形验证码
        Obx(() => controller.isPhoneRegister.value
            ? _buildImageCodeSection()
            : const SizedBox.shrink()),
        // 短信/邮箱验证码
        _buildVerifyCodeSection(),
        const SizedBox(height: 16),
        // 密码
        TextField(
          controller: _registerPwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '注册密码',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onChanged: (v) => controller.registerPwd.value = v,
        ),
        const SizedBox(height: 16),
        // 确认密码
        TextField(
          controller: _registerConfirmPwdCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '确认密码',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onChanged: (v) => controller.registerConfirmPwd.value = v,
        ),
        const SizedBox(height: 20),
        // 注册按钮
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => controller.register(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('注册', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTypeTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.blue : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 图形验证码区域（仅手机号）
  Widget _buildImageCodeSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _imageCodeCtrl,
                decoration: const InputDecoration(
                  labelText: '图形验证码',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => controller.imageCode.value = v,
              ),
            ),
            const SizedBox(width: 8),
            _buildImageCodeWidget(),
            const SizedBox(width: 8),
            Obx(() => SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: controller.isSendingCode.value
                        ? null
                        : () => controller.getImageCodeForSms(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('获取', style: TextStyle(fontSize: 12)),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 短信/邮箱验证码区域
  Widget _buildVerifyCodeSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _verifyCodeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => controller.verifyCode.value = v,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final counting = controller.countdown.value > 0;
              final sending = controller.isSendingCode.value;
              final disabled = counting || sending;
              String btnText;
              if (counting) {
                btnText = '${controller.countdown.value}s';
              } else {
                btnText = '获取验证码';
              }
              return SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: disabled
                      ? null
                      : () {
                          if (controller.isPhoneRegister.value) {
                            controller.sendSmsCode();
                          } else {
                            controller.sendEmailCode();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(btnText, style: const TextStyle(fontSize: 12)),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}