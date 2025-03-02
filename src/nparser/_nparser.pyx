cimport cython
from libc.string cimport memchr, memcpy, strlen

from libc.stdio cimport FILE, fopen, fgets, fclose
from libc.stdlib cimport malloc, free

cdef class Resource:
    cdef public str value

    def __init__(self, c):
        self.value = c

    def __repr__(self) -> str:
        return "<" + self.value + ">"
    def __str__(self) -> str:
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


def parse_three(file_like):
    # Read each line
    cdef char* current
    cdef char* lineend
    cdef char* bla
    cdef int line_count = 0
    while True:
        line = file_like.readline()  # Read a single line
        if not line:
            break
        current = line
        lineend = current + strlen(current)
        line_count += 1
        my_list = []
        while True:
            if current >= lineend:
                if len(my_list) > 0:
                    raise ValueError("Couldn't find . in line " + str(line_count))
                break
            elif current[0] == ' ' or current[0] == '\t':
                current += 1
            elif current[0] == '<':
                current += 1
                startNode = current
                current = <char*>memchr(<void*>current, '>', lineend - current)
                if current == NULL:
                    raise ValueError("Could not find closing '>' bracket for resource in line " + str(line_count))
                my_list.append(Resource(startNode[:current - startNode].decode('UTF-8')))
                current += 1
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
            elif current[0] == '.':
                if len(my_list) == 0:
                    raise ValueError("No nodes but statement end in line " + str(line_count))
                yield my_list
                break
            elif current[0] == '#':
                if len(my_list) > 0:
                    raise ValueError("Couldn't find . in line " + str(line_count))
                break
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
            else:
                raise ValueError("Exception: Wrong starting character in line " + str(line_count))

cdef inline parse_line_inline(char* current, char* lineend, int line_count):
    cdef my_list = []
    while True:
        if current >= lineend:
            if len(my_list) > 0:
                raise ValueError("Couldn't find . in line " + str(line_count))
            break
        elif current[0] == ' ' or current[0] == '\t':
            current += 1
        elif current[0] == '<':
            current += 1
            startNode = current
            current = <char*>memchr(<void*>current, '>', lineend - current)
            if current == NULL:
                raise ValueError("Could not find closing '>' bracket for resource in line " + str(line_count))
            my_list.append(Resource(startNode[:current - startNode].decode('UTF-8')))
            current += 1
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
        elif current[0] == '.':
            if len(my_list) == 0:
                raise ValueError("No nodes but statement end in line " + str(line_count))
            return my_list
        elif current[0] == '#':
            if len(my_list) > 0:
                raise ValueError("Couldn't find . in line " + str(line_count))
            break
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
        else:
            raise ValueError("Exception: Wrong starting character in line " + str(line_count))
    if len(my_list) > 0:
        raise ValueError("Elements are encountered but no . in line " + str(line_count))
    return my_list
        

cdef parse_line(char* current, char* lineend, int line_count):
    cdef my_list = []
    while True:
        if current >= lineend:
            if len(my_list) > 0:
                raise ValueError("Couldn't find . in line " + str(line_count))
            break
        elif current[0] == ' ' or current[0] == '\t':
            current += 1
        elif current[0] == '<':
            current += 1
            startNode = current
            current = <char*>memchr(<void*>current, '>', lineend - current)
            if current == NULL:
                raise ValueError("Could not find closing '>' bracket for resource in line " + str(line_count))
            my_list.append(Resource(startNode[:current - startNode].decode('UTF-8')))
            current += 1
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
        elif current[0] == '.':
            if len(my_list) == 0:
                raise ValueError("No nodes but statement end in line " + str(line_count))
            return my_list
        elif current[0] == '#':
            if len(my_list) > 0:
                raise ValueError("Couldn't find . in line " + str(line_count))
            break
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
        else:
            raise ValueError("Exception: Wrong starting character in line " + str(line_count))
    if len(my_list) > 0:
        raise ValueError("Elements are encountered but no . in line " + str(line_count))
    return my_list



def parse_two_a(file_like, int chunk_size=1024):
    """
    Each iteration, buffer is concatenated with chunk:
    In Python, bytes objects are immutable, so this creates a new allocation each time, leading to performance overhead.
    A better approach is to use a bytearray instead, which allows efficient in-place modification.
    """
    cdef bytearray buffer = bytearray()
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, pos
    cdef char* line_end
    cdef int line_count = 0

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                buf = <char*>buffer
                line_count += 1
                elements = parse_line(buf, buf + len(buffer), line_count)
                if elements:
                    yield elements
            break

        # Append the chunk to the existing buffer
        buffer.extend(chunk)
        buf = <char*>buffer
        length = len(buffer)
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            
            if line_end is not NULL:
                line_count += 1
                elements = parse_line(buf + pos, line_end, line_count)
                if elements:
                    yield elements

                pos = line_end - buf + 1
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[pos:]
                break


