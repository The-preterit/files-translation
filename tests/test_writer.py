import pytest
from pathlib import Path
from translator.config import Config
from translator.writer.file_writer import FileWriter
from translator.models.segment import Segment

@pytest.fixture
def dummy_file(tmp_path):
    file_path = tmp_path / "test.java"
    content = "String a = \"测试\";\n// 汉字"
    file_path.write_text(content, encoding="utf-8")
    return file_path

def test_writer_replace_and_write(dummy_file):
    config = Config(project_directory=Path("."))
    writer = FileWriter(config)
    
    original_content = writer.read(dummy_file)
    
    # Indices for "测试" (start: 12, end: 14) and "汉字" (start: 20, end: 22)
    segments = [
        Segment(text="测试", start=12, end=14),
        Segment(text="汉字", start=20, end=22)
    ]
    translations = ["Test", "Chinese"]
    
    modified = writer.replace_and_write(dummy_file, original_content, segments, translations)
    
    assert modified is True
    
    new_content = writer.read(dummy_file)
    expected_content = "String a = \"Test\";\n// Chinese"
    assert new_content == expected_content
    
def test_writer_no_modification_when_no_segments(dummy_file):
    config = Config(project_directory=Path("."))
    writer = FileWriter(config)
    
    original_content = writer.read(dummy_file)
    
    modified = writer.replace_and_write(dummy_file, original_content, [], [])
    
    assert modified is False
