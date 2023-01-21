# map-aquarius
Mini Auto Pets, for the Mattel Aquarius

Work in progress very preliminary

# Building

Enter make at the top level

# Organisation

assets/
    json files with mattel aquarius assets
    editable using https://aquarius.mattpilz.com/draw/

docs/
    design documents for the game

src/
    assembly source code, including generated code

tools/
    associated tooling (an asset to assembly converter)



# Music format work in progress

2 bytes. 1st byte frequency:

0x10a = 79 cycles

100 means 400*5.25 microseconds

1000000/440/4/5.25

    392.00 121
A4: 440.00 108
    466.16 102
B4: 493.88 96
C5: 523.25 91
D5: 587.33 81
E5: 659.25 72

1.05945938207


