# Python program to read
# json file
import sys
import json
import argparse

def print_asm( data ):
    for y in range(0,24):
        i = y*40
        if i>=len(data):
            return
        print( "        DB ", end="" )
        sep = ""
        for x in range(0,40):
            i = y*40+x
            if i>=len(data):
                print()
                return
            print( f"{sep}${data[i]:02x}", end="" )
            sep = ","
        print()

def compress( data ):
    result = []
    current = 0
    end = len(data)

    # current: position in the input
    # next_pair: position where we have the next char in double

    while current<end:
        # We look for the next pair of identical characters
        next_pair = current
        while next_pair<end-1:
            if data[next_pair]==data[next_pair+1]:
                break
            next_pair += 1

        # If we didn't find a pair up to the last two chars, we skip to the end
        if next_pair==end-1:
            next_pair = end

        # All character until next_pair don't repeat
        if next_pair!=current:
            #  We have to write len litterals, but only in 128 blocs
            l = next_pair-current
            while (l):
                #  We can write at most 128 literals in one go
                sub_length = l
                if sub_length>128:
                    sub_length = 128
                l -= sub_length
                result.append( sub_length )
                for i in range( 0, sub_length ):
                    result.append( data[current+i] )
                current += sub_length

        # Now, we are at the start of the next run, or at the end of the stream
        if current==end:
            break

        c = data[current]

        # Find the len of the run
        l = 0
        while data[current]==c:
            l += 1
            current += 1
            if l==128:
                break
            if current==end:
                break

        result.append( l+126 )
        result.append( c )

        # We don't care about the fact that the run may continue, it will be handled by the next loop iteration

    result.append( 0 )

    return result

def extract( array, x0, y0, w, h ):
    result = []
    for y in range(y0,y0+h):
        for x in range(x0,x0+w):
            result.append( array[y*40+x] )
    return result

# test cases for compression

# data0 = [0,1,2]
# compress0 = [3,0,1,2]

# data1 = [0,0,0,0]
# compress1 = [130,0]

# data2 = [0,1,2,0,0,0,0]
# compress2 = [3,0,1,2,130,0]

# data3 = [0]*255
# compress3 = [254,0,253,0]

# print_asm( data3 )
# print_asm( compress(data3) )

# Opening JSON file
# f = open('assets/samplescreen.json')

# returns JSON object as 
# a dictionary


parser = argparse.ArgumentParser(
                    prog = 'json2asm',
                    description = 'Converts AquariusDraw images into compressed Z80 Assembly files',
                    epilog = '')

parser.add_argument( '-l', '--label', default="DATA", help='Label to use for assembly generation' )      # option that takes a value
parser.add_argument( '-s', '--splice', action='store_true', help='Splice a sprite sheet' )  # on/off flag
parser.add_argument( '-sw', '--width', help='Width of sprites', default=5 )  # on/off flag
parser.add_argument( '-sh', '--height', help='Height of sprites', default=5 )  # on/off flag

args = parser.parse_args()

data = json.load(sys.stdin)

screen = [32]*960
color = [-1]*960

for i in data:
    ix = i['index']
    if ix>=0:
        screen[i['index']] = i['char']
        color[i['index']] = i['fg']*16+i['bg']
    if ix==-1:
        defcol = i['fg']*16+i['bg']
        for i in range(0,960):
            if color[i]==-1:
                color[i] = defcol 

if (args.splice):
    print( "; SPLICING" )
    ix = 0
    for y in range(0,4):
        for x in range(0,8):
            print( f"; Sprite {ix}" )
            print( f"{args.label}{ix}:" )
            data = extract( screen, x*args.width, y*args.height, args.width, args.height )
            print_asm( compress(data) )
            data = extract( color, x*args.width, y*args.height, args.width, args.height )
            print_asm( compress(data) )
            ix = ix+1
    print( f"{args.label}: dw ", end="" )
    sep = ""
    for i in range(0,32):
        print( f"{sep}{args.label}{i}", end="" )
        sep = ","
    print()
else:
    # data = compress( screen )
    # print_asm( data )

    data = compress(screen)
    # data = screen
    print( f"{args.label}SCR: ;{len(data)} bytes {(1-len(data)/len(screen))*100}% saved" )
    print_asm( data )

    data = compress(color)
    # data = color
    print( f"{args.label}COL: ;{len(data)} bytes {(1-len(data)/len(color))*100}% saved" )
    print_asm( data )

# Closing file
# f.close()
