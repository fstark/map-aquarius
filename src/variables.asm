;   --------------------------------------------------------------
;   Global variables representing the game state
;   --------------------------------------------------------------

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
K_F:    equ     $45
K_E:    equ     $61


MAX_MONEY EQU 13
MAX_LIFE EQU 5
MAX_SCORE EQU 10

    ;   Allowed interactions in the shop
GLOBALS:
SHOP_INTER:     db ?,?,?,?,?,?,?,?,?,?,?
CAN_LEFT:       equ 0
CAN_RIGHT:      equ 1
CAN_MLEFT:      equ 2
CAN_MRIGHT:     equ 3
CAN_SELL:       equ 4
CAN_MERGE:      equ 5
CAN_BMERGE:     equ 6
CAN_BUYA:       equ 7
CAN_BUYP:       equ 8
CAN_FREEZE:     equ 9
CAN_ROLL:       equ 10
SHOP_INTER_COUNT: equ 11

SHOP_TOP_X equ  22
SHOP_TOP_Y equ  2

SHOP_SELECT_IX: equ 11
                db ?

PLAYER_BASE:    ; ### REDO USAGE BASED ON IX+X-GLOBALS
MONEY:
    db ?       ;   max = 13
LIFE:
    db ?        ;   max = 5
SCORE:
    db ?        ;   max = 10


;   --------------------------------------------------------------
;   Animal structure
;   00: animal type
;   01: animal level
;   02: animal health
;   03: animal attack
;   04: animal perk
SHOP_ANIMALS:
    db ?,?,?,?,?
    db ?,?,?,?,?
    db ?,?,?,?,?

; The shop (3 animals and 2 powers)
xxxSHOP:   ds 5


SCRATCH1:    db ?

; The 4 animals
TEAM:   ds 4

;   The current turn
TURN:  dw ?

; Seed of the RNG
SEED:  dw ?

; Routine used by the low-level drawing
PXL_STORE_FUNC: ds 3        ; Function to store pixels

PXL_DELTA:          db ?    ; 
PXL_STRIDE:         db ?

; Those two routines will be used for SCREEN and COLOR for sprites
PXL_SCR_STORE: ds 2         ; Routine to store the SCR
PXL_COL_STORE: ds 2         ; Routine to store the COL


;CTX_FLIP
;CTX_MASK
