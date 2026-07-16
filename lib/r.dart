import 'dart:convert';
import 'dart:typed_data';

class R {
  int? code;
  String? message;
  String? datas;
  R({this.code, this.message, this.datas});
  factory R.fromMap(Map<String, dynamic> data) => R(
      code: data['code'] as int?,
      message: data['message'] as String?,
      datas: _parseData(data['data']));

  /// 解析 data 字段，兼容 null、String、List<int>（byte 数组）、Map 等类型
  static String? _parseData(dynamic d) {
    if (d == null) return null;
    if (d is String) return d;
    if (d is List) {
      // Gson 序列化 byte[] 为 JSON 数组，转换为 base64 字符串
      try {
        return base64Encode(Uint8List.fromList(d.cast<int>()));
      } catch (_) {
        return d.toString();
      }
    }
    if (d is Map) return jsonEncode(d);
    return d.toString();
  }

  factory R.fromJson(String data) {
    return R.fromMap(json.decode(data) as Map<String, dynamic>);
  }
  Map<String, dynamic> toMap() => {
        'code': code,
        'message': message,
        'datas': datas,
      };

  String toJson() => json.encode(toMap());
}
