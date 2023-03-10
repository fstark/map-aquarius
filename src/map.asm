;   --------------------------------------------------------------
;   Include file containing code related to display
;   --------------------------------------------------------------

    cpu Z80
    relaxed on


    ORG $3800
    include "variables.asm"

    ORG 0c000h

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

    call random_init;
    call display_init

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

    ld a,1
    ld (SCRATCH1),a
.loop:


    call display_copy_rev
    ld d,30
    ld e,5
    ld a,(SCRATCH1)
    inc a
    and a,$1f
    ld (SCRATCH1),a
    call draw_sprite

    ld a,40
    call wait_vbls
    ld hl,MSG2
    call print_msg

;    ld d,30
;    ld e,5
;    ld b,5
;    ld c,5
;    call erase_rect

    call display_copy
    ld d,3
    ld e,13
    ld a,(SCRATCH1)
    inc a
    and a,$1f
    ld (SCRATCH1),a
    call draw_sprite


    ld a,20
    call wait_vbls
    ld hl,MSG3
    call print_msg

    call read_keys
    ld a,K_SPC
    call check_key
    jr z,.shop

    jr .loop


.shop:
    call game_init
    call shop_init
    call shop_loop

.game:
    ld hl,SAMPLESCR
    call display_cscreen
    jr .game

