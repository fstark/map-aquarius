    cpu Z80

    ORG 0c000h

    db 0

    ORG 0e000h

    db  102, 114, 101, 100
    db  115, 156, 116, 176
    db  97, 108, 114, 100
    db  107, 168, 213, 112

start1:
    ld de,SCREENBASE+40
    ld hl,SAMPLESCR
    ld bc,960
    ldir

    ld de,COLORBASE+40
    ld hl,SAMPLECOL
    ld bc,960
    ldir
loop:
    jp loop


main:
    ld hl,3028h
    ld a,'A'
    ld c,24
line:
    ld b,40
char:
    ld (hl), a
    inc hl
    djnz char
    inc a
    dec c
    jr nz,line
    jp main

SCREENBASE = 03000h
COLORBASE = 03400h

; xy2screen
; input:
;   b = x (0-39)
;   c = y (1-24)
; output
;   hl = screen adrs
; destroys: d,e,h,l
xy2screen:
    ld d,0
    ld e,c
    ld h,0
    ld l,c
    add hl,hl       ; *2
    add hl,hl       ; *4
    add hl,de       ; *5
    add hl,hl       ; *10
    add hl,hl       ; *20
    add hl,hl       ; *40
    ld de,SCREENBASE
    add hl,de   ; +SCREENBASE
    ld d,0
    ld e,b
    add hl,de
    ret

; waitvbl
;   Wait for the vbl to be off screen
; destroys: a
waitvbl:
    in a,0fdh
    bit 0,a
    jp z,waitvbl
.loop:
    in a,0fdh
    bit 0,a
    jp nz,.loop
    ret

    include "sprites.inc"
    include "sample.inc"



; put_sprite


    org 0ffffh
    db 1
