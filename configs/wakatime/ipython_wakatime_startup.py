"""WakaTime integration for IPython
Install at: ~/.ipython/profile_default/startup/wakatime_startup.py
Requires: pip install repl-python-wakatime ipython
Tracks Python REPL sessions on wakatime.com dashboard.
"""

from repl_python_wakatime.backends.wakatime import Wakatime
from repl_python_wakatime.frontends.ipython import Ipython

from IPython import get_ipython

ipython = get_ipython()

if ipython is not None:
    ipython.prompts_class = lambda *args, **kwargs: Ipython(
        Wakatime(),
        ipython.prompts_class(*args, **kwargs),
    )
