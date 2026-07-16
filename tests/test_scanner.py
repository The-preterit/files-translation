import pytest
from pathlib import Path
from translator.config import Config
from translator.scanner.scanner import Scanner

@pytest.fixture
def dummy_project(tmp_path):
    project_dir = tmp_path / "project"
    project_dir.mkdir()
    
    # Files to include
    (project_dir / "Main.java").write_text("class Main {}")
    (project_dir / "utils").mkdir()
    (project_dir / "utils" / "helper.py").write_text("def help(): pass")
    
    # Ignored directories
    (project_dir / ".git").mkdir()
    (project_dir / ".git" / "config").write_text("git config")
    
    (project_dir / "build").mkdir()
    (project_dir / "build" / "output.class").write_text("binary")
    
    # Ignored files/extensions
    (project_dir / "image.png").write_text("image")
    
    return project_dir

def test_scanner(dummy_project):
    config = Config(project_directory=dummy_project)
    scanner = Scanner(config)
    
    files = scanner.scan()
    
    # Should only find Main.java and helper.py
    assert len(files) == 2
    names = [f.name for f in files]
    assert "Main.java" in names
    assert "helper.py" in names
    
    assert "config" not in names
    assert "output.class" not in names
    assert "image.png" not in names
