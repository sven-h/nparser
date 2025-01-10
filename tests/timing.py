import time
from nparser import parse, parse_new

start = time.perf_counter()
#with open('C:\\dev\\dbpedia\\2016_10\\skos_categories_en.ttl', 'rb') as file_handle:
    # with open(path, "rb") as file_handle:
#    for sub, pred, obj in parse(file_handle):
#        pass
parse_new('C:\\dev\\dbpedia\\2016_10\\skos_categories_en.ttl')
end = time.perf_counter()
print(end - start)