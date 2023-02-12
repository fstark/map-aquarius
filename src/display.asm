;   --------------------------------------------------------------
;   Include file containing code related to display
;   --------------------------------------------------------------

SPRITE_WIDTH = 5

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

; #### Better way to do draw_sprite stuff:
; blit_set_direction
; blit_set_transparent
;   BLT_COPY_SCR
;   BLT_COPY_COL
;   BLT_BG_COL

display_init:
    ld a,$C3    ;   JMP opcode
    ld (PXL_STORE_FUNC),a

    call display_mask_rev
    ret

;   Function to display the pixel for SCR
display_set_pxl_scr_func:
    ld a,(PXL_SCR_STORE)
    ld (PXL_STORE_FUNC+1),a
    ld a,(PXL_SCR_STORE+1)
    ld (PXL_STORE_FUNC+2),a
    ret

;   Function to display the pixel for COL
display_set_pxl_col_func:
    ld a,(PXL_COL_STORE)
    ld (PXL_STORE_FUNC+1),a
    ld a,(PXL_COL_STORE+1)
    ld (PXL_STORE_FUNC+2),a
    ret

display_set_store_func:
    ld hl,PXL_SCR_STORE
    ld (hl),e
    inc hl
    ld (hl),d
    inc hl
    ld (hl),c
    inc hl
    ld (hl),b
    ret

display_copy:
    ld a,0
    ld (PXL_INIT_OFFSET),a
    ld (PXL_DELTA),a
    ld a,35
    ld (PXL_STRIDE),a

    ld de,pxl_copy
    ld bc,pxl_copy
    jr display_set_store_func

display_mask:
    ld a,0
    ld (PXL_INIT_OFFSET),a
    ld (PXL_DELTA),a
    ld a,35
    ld (PXL_STRIDE),a

    ld de,pxl_copy
    ld bc,col_copy_mask
    jr display_set_store_func

display_copy_rev:
    ld a,5
    ld (PXL_INIT_OFFSET),a
    ld (PXL_DELTA),a
    ld a,45
    ld (PXL_STRIDE),a

    ld de,pxl_revert_copy
    ld bc,pxl_copy
    jr display_set_store_func

display_mask_rev:
    ld a,5
    ld (PXL_INIT_OFFSET),a
    ld (PXL_DELTA),a
    ld a,45
    ld (PXL_STRIDE),a

    ld de,pxl_revert_copy
    ld bc,col_copy_mask
    jr display_set_store_func

;   --------------------------------------------------------------
;   Just copies the pixel or color
;   --------------------------------------------------------------

pxl_copy:
col_copy:
    ld (de),a
    ret
pxl_revert_copy:
    push af
    call invert_char
    ld (de),a
    pop af
    ret

;   --------------------------------------------------------------
;   Merge the color, treating light blue as transparent
;   --------------------------------------------------------------
col_copy_mask:
    push bc
    ld b,a
    and $0f
    cp 6            ;   Light blue
    jp nz,.cont
    ld a,b
    and $f0
    ld a,(de)
    and $0f
    and b           ;   Keep the original background color
    ld (de),a
    pop bc
    ret
.cont:
    ld (de),a
    pop bc
    ret



;   --------------------------------------------------------------
;   draw_sprite: draws a compressed sprite
;   a  : sprite #
;   de : x,y coordinates
;   pixel-level functions needs to be set before calling
;   --------------------------------------------------------------
draw_sprite:
    push bc
    push de
    push hl
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
    call draw_sprite_hl
    pop hl
    pop de
    pop bc
    ret

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
    ld a,(PXL_DELTA)
    add a,d
    ld c,a
    add hl,bc           ; offset x
    ld bc,SCREENBASE
    add hl,bc
    push hl
    pop de              ; de = hl
    pop hl
    ld b,5
    push de

    exx
;    ld de,pxl_copy
;    ld de,pxl_revert_copy
;    call display_set_pxl_func
    call display_set_pxl_scr_func
    exx

    call unpack_sprite
;    call unpack_sprite2
    pop de
    ld a,d
    ccf
    add a,4
    ld d,a
    ld b,5
;    call unpack_sprite3

    exx
;    ld de,col_copy_mask
;    call display_set_pxl_func
    call display_set_pxl_col_func
    exx

    call unpack_sprite
    ret

SCRATCHW = $3900    ;   width of sprite
SCRATCHS = $3901    ;   stride

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
        ;   Do the pixel transfer function
    call PXL_STORE_FUNC
;xxx    call PXL_MOVE_FUNC
    push af
    ld a,(PXL_DELTA)
    or a
    jp nz,.cont
    inc de
    jp .cont2
.cont:
    dec de
.cont2:
    pop af

    dec c
    ret nz
    push af
    push bc
    push hl
    ld h,d
    ld l,e
    ld d,0
    ld a,(PXL_STRIDE)
    ld e,a
    add hl,de
    ld d,h
    ld e,l
    pop hl
    pop bc
    ld a,SPRITE_WIDTH
    ld c,a
    pop af
    ret


;   --------------------------------------------------------------
;   Upacks hl into de, width 'b', reversed, with graphchar revers
;   --------------------------------------------------------------

unpack_sprite2:
    ld a,b
    ld (SCRATCHW),a
    ld a,40
    add a,b
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
    push af         ; because putpixel2 is destructs
    call putpixel2
    pop af
    dec b
    jp nz,.repeat1
    jr .loop
.copy:              ; <$80, copy operation
    ld b,a
.copy1:
    ld a,(hl)
    call putpixel2
    inc hl
    dec b
    jp nz,.copy1

    jr .loop
.end:
    ret

; Reverse char bloc
; 101 00100
;  a  bcdef
;  b  adcfe
; 101 01000

invert_char:
    push bc
        ; remove bit 5
    bit 6,a
    jr z,.cont
    or a,$20        ; #### useless
    jr .cont2
.cont:
    and a,$1f
.cont2:
        ; a now contains __abcdef

    ld b,a
    and a,$15           ; 000b0d0f
    sla a               ; 00b0d0f0
    ld c,a
    ld a,b
    and a,$2a           ; 00a0c0e0
    srl a               ; 000a0c0e
    or a,c
        ; a now contains 00badcfe
    bit 5,a
    jr z,.cont3
    or a,$40
    jr .cont4
.cont3:
    and a,$1f
.cont4:
        ; a now contains _b_adcfe

    or a,$a0
        ; a now contains 1b1adcfe
    pop bc
    ret

; 10110101
; __010101
; __101010
; 11101010

putpixel2:
    call invert_char

putpixel3:  ; entry point used for colors

    call PXL_STORE_FUNC
    dec de
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
;   Upacks hl into de, width 'b', reversed
;   --------------------------------------------------------------

unpack_sprite3:
    ld a,b
    ld (SCRATCHW),a
    ld a,40
    add a,b
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
    call putpixel3
    dec b
    jp nz,.repeat1
    jr .loop
.copy:              ; <$80, copy operation
    ld b,a
.copy1:
    ld a,(hl)
    call putpixel3
    inc hl
    dec b
    jp nz,.copy1

    jr .loop
.end:
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

