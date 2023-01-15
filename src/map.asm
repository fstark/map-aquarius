    cpu Z80

    ORG 0c000h

    RELAXED ON

    db 0

; The cartrige "protection" has to reside at 0e000h
    ORG 0e000h
    db  102, 114, 101, 100
    db  115, 156, 116, 176
    db  97, 108, 114, 100
    db  107, 168, 213, 112

    ld hl,SAMPLESCR
    call showscreen         ; display splash screen

.loop:
    ld hl,MUSIC
    call playmusic
    jp .loop

    call waitkey            ; wait for keypress
    ret

; playmusic:
; input
;    hl : points on a music table (pitch,duration), terminated by a zero
playmusic:
    ld a,(hl)
    inc hl
    cp $ff
    jp z,.end

    cp $0
    jp nz,.skip1
    
    ld bc,1000
    ld d,h
    ld e,l
    push hl
    ldir
    pop hl
    jp playmusic

.skip1:
    cp $1
    jp nz,.skip2

    ld bc,10000
    ld d,h
    ld e,l
    push hl
    ldir
    pop hl
    jp playmusic

.skip2:
    ld e,(hl)
    inc hl
    push hl
    ld h,0
    ld l,a
    add hl,hl
    add hl,hl
    ld b,h
    ld c,l
    call playnote

    pop hl
    jp playmusic
.end:
    ret

; playnote:
; input
;   bc : pitch               ; pitch is a delay, and must be correctly pre-computed
;   e : duration            ; duration is a repeat count, and depends on the pitch itself
playnote:
    ld a,$ff                ; We will alternate a $ff and a $00 pattern

.loop:
    ld d,4
.loop1:
    out 0fch,a              ; Click
    xor a,$ff               ; Will revert next

    call playdelay

    dec d
    jp nz,.loop1

    dec e                  ; duration--
    jp nz,.loop

    ret

; playdelay (internal)
playdelay:
    push bc
    push de
    ld d,h
    ld e,l
    ldir
    pop de
    pop bc
    ret

MUSIC:
    db 1,1,1,1,1,1,1

    db 91,30,0
    db 91,30,0
    db 91,30,0
    db 81,30,0
    db 72,60,0
    db 81,60,1

    db 91,30,0
    db 72,30,0
    db 81,30,0
    db 81,30,0
    db 91,60,1

    db 91,30,0
    db 91,30,0
    db 91,30,0
    db 81,30,0
    db 72,60,0
    db 81,60,1

    db 91,30,0
    db 72,30,0
    db 81,30,0
    db 81,30,0
    db 91,60,1

    db 72,30,0
    db 72,30,0
    db 72,30,0
    db 72,30,0
    db 108,60,0
    db 108,60,1

    db 81,30,0
    db 91,30,0
    db 96,30,0
    db 108,30,0
    db 121,60,1


    db 91,30,0
    db 91,30,0
    db 91,30,0
    db 81,30,0
    db 72,60,0
    db 81,30,1

    db 91,30,0
    db 72,30,0
    db 81,30,0
    db 81,30,0
    db 91,60,1

    db 1,1,1,1,1,1,1

    db $ff

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
