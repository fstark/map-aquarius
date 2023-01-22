    cpu Z80
    relaxed on


;   --------------------------------------------------------------
;   Global variables representing the player state
;   --------------------------------------------------------------

    ORG $3800

    ;   KEYS needs to not cross a page boundary
KEYS:
    db ?,?,?,?,?,?,?,?

K_SPC:  equ     $64
K_RTN:  equ     $03
K_J:    equ     $25
K_K:    equ     $22
K_SHIFT:equ     $74
K_S:    equ     $62
K_M:    equ     $23
K_1:    equ     $72
K_2:    equ     $70
K_3:    equ     $60
K_4:    equ     $52
K_9:    equ     $20
K_0:    equ     $12
K_R:    equ     $53
K_E:    equ     $61


MAX_MONEY EQU 13
MAX_LIFE EQU 5
MAX_SCORE EQU 10

PLAYER_BASE:
MONEY:
    db ?       ;   max = 13
LIFE:
    db ?        ;   max = 5
SCORE:
    db ?        ;   max = 10

    ORG 0c000h

    db 0

;   --------------------------------------------------------------
;   E000 : Cartridge protection code
;   --------------------------------------------------------------
    ORG 0e000h
    db  102, 114, 101, 100
    db  115, 156, 116, 176
    db  97, 108, 114, 100
    db  107, 168, 213, 112

;   --------------------------------------------------------------
;   entry point of Mini Auto Pets
;   --------------------------------------------------------------
entry:
        ;   Displays the splash
    ld hl,SPLASHSCR
    call display_cscreen

        ;   Wait 1/2 second
    ld a,25
    call wait_vbls

        ;   Displays presents
    ld hl,MSG1
    call print_msg

        ;   Wait 1 second
    ld a,50
    call wait_vbls

        ;   Display title screen
    ld hl,TITLESCR
    call display_cscreen

.loop:
    ld a,40
    call wait_vbls
    ld hl,MSG2
    call print_msg
    ld a,20
    call wait_vbls
    ld hl,MSG3
    call print_msg

    call read_keys
    ld a,K_SPC
    call check_key
    jp z,.shop

    jp .loop


        ;   Wait for a key

.shop:
    call init_game
    call display_shop_bg
    call display_status

.game:
    jp .game


;   --------------------------------------------------------------
;   Initialize the game
;   --------------------------------------------------------------

init_game:
    ld de,PLAYER_BASE
    ld hl,PLAYER_BASE_INIT
    ld bc,3
    ldir
    ret

PLAYER_BASE_INIT:
    db 10,5,0

;   --------------------------------------------------------------
;   Displays the status bar on top of the screen
;   --------------------------------------------------------------
display_status:
    ld hl,SCREENBASE+3
    ld ix,PLAYER_BASE

        ;   Display money
    ld b,(ix+MONEY-PLAYER_BASE)
    ld de,$9636
    call displays_with_color

    ld a,MAX_MONEY
    sub (ix+MONEY-PLAYER_BASE)
    ld b,a
    ld de,$9686
    call displays_with_color

    inc hl
    inc hl
    inc hl

        ;   Display score
    ld b,(ix+SCORE-PLAYER_BASE)
    ld de,$9126
    call displays_with_color

    ld a,MAX_SCORE
    sub (ix+SCORE-PLAYER_BASE)
    ld b,a
    ld de,$9186
    call displays_with_color

    inc hl
    inc hl
    inc hl

    ld b,(ix+LIFE-PLAYER_BASE)
    ld de,$d416
    call displays_with_color

    ld a,MAX_LIFE
    sub (ix+LIFE-PLAYER_BASE)
    ld b,a
    ld de,$d486

;    jp displays_with_color

;   --------------------------------------------------------------
;   Displays several identical characters with specific background
;   --------------------------------------------------------------
;   hl : where to display
;   d  : character
;   e  : color
;   b  : count
;   --------------------------------------------------------------
displays_with_color:
    ld a,b
    cp 0
    jp z,.end
 .loop:
    call display_with_color
    djnz .loop
.end
    ret

