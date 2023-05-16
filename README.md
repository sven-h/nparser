## NParser

This is a small parser written in cython to speed up parsing N-Tiple files.
The NParser is non-validating parser.
It will thus also parse non-conformant N-Triples (e.g. URI containing spaces and character escapes - more examples below).
All [positive W3C N-Triples test cases](https://w3c.github.io/rdf-tests/ntriples/) are passed.

It is similar to the [NxParser written in java](https://github.com/nxparser/nxparser).

## Usage

The parse function expects a [file-like object](https://docs.python.org/3/glossary.html#term-file-object) (which has at least a `read` function).
It returns a generator of tuples where the elements are parsed parts of the triple.

To parse a n-triple file a sample code could look like:

```
from nparser import parse
with open('labels.nt', 'rb') as f:
    for s, p, o in parse(f):
        print(s.value)
        print(type(s))
```

The following types and their functions are available:
- `Resource`
    - `.value` to access the IRI/URI as string e.g. `http://example.com/a`
    - `str(z)` to get the ntriple representation e.g. `<http://example.com/a>` including `<` and `>`
- `Literal`
    - `.value` to access the lexical representation as a string e.g. `2` given `"2"^^<http://www.w3.org/2001/XMLSchema#integer>`
    - `.extension` to access the extension as a string e.g. `<http://www.w3.org/2001/XMLSchema#integer>` given `"2"^^<http://www.w3.org/2001/XMLSchema#integer>`
    - `str(z)` to get the ntriple representation e.g. `"2"^^<http://www.w3.org/2001/XMLSchema#integer>`
- `BNode` ([Blank node](https://en.wikipedia.org/wiki/Blank_node))
    - `.value` to access the nodeID as a string e.g. `foo` given `_:foo`
    - `str(z)` to get the ntriple representation e.g. `_:foo`

Thus it is possible to always call `.value` and `str()` on a returned element.

If you want to count the triples where the object is a `Resource` you can do the following:

```
from nparser import parse, Resource
count = 0
with open('labels.nt', 'rb') as f:
    for s, p, o in parse(f):
        if type(o) == Resource:
            count += 1
```

In case of a small file, it is also possible to load everything into a list directly:

```
from nparser import parse
with open('labels.nt', 'rb') as f:
    list_of_triples = list(parse(f))
```


For compressed files, just provide the uncompressed file object:

```
from nparser import parse
import gzip

with gzip.open('compressed.nt.gz', 'rb') as f:
    for s, p, o in parse(f):
        print(s.value)
```

### Examples of non-conformant N-Triples
Those triples can be parsed by the library but are not conformant to the specification.

```
# Bad IRI : space.
<http://example/ space> <http://example/p> <http://example/o> .
```
```
# Bad IRI : character escapes not allowed.
<http://example/\n> <http://example/p> <http://example/o> .
```
```
# No relative IRIs in N-Triples
<http://example/s> <http://example/p> <o> .
```