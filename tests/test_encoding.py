import pytest
from nparser import parse, Resource, Literal, BNode
import glob

def pytest_generate_tests(metafunc):
    filelist = glob.glob('tests/encoding/*.nt')
    metafunc.parametrize("file_path", filelist )

def test_encoding(file_path):
        
    with open(file_path, 'rb') as file_handle:
        actual_triples = list(parse(file_handle))
    
    assert len(actual_triples) == 3
    
    #first triple
    sub, pred, obj = actual_triples[0]
    
    assert type(sub) == Resource
    assert type(pred) == Resource
    assert type(obj) == Literal
    
    assert sub.value == 'one'
    assert pred.value == 'two'
    assert obj.value == 'three'
    
    
    #second triple
    sub, pred, obj = actual_triples[1]
    
    assert type(sub) == Resource
    assert type(pred) == Resource
    assert type(obj) == BNode
    
    assert sub.value == 'four'
    assert pred.value == 'five'
    assert obj.value == 'six'
    
    #third triple
    sub, pred, obj = actual_triples[2]
    
    assert type(sub) == BNode
    assert type(pred) == Resource
    assert type(obj) == BNode
    
    assert sub.value == 'seven'
    assert pred.value == 'eight'
    assert obj.value == 'nine'

