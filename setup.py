from setuptools import Extension, setup

# Allow installing package without Cython
try:
    import Cython.Build
except ImportError:
    Cython = None

ext = '.pyx' if Cython else '.c'
extensions = [Extension("nparser._nparser", ["src/nparser/_nparser"+ext])]

setup(
    ext_modules = Cython.Build.cythonize(extensions) if Cython else extensions # , compiler_directives={'language_level' : "3"}
)