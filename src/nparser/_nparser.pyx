cimport cython
from libc.string cimport memchr, memcpy

cdef class Resource:
    cdef public str value
    def __init__(self, c):
        self.value = c

    def __repr__(self):
        return "<" + self.value + ">"
    def __str__(self):
        return "<" + self.value + ">"

cdef class BNode:
    cdef public str value
    def __init__(self, c):
        self.value = c

    def __repr__(self):
        return ":_" + self.value
    def __str__(self):
        return ":_" + self.value

cdef class Literal:
    cdef public str value
    cdef public str extension

    def __init__(self, lex, ext):
        self.value = lex
        self.extension = ext

    def __repr__(self):
        return '"' + self.value + '"' + self.extension
    def __str__(self):
        return '"' + self.value + '"' + self.extension



def parse(file_like):
    if not hasattr(file_like, "read"):
        raise ValueError("no read function available")
    cdef char buf[8388609]
    buf_py = file_like.read(8388609)#file_like.read(16384) # 2^23 + 1   ~ 8MB
    cdef int bytes_read = len(buf_py)
    memcpy(buf,<char*>buf_py, bytes_read)

    cdef int line_count = 0
    cdef char* linestart = buf
    cdef char* lineend = NULL
    cdef char* current = NULL
    cdef char* startNode = NULL
    cdef int last_line = 0
    cdef int copy_amount = 0
    cdef str literal_lexical

    while not last_line:
        my_list = []
        lineend = <char*>memchr(<void*>linestart, '\n', (buf + bytes_read) - linestart)
        if lineend == NULL:
            copy_amount = (buf + bytes_read) - linestart
            memcpy(buf, linestart, copy_amount)
            buf_py = file_like.read(8388609 - copy_amount)
            if not buf_py:
                last_line = 1
                lineend = buf + copy_amount
            else:
                bytes_read = len(buf_py)
                memcpy(buf + copy_amount,<char*>buf_py, bytes_read)
                bytes_read += copy_amount
                linestart = buf

                lineend = <char*>memchr(<void*>linestart, '\n', (buf + bytes_read) - linestart)
                if lineend == NULL:
                    last_line = 1
                    lineend = buf + bytes_read

        line_count += 1
        current = linestart
        while True:
            if current[0] == '\n' or current >= lineend: # or current[0] == '\n' or current >= lineend)and len(my_list) == 0: # empty line
                if len(my_list) > 0:
                    raise ValueError("Couldn't find . in line " + str(line_count))
                break
            elif current[0] == ' ' or current[0] == '\t':
                current += 1
            elif current[0] == '_':
                current += 1
                if current >= lineend:
                    raise ValueError("Parsed blank node (starting with underscore) but encountered line end directly afterwards. Line : " + str(line_count))
                if current[0] != ':':
                    raise ValueError("Parsed blank node (starting with underscore) but encountered no colon afterwards . Line : " + str(line_count))
                current += 1
                startNode = current
                # search for first character not in starting character of other elements:
                while current[0] != '\n' and current < lineend and current[0] != ' ' and current[0] != '\t' and current[0] != '<' and current[0] != '.' and current[0] != '"' and current[0] != '#':
                    current += 1
                my_list.append(BNode(startNode[:current - startNode].decode('UTF-8')))
            elif current[0] == '<':
                current += 1
                startNode = current
                current = <char*>memchr(<void*>current, '>', lineend - current)
                if current == NULL:
                    raise ValueError("Could not find closing '>' bracket for resource in line " + str(line_count))
                my_list.append(Resource(startNode[:current - startNode].decode('UTF-8')))
                current += 1
            elif current[0] == '.':
                if len(my_list) == 0:
                    raise ValueError("No nodes but statement end in line " + str(line_count))
                yield my_list
                break
            elif current[0] == '"':
                current += 1
                startNode = current
                while True:
                    current = <char*>memchr(<void*>current, '"', lineend - current)
                    if current == NULL:
                        raise ValueError('Could not find closing " for literal in line ' + str(line_count))
                    if current[-1] != '\\':
                        break
                    i = -1
                    while current[i] == '\\':
                        i = i - 1
                    if (i+1) % 2 == 0:
                        break
                    current += 1
                literal_lexical = startNode[:current - startNode].decode('UTF-8')
                current += 1

                #find literal extension
                startNode = current
                while not ((current[0] == '.' and (current[1] == ' ' or (current + 2) >= lineend )) or current[0] == ' '):
                    current += 1
                my_list.append(Literal(literal_lexical, startNode[:current - startNode].decode('UTF-8')))
            elif current[0] == '#':
                if len(my_list) > 0:
                    raise ValueError("Couldn't find . in line " + str(line_count))
                break
            else:
                raise ValueError("Exception: Wrong starting character in line " + str(line_count))

            if current >= lineend:
                if len(my_list) == 0:
                    break
                else:
                    raise ValueError("Couldn't find . in line " + str(line_count) + ":" + str(my_list))
        linestart = lineend + 1


#https://github.com/nxparser/nxparser/blob/master/nxparser-parsers/src/main/java/org/semanticweb/yars/nx/parser/NxParser.java
#https://stackoverflow.com/questions/6874102/python-strings-in-a-cython-extension-type