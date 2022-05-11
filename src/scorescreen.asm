;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------
DEF LABEL_APPEAR_DELAY EQU 30
DEF DIGIT_APPEAR_DELAY EQU 20

;----------------------------------------------------------------------------
; Visual transition from the game screen to the score screen
;----------------------------------------------------------------------------
TransitionScore:
    ; Limit to only VBlank Interrupts
    ld a, IEF_VBLANK
    ldh [rIE], a

    ; Initialize VRAM Cleaning Variables
    ld hl, $9E3F
    ld bc, $0412

    ; Halt and wait for VBlank
.scoreOutroScroll
    halt 

    ; Check if VRAM can be cleared
    dec b
    jr nz, .noClearVRAM

    ; Clear one line of tiles from VRAM
    xor a
    ld b, 32
.clearLoop
    ld [hld], a
    dec b
    jr nz, .clearLoop

    ; Update counter variables, check if at end
    ld b, 4
    dec c
    jr nz, .noClearVRAM
    jr InitScore

.noClearVRAM
    ; Decrement SCY, increment WY
    ldh a, [rSCY]
    dec a
    dec a
    ldh [rSCY], a
    ldh a, [rWY]
    inc a
    inc a
    ldh [rWY], a
    jr .scoreOutroScroll

;----------------------------------------------------------------------------
; Initialization Routine for the final score screen after the game ends
; Re-uses a lot of variables from the game state
;----------------------------------------------------------------------------
InitScore:
    ; Wait for VBlank
    ldh a, [rLY]
    cp SCRN_Y
    jr c, InitScore

    ; Turn off LCD
    xor a
    ldh [rLCDC], a

    ; Reset PPU Registers
    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    ldh [rWX], a
    ldh [rWY], a

    ; Clear Game Field
    ld hl, $9800
    ld b, 17
.clearLoop
    xor a
    ld [hli], a
    ld a, l
    and 7
    jr nz, .clearLoop
    ld a, l
    add $18
    ld l, a
    jr nc, .noClearCarry
    inc h
.noClearCarry
    dec b
    jr nz, .clearLoop

    ; Turn on LCD
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_WINOFF
    ldh [rLCDC], a

    ; Print Score Label
    ld de, strScore
    ld hl, $9821
    call PrintStringDelayed

    ; Print inital score zeros
    ld hl, $9832
    ld c, 2
.initZeroLoop
    ld b, DIGIT_APPEAR_DELAY
.initZeroDelay
    halt 
    dec b
    jr nz, .initZeroDelay
    ld [hl], NUM_TILE_BASE
    dec hl
    push hl
    ld a, l
    add $21
    jr nc, .initZeroNoCarry
    inc h
.initZeroNoCarry
    ld l, a
    ld [hl], NUM_TILE_BASE + 10
    pop hl
    dec c
    jr nz, .initZeroLoop

    ; Print actual score values
    ld d, h
    ld e, l
    ld hl, wScore
    ld c, SIZE_SCORE
    call PrintDelayedBCD

    ; Print Combo Label
    ld de, strCombo
    ld hl, $9881
    call PrintStringDelayed

    ; Print actual combo values
    ld de, $9892
    ld hl, wComboMax
    ld c, SIZE_COMBO
    call PrintDelayedBCD

    jr @

;----------------------------------------------------------------------------
; Prints a BCD number from lowest to highest digit with delays between
; each digit.
; Inputs:
;  * C  - Maximum BCD length in bytes
;  * DE - VRAM Pointer
;  * HL - BCD Pointer
;----------------------------------------------------------------------------
PrintDelayedBCD:
    ; Initial delay before first digit
    ld b, DIGIT_APPEAR_DELAY
.scorePrintDelay1
    halt
    dec b
    jr nz, .scorePrintDelay1
    ; Fetch BCD value, if $00, exit print loop
    ld a, [hl]
    and a
    ret z
    ; Print and re-adjust VRAM pointer
    call RenderBCD.renderNibble
    dec de
    dec de
    ; Print second nibble of BCD byte
    ld b, DIGIT_APPEAR_DELAY
.scorePrintDelay2
    halt
    dec b
    jr nz, .scorePrintDelay2
    ld a, [hli]
    swap a
    and $0F
    jr nz, .noCheckLeadingZero
    ; Check if next byte is 00, if so, dont print leading zero
    ld a, [hld]
    and a
    ret z
    ld a, [hli]
    swap a
.noCheckLeadingZero
    call RenderBCD.renderNibble
    dec de
    dec de
    dec c
    jr nz, PrintDelayedBCD
    ret

;----------------------------------------------------------------------------
; Prints a string, one char per frame, after a set delay.
; Requires VBlank Interrupts to be enabled.
; Inputs:
;  * DE - String Pointer
;  * HL - Destination Pointer
;----------------------------------------------------------------------------
PrintStringDelayed:
    ; Initialize delay
    ld b, LABEL_APPEAR_DELAY

    ; Wait until delay is zero
.notYetZero
    halt 
    dec b
    jr nz, .notYetZero

    ; Print characters one by one
.printDelayLoop
    ; Load character, return if null
    ld a, [de]
    inc de
    and a
    ret z

    ld [hli], a
    halt 
    jr .printDelayLoop