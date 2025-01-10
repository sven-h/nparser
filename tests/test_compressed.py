import pytest
from nparser import parse

def test_compressed_gz():
    import gzip
    with gzip.open('tests/compressed/compressed.nt.gz', 'rb') as f:
        parsed_list = list(parse(f))
        assert len(parsed_list) == 1000

def test_compressed_bz2():
    import bz2
    with bz2.open("tests/compressed/compressed.nt.bz2", "rb") as f:
        parsed_list = list(parse(f))
        assert len(parsed_list) == 1000

def test_compressed_lzma():
    import lzma
    with lzma.open("tests/compressed/compressed.nt.xz") as f:
        parsed_list = list(parse(f))
        assert len(parsed_list) == 1000

def test_compressed_zip():
    from zipfile import ZipFile
    with ZipFile('tests/compressed/compressed.zip') as myzip:
        with myzip.open('compressed.nt') as f:
            parsed_list = list(parse(f))
            assert len(parsed_list) == 1000