;   --------------------------------------------------------------
;   Displays on character with specific background
;   --------------------------------------------------------------
;   hl : where to display
;   d  : character
;   e  : color
;   --------------------------------------------------------------
display_with_color:
    push hl
    ld a,d
    ld (hl),a
    ld a,h
    add a,4         ;   go to color mem
    ld h,a
    ld a,e
    ld (hl),e
    pop hl
    inc hl
    ret

    ld hl,MUSIC
    call playmusic

;    call waitkey            ; wait for keypress
    ret

;   --------------------------------------------------------------
;   check_key2 : checks if a key is pressed
;   a : code of the key to check
;   --------------------------------------------------------------
check_key:
    exx
    ld d,a          ;   save A

    and $0f         ;   Last 4 bits are the bit postion to check
    ld b,0
    ld c,a
    ld hl,DEMUX4
    add hl,bc    
    ld e,(hl)       ;   e contains the mask

    sra d
    sra d
    sra d
    sra d
    ld c,d
    ld hl,KEYS
    add hl,bc
    ld a,(hl)
    and e
    exx
    ret

DEMUX4:
    DB  $01,$02,$04,$08,$10,$20,$40,$80

;   --------------------------------------------------------------

;   --------------------------------------------------------------

print_msg:
    ld b,(hl)       ; x
    inc hl
    ld c,(hl)       ; y
    inc hl
    push hl
    call xy2screen
    ex de,hl
    pop hl
    ld b,0
    ld c,(hl)
    inc hl
    ldir
    ret

MSG1:
    DB 14,24
    DB 8
    DB 'PRESENTS'

MSG2:
    DB 10,22
    DB 19
    DB 'PRESS SPACE TO PLAY'
MSG3:
    DB 10,22
    DB 19
    DB '                   '


;display_shop_bg:   displays the shop background
display_shop_bg:
    ld hl,SHOPSCR
    jp display_cscreen

; display_cscreen: displays a compressed screen
display_cscreen:
    ld de,SCREENBASE+40
    call unpack
    ld de,COLORBASE+40
;    jp unpack

unpack:
    ; first byte
.loop:
    ld a,(hl)
    cp $00
    inc hl
    jp z,.end
    cp $80
    jp m,.copy

.repeat:            ;  >$80, repeat operation
    sub 126
    ld b,a
    ld a,(hl)
    inc hl
.repeat1:
    ld (de),a
    inc de
    djnz .repeat1
    jp .loop

.copy:              ; <$80, copy operation
    ld b,0
    ld c,a
    ldir
    jp .loop

.end:
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

; wait_vbls: wait the amount of vlb in a
wait_vbls:
    ld b,a
.loop:
    call wait_vbl
    djnz .loop
    ret    

; wait_vbl: Wait for the vbl to be off screen
; destroys: a
wait_vbl:
    in a,0fdh
    bit 0,a
    jp z,wait_vbl
.loop:
    in a,0fdh
    bit 0,a
    jp nz,.loop
    ret

    include "splash.inc"
    include "title.inc"
    include "shop.inc"

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


read_keys:
.loop
    ld hl,SCREENBASE+40     ;   We print in the top of the screen

    ld c,0xff               ;   Keyboard input
    ld d,0xfe               ;   Initial mask: '1111110'
    ld b,8                  ;   8 scans
    ld ix,KEYS
.loop1:
    push bc

    ld b,d                  ;   Side-effect: is on the bus during 'in'
    in a,(c)
    ld (ix),a
    inc ix

    call print_binary
    ld bc,40-8
    add hl,bc

    pop bc

    ld a,d                  ; move mask 1 left (mask has a single 0)
    rl a
    or a,1
    ld d,a

    djnz .loop1
    ret

; print_binary: prints the content of 'a' in binary in (hl)
; increments hl
; destroys: a,b,c
print_binary:
    ld b,8
.loop:
    bit 7,a
    ld c,'0'
    jp z,.print0
    inc c
.print0:
    ld (hl),c
    inc hl
    rl a
    djnz .loop
    ret




    org 0ffffh
    db 1
