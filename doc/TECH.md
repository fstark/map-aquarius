# Compression

Compression of images is performed by a standard run length encoding, with the following format:

byte:
    1-127:   the next n bytes are copied
    128-255: the next byte is replicated n-126 times
