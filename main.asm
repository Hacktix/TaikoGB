INCLUDE "hardware.inc"
INCLUDE "src/strings.asm"
INCLUDE "src/maps.asm"
INCLUDE "src/songs.asm"
INCLUDE "src/common.asm"
INCLUDE "src/menu.asm"
INCLUDE "src/game.asm"

SECTION "Vectors", ROM0[0]

;----------------------------------------------------------------------------
; Input:
;  C  - Amount of bytes to copy
;  DE - Pointer to Source
;  HL - Pointer to Destination
;----------------------------------------------------------------------------
NULL:
MemcpySmall:
    ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, MemcpySmall
	ret
    ds $08 - @

_rst08:
    ds $10 - @

_rst10:
    ds $18 - @

_rst18:
    ds $20 - @

_rst20:
    ds $28 - @

_rst28:
    ds $30 - @

_rst30:
    ds $38 - @

_rst38:
    ds $40 - @

iVBlank:
    reti
    ds $48 - @

iSTAT:
    jp HandleSTAT
    ds $50 - @

iTimer:
    reti
    ds $58 - @

iSerial:
    reti
    ds $60 - @

iJoypad:
    reti 
    ds $100 - @



SECTION "Main", ROM0[$100]
    jr Main

    ds $150 - @

Main::
    ; Initially wait for VBlank
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, Main
    
    ; Turn off LCD
    xor a
    ldh [rLCDC], a

    ; Initialize Variables
    ld sp, $CFFF
    ldh [hPressedKeys], a
    ldh [hHeldKeys], a
    ldh [hSelectedSong], a

    ; Initially turn off audio
    xor a
    ldh [rAUDENA], a

    ; Initialize OAM DMA Routine in HRAM
	ld hl, OAMDMA
	ld b, OAMDMA.end - OAMDMA
    ld c, LOW(hOAMDMA)
.copyOAMDMA
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyOAMDMA

    ; Jump to initialization of next game state
    jp InitMenu