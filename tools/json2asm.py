# Python program to read
# json file
import sys
import json

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

# data = compress( screen )
# print_asm( data )

data = compress(screen)
# data = screen
print( f"{sys.argv[1]}SCR: ;{len(data)} bytes {(1-len(data)/len(screen))*100}% saved" )
print_asm( data )

data = compress(color)
# data = color
print( f"{sys.argv[1]}COL: ;{len(data)} bytes {(1-len(data)/len(color))*100}% saved" )
print_asm( data )

# Closing file
# f.close()
