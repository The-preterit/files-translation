import pytest
from pathlib import Path
from translator.config import Config
from translator.core.engine import TranslationEngine

@pytest.fixture
def dummy_integration_project(tmp_path):
    project_dir = tmp_path / "dummy_project"
    project_dir.mkdir()
    
    content = """
package com.example;

public class Main {
    public static void main(String[] args) {
        String msg = "检测成功";
        System.out.println(msg);
    }
}
"""
    (project_dir / "Main.java").write_text(content, encoding="utf-8")
    return project_dir

def test_engine_integration(dummy_integration_project):
    config = Config(
        project_directory=dummy_integration_project,
        translator="dummy",
        source_language="ZH",
        target_language="EN",
        batch_size=10,
        backup_enabled=False
    )
    
    engine = TranslationEngine(config)
    engine.run()
    
    assert engine.stats["files_scanned"] == 1
    assert engine.stats["files_modified"] == 1
    assert engine.stats["segments_translated"] == 1
    
    # Check modification
    new_content = (dummy_integration_project / "Main.java").read_text(encoding="utf-8")
    assert "检测成功" not in new_content
    assert "[TRANSLATED_EN] 检测成功" in new_content