def parse_two(file_like, int chunk_size=1024):
    """
    Parse lines from a file-like object using memchr for efficient line detection.
    Assumes the file-like object only supports the `read` method.
    """
    cdef bytes buffer = b""
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, pos
    cdef char* line_end
    cdef int line_count = 0

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                buf = <char*>buffer
                line_count += 1
                elements = parse_line(buf, buf + len(buffer), line_count)
                if elements:
                    yield elements
            break

        # Append the chunk to the existing buffer
        buffer += chunk
        buf = <char*>buffer
        length = len(buffer)
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            
            if line_end is not NULL:
                line_count += 1
                elements = parse_line(buf + pos, line_end, line_count)
                if elements:
                    yield elements

                pos = line_end - buf + 1
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[pos:]
                break

def parse_two_with_inline(file_like, int chunk_size=1024):
    """
    Parse lines from a file-like object using memchr for efficient line detection.
    Assumes the file-like object only supports the `read` method.
    """
    cdef bytes buffer = b""
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, pos
    cdef char* line_end
    cdef int line_count = 0

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                buf = <char*>buffer
                line_count += 1
                elements = parse_line_inline(buf, buf + len(buffer), line_count)
                if elements:
                    yield elements
            break

        # Append the chunk to the existing buffer
        buffer += chunk
        buf = <char*>buffer
        length = len(buffer)
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            
            if line_end is not NULL:
                line_count += 1
                elements = parse_line_inline(buf + pos, line_end, line_count)
                if elements:
                    yield elements

                pos = line_end - buf + 1
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[pos:]
                break



def parse_two_without_function(file_like, int chunk_size=1024):
    """
    Parse lines from a file-like object using memchr for efficient line detection.
    Assumes the file-like object only supports the `read` method.
    """
    cdef bytes buffer = b""
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, pos
    cdef char* line_end
    cdef int line_count = 0
    cdef char* current

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                buf = <char*>buffer
                line_count += 1
                elements = parse_line(buf, buf + len(buffer), line_count)
                if elements:
                    yield elements
            break

        # Append the chunk to the existing buffer
        buffer += chunk
        buf = <char*>buffer
        length = len(buffer)
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            
            if line_end is not NULL:
                line_count += 1
                
                #elements = parse_line(buf + pos, line_end, line_count)
                # function begin
                current = buf + pos
                my_list = []
                while True:
                    if current >= line_end:
                        if len(my_list) > 0:
                            raise ValueError("Couldn't find . in line " + str(line_count))
                        break
                    elif current[0] == ' ' or current[0] == '\t':
                        current += 1
                    elif current[0] == '<':
                        current += 1
                        startNode = current
                        current = <char*>memchr(<void*>current, '>', line_end - current)
                        if current == NULL:
                            raise ValueError("Could not find closing '>' bracket for resource in line " + str(line_count))
                        my_list.append(Resource(startNode[:current - startNode].decode('UTF-8')))
                        current += 1
                    elif current[0] == '"':
                        current += 1
                        startNode = current
                        while True:
                            current = <char*>memchr(<void*>current, '"', line_end - current)
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
                        while not ((current[0] == '.' and (current[1] == ' ' or (current + 2) >= line_end )) or current[0] == ' '):
                            current += 1
                        my_list.append(Literal(literal_lexical, startNode[:current - startNode].decode('UTF-8')))
                    elif current[0] == '.':
                        if len(my_list) == 0:
                            raise ValueError("No nodes but statement end in line " + str(line_count))
                        yield my_list
                        break
                    elif current[0] == '#':
                        if len(my_list) > 0:
                            raise ValueError("Couldn't find . in line " + str(line_count))
                        break
                    elif current[0] == '_':
                        current += 1
                        if current >= line_end:
                            raise ValueError("Parsed blank node (starting with underscore) but encountered line end directly afterwards. Line : " + str(line_count))
                        if current[0] != ':':
                            raise ValueError("Parsed blank node (starting with underscore) but encountered no colon afterwards . Line : " + str(line_count))
                        current += 1
                        startNode = current
                        # search for first character not in starting character of other elements:
                        while current[0] != '\n' and current < line_end and current[0] != ' ' and current[0] != '\t' and current[0] != '<' and current[0] != '.' and current[0] != '"' and current[0] != '#':
                            current += 1
                        my_list.append(BNode(startNode[:current - startNode].decode('UTF-8')))
                    else:
                        raise ValueError("Exception: Wrong starting character in line " + str(line_count))
                # function end


                pos = line_end - buf + 1
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[pos:]
                break






