
import re
from nparser import parse, parse_two_old, parse_two, parse_two_a, parse_three, parse_two_without_function, parse_ten, parse_eleven, parse_two_with_inline

def one():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_two(f):
            pass

def two():
    with open('skos_categories_en.ttl', 'rb') as f:
        counter = 0
        for a,b, c  in parse_two(f):
            if a.value == 'http://dbpedia.org/resource/Category:Museums_established_in_1794':
                counter += 1
        print(counter)
    
def a():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse(f):
            pass

def b():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_two_without_function(f, chunk_size=8388609):
            pass

def c():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_two(f, chunk_size=8388609):
            pass

def d():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_two_a(f, chunk_size=8388609):
            pass

def e():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_three(f):
            pass



def f():
    object_pattern = re.compile(rb'<(.+)> <(.+)> <(.+)> \.\s*\n')
    literal_pattern = re.compile(rb'<(.+)> <(.+)> "(.+)"(?:\^\^.*|@en.*)? \.\s*\n')

    with open('skos_categories_en.ttl', mode='rb') as file_reader:
        for line in file_reader:
            object_triple = object_pattern.match(line)
            if object_triple:
                sub, pred, obj = object_triple.groups()
            else:
                literal_triple = literal_pattern.match(line)
                if literal_triple:
                    sub, pred, obj = literal_triple.groups()

def g():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_ten(f, chunk_size=8388609):
            pass

def h():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_eleven(f, chunk_size=8388609):
            pass


def j():
    with open('skos_categories_en.ttl', 'rb') as f:
        for a,b, c  in parse_two_with_inline(f, chunk_size=8388609):
            pass
#parse_two(open('tests/encoding/utf8.nt', 'rb'), chunk_size=80)
#parse_two(open('bla.txt', 'rb'), chunk_size=36)
#with open('skos_categories_en.ttl', 'rb') as f:
    #for a,b, c  in parse_three(f):
#    for a,b, c  in parse_two(f):
#        pass
        # print(a,b,c)

import time
start = time.perf_counter()
b()
print(time.perf_counter() - start)





#import timeit
#print("A")
#a()
#print("B")
#b()
#print("C")
#c()
#print("D")
#d()
#print("E")
#e()
#print("F")
#f()
#print("G")
#g()
#print("H")
#h()

#print("J")
#j()

#f()
#print("OK")


#print(timeit.timeit(a, number=10)) #21.756735499948263
#print(timeit.timeit(b, number=10)) #24.470946799963713
#print(timeit.timeit(c, number=10)) #28.878449199954048
#print(timeit.timeit(d, number=10)) #29.944789999863133
#print(timeit.timeit(e, number=10)) #31.98411380010657
#print(timeit.timeit(f, number=10)) # 116.92606279999018
#print(timeit.timeit(g, number=10)) # 
#print(timeit.timeit(h, number=10)) #
#print(timeit.timeit(j, number=10)) 










#for one, two, three in blub():
#    print(one, two, three)

#with open('./test.txt', 'r') as f:
#    f.readline()






def parse_new(file):
    if isinstance(file, str):
        if file.endswith('.bz2'):
            import bz2
            with bz2.open(file, 'rb') as f:
                print(f.readline())
        elif file.endswith('.tar.gz'):
            import tarfile
            with tarfile.open(file, 'r:gz') as tar:
                if len(tar.getmembers()) != 1:
                    raise ValueError('Tar file must contain exactly one file')
                
                with tar.extractfile(tar.getmembers()[0]) as f:
                    print(f.readline())        
        elif file.endswith('.gz'):
            import gzip
            with gzip.open(file, 'rb') as f:
                print(f.readline())
        elif file.endswith('.xz'):
            import lzma
            with lzma.open(file, 'rb') as f:
                print(f.readline())
        elif file.endswith('.tar'):
            import tarfile
            with tarfile.open(file, 'r') as tar:
                if len(tar.getmembers()) != 1:
                    raise ValueError('Tar file must contain exactly one file')
                
                with tar.extractfile(tar.getmembers()[0]) as f:
                    print(f.readline())
        elif file.endswith('.zip'):
            # read it, only if one file is in there
            from zipfile import ZipFile
            with ZipFile(file) as myzip:
                if len(myzip.namelist()) != 1:
                    raise ValueError('Zip file must contain exactly one file')
                with myzip.open(myzip.namelist()[0]) as f:
                    print(f.readline())
        
        else:
            with open(file, 'rb') as f:
                print(f.readline())


#parse_new('tests/compressed/compressed.nt.tar')