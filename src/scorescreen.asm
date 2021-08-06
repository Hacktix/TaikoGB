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

    ; TODO: Actually implement a score screen here

    jr @