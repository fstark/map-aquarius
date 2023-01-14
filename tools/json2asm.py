# Python program to read
# json file
import sys
import json

def print_asm( data ):
    for y in range(0,24):
        print( "        DB ", end="" )
        sep = ""
        for x in range(0,40):
            print( f"{sep}0{data[y*40+x]:02x}h", end="" )
            sep = ","
        print()


# Opening JSON file
# f = open('assets/samplescreen.json')

# returns JSON object as 
# a dictionary
data = json.load(sys.stdin)

screen = [32]*960
color = [6]*960

for i in data:
    if i['index']>=0:
        screen[i['index']] = i['char']
        color[i['index']] = i['fg']*16+i['bg']

print( f"{sys.argv[1]}SCR:" )
print_asm( screen )
print( f"{sys.argv[1]}COL:" )
print_asm( color )

# Closing file
# f.close()