;   --------------------------------------------------------------
;   Init shop interactions (user can't do anything)
;   --------------------------------------------------------------

init_shop_inter:
    ld hl,SHOP_INTER
    ld de,SHOP_INTER+1
    ld bc,SHOP_INTER_COUNT-1
    ld (hl),0
    ldir
    ret

;   --------------------------------------------------------------
;   Update shop interaction text to represent possible actions
;   --------------------------------------------------------------
update_shop_inter:
        ;   The line we need to update
    ld hl,COLORBASE+40*SHOP_TOP_Y+SHOP_TOP_X
    ld de,SHOP_INTER
    ld b,SHOP_INTER_COUNT
.loop:
    ld a,(de)
    or a
    ld a,$07
    jr nz,.skip
    ld a,$87
.skip:
    push bc
    call update_shop_inter_line
    ld bc,40-16
    add hl,bc
    pop bc
    inc de
    djnz .loop

    ret

;   --------------------------------------------------------------
;   Updates a line of the shop interaction menu
;   --------------------------------------------------------------
update_shop_inter_line:
    ld b,16
.loop:
    ld (hl),a
    inc hl
    djnz .loop
    ret


    ; disable text item #x
.disable_text:

;   --------------------------------------------------------------
;   Compute shop interaction possibilities according to game state
;   --------------------------------------------------------------
compute_shop_inter:
    ld IX,GLOBALS
        ;    We first look if we can DO stuff

        ;   First based on the selected index
    ld a,(IX+SHOP_SELECT_IX)
    ld b,a
    or a
    jr z,.next1
        ;   Can do anything left if not in position 0
    ld (IX+CAN_LEFT),$ff
    ld (IX+CAN_MLEFT),$ff
    ld (IX+CAN_MERGE),$ff   ; we could even merge!
.next1:
    ld a,b
    cp a,$3
    jr z,.next2
        ;   Can do anything right if not in position 3
    ld (IX+CAN_RIGHT),$ff
    ld (IX+CAN_MRIGHT),$ff
.next2:

    ld (ix+CAN_ROLL),$ff
    ld a,(ix+MONEY-GLOBALS)
    cp 0
    jp nz,.next3
    ld (ix+CAN_ROLL),a
.next3:

    ret

;   --------------------------------------------------------------
;   The mapping from keys to shop interaction routines
;   --------------------------------------------------------------

SHOP_INTER_TABLE:
    db K_J, 0
    dw shop_left
    db K_K, 0
    dw shop_right
    db K_J, K_SHIFT
    dw move_left
    db K_K, K_SHIFT
    dw move_right
    db K_S, 0
    dw shop_sell
    db K_M, 0
    dw shop_merge_left
    db K_1, 0
    dw shop_buy_animal0
    db K_2, 0
    dw shop_buy_animal1
    db K_3, 0
    dw shop_buy_animal2
    db K_4, 0
    dw shop_buy_animal3

    db K_9, 0
    dw shop_buy_perk0
    db K_0, 0
    dw shop_buy_perk1
    db K_F, 0
    dw shop_freeze
    db K_R, 0
    dw shop_roll
    db 0

shop_left:
    ld a,(IX+CAN_LEFT)
    or a
    jr z,.ret
    dec (IX+SHOP_SELECT_IX)
.ret:
    ret
shop_right:
    ld a,(IX+CAN_RIGHT)
    or a
    jr z,.ret
    inc (IX+SHOP_SELECT_IX)
.ret:
    ret
move_left:
    ld a,(IX+CAN_LEFT)
    or a
    jr z,.ret
    dec (IX+SHOP_SELECT_IX)
.ret:
    ret
move_right:
    ld a,(IX+CAN_RIGHT)
    or a
    jr z,.ret
    inc (IX+SHOP_SELECT_IX)
.ret:
    ret
shop_sell:
    ret
shop_merge_left:
    ret
shop_buy_animal0:
    ret
shop_buy_animal1:
    ret
shop_buy_animal2:
    ret
shop_buy_animal3:
    ret
shop_buy_perk0:
    ret
shop_buy_perk1:
    ret
shop_freeze:
    ret
shop_roll:
    ld a,(IX+CAN_ROLL)
    or a
    jr z,.ret
    call shop_generate
    call shop_display_animals
    ld a,(ix+MONEY-GLOBALS)
    dec a
    ld (ix+MONEY-GLOBALS),a
    call display_status
.ret
    ret

;   --------------------------------------------------------------
;   Execute routine in bc
;   --------------------------------------------------------------
execbc:
    push bc
    pop hl
;   --------------------------------------------------------------
;   Execute routine in hl
;   --------------------------------------------------------------
exechl:
    jp (hl)



;   --------------------------------------------------------------
;   Shop Loop
;   --------------------------------------------------------------
;   Displays the shop and runs the user interactions until
;   end game
;   --------------------------------------------------------------

shop_loop:
    call display_shop_bg
    call display_status
    call shop_display_animals

    ld a,0
    ld IX,GLOBALS
    ld (IX+SHOP_SELECT_IX),a

.loop:
    call init_shop_inter
    call compute_shop_inter
    call update_shop_inter

    call read_keys
        ;   E => exit shop
    ld a,K_E
    call check_key
    jr z,.end

    ld hl,SHOP_INTER_TABLE

.keyloop
    ld a,(hl)
    cp 0
    jr z,.loop
    inc hl
    call check_key
    jr nz,.skip3

    ld a,(hl)
    inc hl
    or a
    jr z,.checknoshift

    call check_key
    jr nz,.skip2
    jr .exec

.checknoshift:
    ld a,(KEYS+7)
    inc a
    jr nz,.skip2

.exec:
    push bc

        ;   Wait key up
    push hl
    push ix
    call wait_key_up
    pop ix
    pop hl

    pop bc

    ld c,(hl)
    inc hl
    ld b,(hl)
    inc hl
    push hl
    call execbc
    pop hl
    jr .loop            ; we executed something

.skip3:
    inc hl
.skip2:
    inc hl
    inc hl
    jr .keyloop

.end:
    ret

;   --------------------------------------------------------------
;   Initialize the game
;   --------------------------------------------------------------

game_init:
        ;   Money, lifes, score
    ld de,PLAYER_BASE
    ld hl,PLAYER_BASE_INIT
    ld bc,3
    ldir
        ;   Level
    ld a,0
    ld (TURN),a
    ret

PLAYER_BASE_INIT:
    db 10,5,0

;   --------------------------------------------------------------
;   Initialize the shop according to current level
;   --------------------------------------------------------------
shop_init:
    call shop_generate
    ret

;   --------------------------------------------------------------
;   Generate shop content
;   --------------------------------------------------------------
shop_generate:
    ld hl,SHOP_ANIMALS
    ld b,3
.loop:
    call shop_random_animal
    ld (hl),a
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    djnz .loop
    ret

;   --------------------------------------------------------------
;   Generates a random shop animal in a
;   --------------------------------------------------------------

ANIMALS_BY_TURN:
    db 4, 4, 6, 6, 8, 8, 10, 10, 12, 12, 14, 14, 16, 16, 16
POWERS_BY_TURN:
    db 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 8, 8, 8
;   
shop_random_animal:
    push bc
    push hl
    ld bc,(TURN)
    ld hl, ANIMALS_BY_TURN
    add hl,bc
    ld a,(hl)
    call random_less
    pop hl
    pop bc
    ret

;   --------------------------------------------------------------
;   Display the animals in the shop
;   --------------------------------------------------------------
shop_display_animals:
    ld b,3
    ld hl,SHOP_ANIMALS
    ld d,1
.loop:
    ld a,(hl)
    ld e,17
    call draw_sprite
    inc hl

    inc d
    inc d

        ; display health
    ld c,(hl)
    push hl
    ld e,23
    call display_adrs_from_de
    ld a,c
    call print_nn
    ld (hl),212     ; draw red heart
    call scr2col
    ld (hl),18
    pop hl
    inc hl

        ; display attack
    ld c,(hl)
    push hl
    ld e,24
    call display_adrs_from_de
    ld a,c
    call print_nn
    ld (hl),9     ; draw blue sword
    call scr2col
    ld (hl),66
    pop hl
    inc hl

    inc hl
    inc hl

    inc d
    inc d
    inc d

    djnz .loop
    ret

draw_animal:
    call draw_sprite
    ret

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
    or a
    jr z,.end
 .loop:
    call display_with_color
    djnz .loop
.end
    ret

;   --------------------------------------------------------------
;   Displays one character with specific background
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
;   check_key : checks if a key is pressed
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
;   wait_key_up : wait for all keys to be up
;   --------------------------------------------------------------

wait_key_up:
        ;   Read keyboard
    call read_keys

        ;   Check all keys are at $FF but the last row (shif+control)
    ld hl,KEYS
    ld b,8-1
.loop:
    ld a,(hl)
    inc hl
    inc a   ; destructive cp $ff
    jr nz,wait_key_up
    djnz .loop

        ;   All keys (beside shift and control) are $FF
    ret

;   --------------------------------------------------------------

;   --------------------------------------------------------------

print_msg:
    ld d,(hl)       ; x
    inc hl
    ld e,(hl)       ; y
    inc hl
    push hl
    call display_adrs_from_de
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

; playmusic:
; input
;    hl : points on a music table (pitch,duration), terminated by a zero
playmusic:
    ld a,(hl)
    inc hl
    cp $ff
    jr z,.end

    cp $0
    jr nz,.skip1
    
    ld bc,1000
    ld d,h
    ld e,l
    push hl
    ldir
    pop hl
    jr playmusic

.skip1:
    cp $1
    jr nz,.skip2

    ld bc,10000
    ld d,h
    ld e,l
    push hl
    ldir
    pop hl
    jr playmusic

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
    jr playmusic
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
    jr nz,.loop1

    dec e                  ; duration--
    jr nz,.loop

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
.loop:
    jr .loop


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
    jr main

    include "splash.inc"
    include "title.inc"
    include "shop.inc"

    include "sprites.inc"
    include "sample.inc"

;   --------------------------------------------------------------
;   Read all keys into the 8 byte KEYS buffer 
;   --------------------------------------------------------------
;   #### remove print_binary call 
read_keys:
.loop
    push ix
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

;    call print_binary
    ld bc,40-8
    add hl,bc

    pop bc

    ld a,d                  ; move mask 1 left (mask has a single 0)
    rl a
    or a,1
    ld d,a

    djnz .loop1
    pop ix
    ret

; print_binary: prints the content of 'a' in binary in (hl)
; increments hl
; destroys: a,b,c
print_binary:
    ld b,8
.loop:
    bit 7,a
    ld c,'0'
    jr z,.print0
    inc c
.print0:
    ld (hl),c
    inc hl
    rl a
    djnz .loop
    ret

    include "display.asm"
    include "utils.asm"

    org 0ffffh
    db 1


