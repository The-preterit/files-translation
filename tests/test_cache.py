from translator.cache.memory_cache import MemoryCache

def test_memory_cache():
    cache = MemoryCache()
    
    assert cache.contains("hello") is False
    assert cache.get("hello") is None
    
    cache.set("hello", "bonjour")
    
    assert cache.contains("hello") is True
    assert cache.get("hello") == "bonjour"
    
    # Overwrite
    cache.set("hello", "salut")
    assert cache.get("hello") == "salut"
