    cpu Z80

    ORG 0c000h

    db 0

; The cartrige "protection" has to reside at 0e000h
    ORG 0e000h
    db  102, 114, 101, 100
    db  115, 156, 116, 176
    db  97, 108, 114, 100
    db  107, 168, 213, 112

    ld hl,SAMPLESCR
    call showscreen         ; display splash screen
    call waitkey            ; wait for keypress
    ret

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

; showscreen: displays a full screen of data
; input
;   hl: 960 bytes of screen data, followed by 960 bytes of color data
; destroys: b,c,d,e,h,l
showscreen:
    ld de,SCREENBASE+40
    ld bc,960
    ldir
    ld de,COLORBASE+40
    ld bc,960
    ldir
    ret

waitkey:
    call 01e80h
    cp a,0
    jp z,waitkey
    ret

; put_sprite


    org 0ffffh
    db 1
