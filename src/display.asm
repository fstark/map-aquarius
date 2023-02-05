;   --------------------------------------------------------------
;   Include file containing code related to display
;   --------------------------------------------------------------


SCREENBASE = $3000
COLOR_OFFSET = $0400
COLORBASE = SCREENBASE+COLOR_OFFSET

;   --------------------------------------------------------------
;   display_cscreen: unpacks into SCREENBASE and COLORBASE
;   --------------------------------------------------------------
display_cscreen:
    push hl
    ld hl,SCREENBASE+40
    ld de,SCREENBASE+41
    ld (hl),134
    ld bc,COLOR_OFFSET-41
    ldir

    ld hl,COLORBASE+40
    ld de,COLORBASE+41
    ld (hl),$13
    ld bc,COLOR_OFFSET-41
    ldir
    pop hl

    ld de,SCREENBASE+40
    call unpack
    ld de,COLORBASE+40
    jr unpack

;   --------------------------------------------------------------
;   draw_sprite: draws a compressed sprite
;   a  : sprite #
;   de : x,y coordinates
;   --------------------------------------------------------------
draw_sprite:
    add a,a
    ld b,0
    ld c,a
    ld hl,SPR
    add hl,bc
    ld c,(hl)
    inc hl
    ld b,(hl)
    push bc
    pop hl
    jp draw_sprite_hl
;   --------------------------------------------------------------
;   draw_sprite_hl: draws a compressed sprite
;   hl : sprite source
;   de : x,y coordinates
;   b  : sprite width (hard coded to 5)
;   --------------------------------------------------------------

draw_sprite_hl:
    push hl
    ld h,0
    ld l,e
    push hl
    pop bc
    add hl,hl           ; *2
    add hl,hl           ; *4
    add hl,bc           ; *5
    add hl,hl           ; *10
    add hl,hl           ; *20
    add hl,hl           ; *40
    ld c,d
    add hl,bc           ; offset x
    ld bc,SCREENBASE
    add hl,bc
    push hl
    pop de              ; de = hl
    pop hl
    ld b,5
    push de
    call unpack_sprite
    pop de
    ld a,d
    ccf
    add a,4
    ld d,a
    ld b,5
    call unpack_sprite
    ret

;   --------------------------------------------------------------
;   Upacks hl into de
;   --------------------------------------------------------------
unpack:
    ; first byte
.loop:
    ld a,(hl)
    or a
    inc hl
    jr z,.end
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
    jr .loop
.copy:              ; <$80, copy operation
    ld b,0
    ld c,a
    ldir
    jr .loop
.end:
    ret

SCRATCHW = $3900    ;   width of sprite
SCRATCHS = $3901    ;   stride

:
;   --------------------------------------------------------------
;   Upacks hl into de, width 'b'
;   --------------------------------------------------------------

unpack_sprite:
    ld a,b
    ld (SCRATCHW),a
    ld a,40
    sub b
    ld (SCRATCHS),a
    ld c,b
    ; first byte
.loop:
    ld a,(hl)
    or a
    inc hl
    jr z,.end
    cp $80
    jp m,.copy
.repeat:            ;  >$80, repeat operation
    sub 126
    ld b,a
    ld a,(hl)
    inc hl
.repeat1:
    call putpixel
    dec b
    jp nz,.repeat1
    jr .loop
.copy:              ; <$80, copy operation
    ld b,a
.copy1:
    ld a,(hl)
    call putpixel
    inc hl
    dec b
    jp nz,.copy1

    jr .loop
.end:
    ret


putpixel:
    ld (de),a
    inc de
    dec c
    ret nz
    push af
    push bc
    push hl
    ld h,d
    ld l,e
    ld d,0
    ld a,(SCRATCHS)
    ld e,a
    add hl,de
    ld d,h
    ld e,l
    pop hl
    pop bc
    ld a,(SCRATCHW)
    ld c,a
    pop af
    ret

;   --------------------------------------------------------------
;   TO BE REMOVED
;   --------------------------------------------------------------


WINOFFSETL = $3900
WINOFFSETH = $3901

;   --------------------------------------------------------------
;   Upacks hl into de window
;   --------------------------------------------------------------
unpack_XXX:
    ld iy,WINOFFSETL
    ld a,10
    ld (iy+0),a
    ld a,0
    ld (iy+1),a

    ; first byte
.loop:
    ld a,(hl)
    or a
    inc hl
    jr z,.end
    cp $80
    jp m,.copy
.repeat:            ;  >$80, repeat operation
    sub 126
    ld b,a
    ld a,(hl)
    inc hl
.repeat1:

    push af
    ld a,(iy+0)
    or (iy+1)
    jr nz,.repeatskip
    pop af
    ld (de),a
    inc de
    djnz .repeat1
    jr .loop

.repeatskip:
    dec (iy+0)
    pop af
    inc de
    djnz .repeat1
    jr .loop

.copy:              ; <$80, copy operation
    ld b,0
    ld c,a

.copyloop

    ld a,(iy+0)
    or (iy+1)
    jr nz,.copyskip

    ld a,(hl)
    ld (de),a
    inc de
    inc hl
    dec c
    jr nz,.copyloop

    jr .loop

.copyskip:
    dec (iy+0)
    inc hl
    inc de
    dec c
    jr nz,.copyloop
    jr .loop

.end:
    ret



;   --------------------------------------------------------------
;   Convert (bc) into a screen address.
;   Need to add COLOR_OFFSET for color address.
;   --------------------------------------------------------------
; input:
;   b = x (0-39)
;   c = y (1-24)
; output
;   hl = screen adrs
; destroys: d,e,h,l
;   --------------------------------------------------------------
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
    add hl,de
    ld d,0
    ld e,b
    add hl,de
    ret


;   --------------------------------------------------------------
;   Wait for several vbls. Abort if space pressed
;   --------------------------------------------------------------
; wait_vbls: wait the amount of vlb in a
wait_vbls:
    ld b,a
.loop:
    call wait_vbl

    push bc
    call read_keys
    ld a,K_SPC
    call check_key
    pop bc
    jr z,.exit

    djnz .loop
.exit:
    ret    

;   --------------------------------------------------------------
;   Waits for a single VBL.
;   --------------------------------------------------------------
; wait_vbl: Wait for the vbl to be off screen
; destroys: everything
wait_vbl:
    in a,0fdh
    bit 0,a
    jr z,wait_vbl
.loop:

    in a,0fdh
    bit 0,a
    jr nz,.loop

    ret

