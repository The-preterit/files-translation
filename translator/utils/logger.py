import logging
import sys

def setup_logger() -> logging.Logger:
    """
    Sets up and returns a standard Python logger.
    """
    logger = logging.getLogger("translator")
    logger.setLevel(logging.INFO)
    
    # Avoid adding handlers multiple times if setup_logger is called again
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter('%(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
    return logger

logger = setup_logger()
