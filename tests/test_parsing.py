import pytest
from nparser import parse, Resource, Literal, BNode
import io

def test_resource_only():
    ntriple = b'<one> <two> <three>.'
    parsed_list = list(parse(io.BytesIO(ntriple)))
    assert len(parsed_list) == 1
    sub, pred, obj = parsed_list[0]
    
    assert type(sub) == Resource
    assert type(pred) == Resource
    assert type(obj) == Resource
    
    assert sub.value == 'one'
    assert pred.value == 'two'
    assert obj.value == 'three'

def test_simple_literal():
    ntriple = b'<one> <two> "three".'
    parsed_list = list(parse(io.BytesIO(ntriple)))
    assert len(parsed_list) == 1
    sub, pred, obj = parsed_list[0]
    
    assert type(sub) == Resource
    assert type(pred) == Resource
    assert type(obj) == Literal
    
    assert sub.value == 'one'
    assert pred.value == 'two'
    assert obj.value == 'three'

@pytest.mark.parametrize("ntriple", [
    b'<one> <two> _:three.', 
    b'<one> <two> _:three   .'
])
def test_simple_blank_node(ntriple):
    parsed_list = list(parse(io.BytesIO(ntriple)))
    assert len(parsed_list) == 1
    sub, pred, obj = parsed_list[0]
    
    assert type(sub) == Resource
    assert type(pred) == Resource
    assert type(obj) == BNode
    
    assert sub.value == 'one'
    assert pred.value == 'two'
    assert obj.value == 'three'

@pytest.mark.parametrize("ntriple", [
    b'_:one <two> <three>.',
    b'_:one<two> <three>.'
])
def test_blank_node_beginning(ntriple):
    parsed_list = list(parse(io.BytesIO(ntriple)))
    assert len(parsed_list) == 1
    sub, pred, obj = parsed_list[0]
    
    assert type(sub) == BNode
    assert type(pred) == Resource
    assert type(obj) == Resource
    
    assert sub.value == 'one'
    assert pred.value == 'two'
    assert obj.value == 'three'


# negatives tests

@pytest.mark.parametrize("ntriple", [b'.', b'_', b'__'])
def test_empty_line(ntriple):
    with pytest.raises(ValueError):
        parsed_list = list(parse(io.BytesIO(ntriple)))

