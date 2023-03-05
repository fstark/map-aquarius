;   --------------------------------------------------------------
;   Include file containing code related to display
;   --------------------------------------------------------------

SPRITE_WIDTH = 5
SCREEN_WIDTH = 40

SCREENBASE = $3000
COLOR_OFFSET = $0400
COLORBASE = SCREENBASE+COLOR_OFFSET

;   --------------------------------------------------------------
;   Erase rectangle (d,e)-(d+b,e+c) using content of first column
;   --------------------------------------------------------------

erase_rect:
    call display_adrs_from_de
        ; hl contains screen address of destination
    push hl
    ld d,0
    call display_adrs_from_de
        ; hl contains screen address of line start
    pop de

erase_rect_adrs:
    push bc
    push hl
    push de
    call erase_rect_adrs1
    ld bc,COLOR_OFFSET
    pop hl
    add hl,bc
    push hl
    pop de
    pop hl
    add hl,bc
    pop bc
;   erase with the start of the line at (hl) at (de) into b col and c lines
erase_rect_adrs1:
    push bc
    push de
    ld a,(hl)

    ld a,$55
.loop
    ld (de),a
    inc de
    djnz .loop
    pop de

    ld b,0
    ld c,SCREEN_WIDTH
    add hl,bc
    ex de,hl
    add hl,bc
    ex de,hl
    pop bc

    dec c
    jp nz,erase_rect_adrs1

    ret


;   --------------------------------------------------------------
;   display_cscreen: unpacks into SCREENBASE and COLORBASE
;   input: hl = address of compressed screen data (SCR+COL)
;   --------------------------------------------------------------
display_cscreen:
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

;   --------------------------------------------------------------
;   Sets SCR and COL store function
;   de = SCR store
;   bc = COL store
;   --------------------------------------------------------------
display_set_store_func:
    ld hl,PXL_SCR_STORE
    ld (hl),e
    inc hl
    ld (hl),d
    inc hl      ;   PXL_COL_STORE
    ld (hl),c
    inc hl
    ld (hl),b
    ret

display_copy:
    ld a,0
    ld (PXL_DELTA),a
    ld a,SCREEN_WIDTH-SPRITE_WIDTH
    ld (PXL_STRIDE),a

    ld de,pxl_copy
    ld bc,pxl_copy
    jr display_set_store_func

display_mask:
    ld a,0
    ld (PXL_DELTA),a
    ld a,SCREEN_WIDTH-SPRITE_WIDTH
    ld (PXL_STRIDE),a

    ld de,pxl_copy
    ld bc,col_copy_mask
    jr display_set_store_func

display_copy_rev:
    ld a,SPRITE_WIDTH-1
    ld (PXL_DELTA),a
    ld a,SCREEN_WIDTH+SPRITE_WIDTH
    ld (PXL_STRIDE),a

    ld de,pxl_revert_copy
    ld bc,pxl_copy
    jr display_set_store_func

display_mask_rev:
    ld a,SPRITE_WIDTH-1
    ld (PXL_DELTA),a
    ld a,SCREEN_WIDTH+SPRITE_WIDTH
    ld (PXL_STRIDE),a

    ld de,pxl_revert_copy
    ld bc,col_copy_mask
    jr display_set_store_func

;   --------------------------------------------------------------
;   Just copies the pixel or color
;   --------------------------------------------------------------
pxl_copy:
    ld (de),a
    ret

;   --------------------------------------------------------------
;   Invert chat and copies
;   --------------------------------------------------------------
pxl_revert_copy:
    push af
    call invert_char
    ld (de),a
    pop af
    ret

;   --------------------------------------------------------------
;   Merge the color, treating light blue as transparent
;   Changes no registers
;   --------------------------------------------------------------
col_copy_mask:
    push bc
    ld b,a
    and $0f
    cp 6            ;   Light blue
    ld a,b
    jp nz,.cont
    and $f0
    ld c,a
    ld a,(de)
    and $0f
    or c           ;   Keep the original background color
.cont:
    ld (de),a
    ld a,b
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
    add hl,bc   ; hl is address in sprite table
    ld c,(hl)
    inc hl
    ld b,(hl)
    push bc
    pop hl      ; hl is address of sprite
    call draw_sprite_hl
    pop hl
    pop de
    pop bc
    ret

;   --------------------------------------------------------------
;   Convert (de) into a screen address.
;   Need to add COLOR_OFFSET for color address.
;   --------------------------------------------------------------
; input:
;   d = x (0-39)
;   e = y (1-24)
; output
;   hl = screen adrs
;   --------------------------------------------------------------
display_adrs_from_de:
    push bc
    push de
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
    pop de
    pop bc
    ret

;   --------------------------------------------------------------
;   draw_sprite_hl: draws a compressed sprite
;   hl : sprite source
;   de : x,y coordinates
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
    add hl,bc           ; Screen destination
    push hl
    pop de              ; de = hl
    pop hl

        ;   unpacks hl in to de
    push de
    call display_set_pxl_scr_func
    ld b,SPRITE_WIDTH
    call unpack_sprite
    pop de

        ;   de += 0x400
    ld a,d
    ccf
    add a,4     ; Adds 4*256 for color
    ld d,a

    call display_set_pxl_col_func
    ld b,SPRITE_WIDTH
    jr unpack_sprite


;   --------------------------------------------------------------
;   Upacks hl into de, width 'b'
;   --------------------------------------------------------------

unpack_sprite:
    ld c,SPRITE_WIDTH
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

; don't change a, b and c
putpixel:
        ;   Do the pixel transfer function
    call PXL_STORE_FUNC

        ;   Hack: if PXL_DELTA==0 we increment de, else we DECREMENT de
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

        ;   c = column
    dec c
    ret nz

        ;   Go to next line (de+=(PX_STRIDE),c=SPRITE_WIDTH)
    push af
    push hl
    push de
    pop hl
    ld d,0
    ld a,(PXL_STRIDE)
    ld e,a
    add hl,de
    push hl
    pop de
    pop hl
    ld c,SPRITE_WIDTH
    pop af
    ret



; Reverse char bloc
; 1010 0100
;  a b cdef
;  b a dcfe
; 1010 1000

invert_char:
    bit 7,a     ;   Don't invert 1x1x xxxx
    ret z
    bit 5,a
    ret z

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

;   --------------------------------------------------------------
;   TO BE REMOVED
;   --------------------------------------------------------------


WINOFFSETL = $3900
WINOFFSETH = $3901


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

;   --------------------------------------------------------------
;   Displays the A register in decimal in hl
;   --------------------------------------------------------------
print_nn:
    push bc
    ld c,a
.loop:
    cp a,10
    jp c,.done
    inc b
    sub a,10
    jr .loop
.done:
    ld c,a
    ld a,b
    add a,'0'
    ld (hl),a
    inc hl
    ld a,c
    add a,'0'
    ld (hl),a
    inc hl
    pop bc
    ret

scr2col:
    ld a,h
    xor a,04
    ld h,a
    ret