def parse_two_old(file_like, int chunk_size=1024):
    """
    Parse lines from a file-like object using memchr for efficient line detection.
    Assumes the file-like object only supports the `read` method.
    """
    cdef bytes buffer = b""
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, start, pos
    cdef char* line_end

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                pass
                #elements = parse_line(<char*>buffer, buffer+len(buffer), )
                #print("remaining buffer: ", end="")
                #print(buffer)
            break

        # Append the chunk to the existing buffer
        buffer += chunk
        buf = <char*>buffer
        length = len(buffer)
        start = 0
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            
            if line_end is not NULL:
                # Calculate the position of the newline
                pos = line_end - buf
                # Extract the line (excluding the newline character)
                line = buffer[start:pos]
                
                # Process the line
                print("line:", end="")
                print(line)
                
                # Move past the newline character
                pos += 1
                start = pos
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[start:]
                break
        else:
            # Clear the buffer if fully processed
            buffer = b""

    #return processed_lines


def parse_ten(file_like, int chunk_size=1024):

    cdef FILE *f = fopen('skos_categories_en.ttl', 'r')
    if not f:
        raise IOError("Failed to open the file")

    cdef bytes buffer = b""
    cdef int line_count = 0
    cdef char* char_buf
    
    while True:
        # Read a line into buffer
        buffer = fgets(buffer, chunk_size, f)
        
        if not buffer:
            break  # End of file
        char_buf = <char*> buffer
        line_count += 1
        elements = parse_line(char_buf, char_buf + len(buffer), line_count)
        if elements:
            yield elements

    fclose(f)



def parse_eleven(file_like, int chunk_size=1024):

    """
    Parse lines from a file-like object using memchr for efficient line detection.
    Assumes the file-like object only supports the `read` method.
    """
    
    cdef bytes chunk
    cdef char* buf
    cdef Py_ssize_t length, pos
    cdef char* line_end
    cdef int line_count = 0
    cdef int capacity = chunk_size * 5
    cdef bytes buffer = b"\x00" * capacity  # Initialize the buffer with the given capacity

    while True:
        # Read the next chunk from the file-like object
        chunk = file_like.read(chunk_size)
        #print("chunk: ", end="")
        #print(chunk)
        if not chunk:
            # No more data to read, and in the buffer is also no newline anymore,
            # thus the buffer needs to contain the last line which has no newline and still needs to be processed
            if buffer:
                buf = <char*>buffer
                line_count += 1
                elements = parse_line(buf, buf + len(buffer), line_count)
                if elements:
                    yield elements
            break

        # Append the chunk to the existing buffer

        # Calculate the new length after adding the chunk
        new_length = len(buffer) + len(chunk)

        print("one")
        # Check if the buffer has enough space to accommodate the new data
        if new_length > capacity:
            print("two")
            # Need to allocate more memory for the buffer
            capacity = new_length  # Update capacity
            new_buf = <char*>malloc(capacity)  # Allocate new buffer

            print("three")
            if not new_buf:
                raise MemoryError("Failed to allocate memory for buffer")

            # Copy the existing buffer content to the new buffer
            memcpy(new_buf, <char*>buffer, len(buffer))
            # Copy the new chunk content to the new buffer
            memcpy(new_buf + len(buffer), <char*>chunk, len(chunk))
            
            print("four")
            # Free the old buffer (Python will automatically handle freeing the old `bytes` object)
            buffer = <bytes>new_buf
        else:
            print("five")
            # If the buffer has enough space, just copy the chunk into the existing buffer
            memcpy(<char*>buffer + len(buffer), <char*>chunk, len(chunk))

        print("six")
        # buffer += chunk # all this is done above

        buf = <char*>buffer
        length = len(buffer)
        pos = 0

        while pos < length:
            # Find the next newline character in the buffer
            line_end = <char*>memchr(buf + pos, b'\n', length - pos)
            print("seven")
            if line_end is not NULL:
                line_count += 1
                elements = parse_line(buf + pos, line_end, line_count)
                if elements:
                    yield elements

                pos = line_end - buf + 1
            else:
                # No more newlines in this chunk, retain remaining buffer
                buffer = buffer[pos:]
                break



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
            #print("lineend == NULL")
            copy_amount = (buf + bytes_read) - linestart
            memcpy(buf, linestart, copy_amount)
            buf_py = file_like.read(8388609 - copy_amount)
            if not buf_py:
                #print("if not buf_py")
                last_line = 1
                lineend = buf + copy_amount
            else:
                #print("else")
                bytes_read = len(buf_py)
                memcpy(buf + copy_amount,<char*>buf_py, bytes_read)
                bytes_read += copy_amount
                linestart = buf

                lineend = <char*>memchr(<void*>linestart, '\n', (buf + bytes_read) - linestart)
                if lineend == NULL:
                    #print("if lineend == NULL")
                    last_line = 1
                    lineend = buf + bytes_read
        #print(line_count)
        #print(linestart[:lineend-linestart].decode('UTF-8'))
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