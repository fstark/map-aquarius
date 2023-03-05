;   --------------------------------------------------------------
;   VARIOUS UTILITIES
;   --------------------------------------------------------------

random_init:
    ld a,12
    ld (seed),a
    ld (seed+1),a
    ret

;   --------------------------------------------------------------
;   Random between 0 and 255
;   --------------------------------------------------------------
random:
        push    hl
        push    de
        ld      hl,(SEED)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (SEED),hl
        pop     de
        pop     hl
        ret

;   --------------------------------------------------------------
;   Random between 0 and a
;   Very slow if a is small
;   --------------------------------------------------------------
random_less:
    ld b,a
.loop:
    call random
    cp a,b
    jp nc,.loop
    ret
