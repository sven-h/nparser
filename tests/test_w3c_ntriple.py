import pytest
from nparser import parse
from rdflib import Graph
from rdflib.exceptions import ParserError
import glob

def get_parsed_triples(file_name):
    g = Graph()
    g.parse(file_name, format='nt')
    return list(g)

def pytest_generate_tests(metafunc):
    filelist = glob.glob('tests/w3c/*.nt')
    metafunc.parametrize("file_path", filelist )

def test_positive_w3c(file_path):
    try:
        expected_triples = get_parsed_triples(file_path)
    except ParserError:
        return
        
    with open(file_path, 'rb') as file_handle:
        actual_triples = list(parse(file_handle))
    
    assert len(actual_triples) == len(expected_triples)

