import pytest
from nparser import parse
from rdflib import Graph
from rdflib.exceptions import ParserError
import glob

#def pytest_generate_tests(metafunc):
#    if "fixture1" in metafunc.fixturenames:
#        metafunc.parametrize("fixture1", ["one", "uno"])
#    if "fixture2" in metafunc.fixturenames:
#        metafunc.parametrize("fixture2", ["two", "duo"])
#        
#def test_foobar(fixture1, fixture2):
#    assert type(fixture1) == type(fixture2)

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
    
        #for sub, pred, obj in parse(file_handle):
        #    test_triples.add((sub.value, pred.value, obj.value))
    #assert len(triples) == len(test_triples)

#response = urlopen('file:///C:/dev/dbkwik_extraction/extraction_docker_ubuntu/newapproach/parser_lib/tests/w3c/nt-syntax-bad-uri-01.nt')
#test = response.read(50)
#print("Bla")



#def test_nlas(blub):
#    assert 6 == 5

#def test_positive_w3c(path):
#    print(path)
#    assert inc(3) == 5


#@pytest.mark.parametrize("path", negative_path, ids=negative_name)
#def test_negative_w3c(path):
#    with pytest.raises(ValueError):
#        with urlopen(path) as file_handle:
#        #with open(path, "rb") as file_handle:
#            for sub, pred, obj in parse(file_handle):
#                pass


#@pytest.mark.parametrize("path", positive_path, ids=positive_name)
#def test_positive_w3c(path):
#    triples = get_set_of_triple(path)
#    test_triples = set()
#    with urlopen(path) as file_handle:
#        for sub, pred, obj in parse(file_handle):
#            test_triples.add((sub.value, pred.value, obj.value))
#    assert triples == test_triples


#def test_one():
#    assert 1 == 1

#def test_two():
#    assert 1 == 2


#def test_answer():
#    with open('C:\\dev\\dbpedia\\test.nt', "rb") as file_handle:
#        for sub, pred, obj in parse(file_handle):
#            if pred.value == 'http://dbpedia.org/property/restingplace':
#                print(sub)
#    assert 5 == 6
