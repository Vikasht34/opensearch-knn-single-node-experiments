import os
import sys
sys.path.append(os.path.abspath(os.getcwd()))

from .param_sources import register as custom_register
from .runners import register as register_runners


def register(registry):
    register_runners(registry)
    custom_register(registry)
