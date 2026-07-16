from translator.detectors.chinese_detector import ChineseDetector

def test_chinese_detector_finds_chinese():
    detector = ChineseDetector()
    text = "String text = \"检测成功\";"
    segments = detector.find_segments(text)
    
    assert len(segments) == 1
    assert segments[0].text == "检测成功"
    
def test_chinese_detector_ignores_english_and_code():
    detector = ChineseDetector()
    text = "public void test() { int a = 123; String camelCase = \"hello\"; }"
    segments = detector.find_segments(text)
    
    assert len(segments) == 0

def test_chinese_detector_finds_multiple():
    detector = ChineseDetector()
    text = "/* 初始化摄像头 */\nString msg = \"无法连接\";"
    segments = detector.find_segments(text)
    
    assert len(segments) == 2
    assert segments[0].text == "初始化摄像头"
    assert segments[1].text == "无法连接"
