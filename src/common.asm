;----------------------------------------------------------------------------
; Common Constant Definitions
;----------------------------------------------------------------------------
DEF BTN_A       EQU $01
DEF BTN_B       EQU $02
DEF BTN_SELECT  EQU $04
DEF BTN_START   EQU $08
DEF BTN_DPAD_R  EQU $10
DEF BTN_DPAD_L  EQU $20
DEF BTN_DPAD_U  EQU $40
DEF BTN_DPAD_D  EQU $80

SECTION "Common Routines", ROM0
;----------------------------------------------------------------------------
; Input:
;  BC - Amount of bytes to copy
;  DE - Pointer to Source
;  HL - Pointer to Destination
;----------------------------------------------------------------------------
Memcpy:
    ld a, [de]
    inc de
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

;----------------------------------------------------------------------------
; Input:
;  BC - Amount of bytes to copy
;  D  - Value to set memory region to
;  HL - Pointer to Destination
;----------------------------------------------------------------------------
Memset:
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memset
    ret

;----------------------------------------------------------------------------
; Input:
;  DE - Pointer to String
;  HL - Pointer to Destination
;----------------------------------------------------------------------------
Strcpy::
    ld a, [de]
    inc de
    ld [hli], a
    and a
    ret z
    jr Strcpy

;----------------------------------------------------------------------------
; Input:
;  HL - Pointer Memory Address
;
; Output:
;  HL - Resulting memory address
;  ROM Bank Number set automatically
;  Trashes BC
;----------------------------------------------------------------------------
GetPointerAbs::
    ; Set lower ROM Bank byte
    ld a, [hli]
    ld [rROMB0], a

    ; Fetch Low Address Byte
    ld a, [hli]
    ld b, a

    ; Fetch High Address Byte & High ROM Bank Bit then return
    ld a, [hl]
    sla a
    ld h, a
    ld a, $01
    jr c, .highBitSet
    dec a
.highBitSet
    ld [rROMB1], a
    srl h
    ld l, b               ; Preserved from previous fetch
    ret

;----------------------------------------------------------------------------
; Input:
;  DE - Pointer to Tilemap Data
;  HL - Pointer to VRAM
;----------------------------------------------------------------------------
LoadTilemap:
    ld a, [de]
    and a
    ret z
    inc de
    ld b, a
    ld a, [de]
    inc de
.loadLoop
    ld [hli], a
    dec b
    jr nz, .loadLoop
    jr LoadTilemap

;----------------------------------------------------------------------------
; Fetches the input state to the two corresponding HRAM addresses
;----------------------------------------------------------------------------
FetchInput:
    ; Fetch D-Pad State
    ld c, LOW(rP1)
	ld a, $20
	ldh [c], a
REPT 6
	ldh a, [c]
ENDR
	or $F0
	ld b, a
	swap b

    ; Fetch Button State
	ld a, $10
	ldh [c], a
REPT 6
    ldh a, [c]
ENDR
	and $0F
	or $F0
	xor b
	ld b, a

	; Release joypad
	ld a, $30
	ldh [c], a

    ; Update HRAM Variables & return
	ldh a, [hHeldKeys]
	cpl
	and b
	ldh [hPressedKeys], a
	ld a, b
	ldh [hHeldKeys], a
    ret

;----------------------------------------------------------------------------
; OAM DMA Routine, should be copied to HRAM
;----------------------------------------------------------------------------
OAMDMA:
	ldh [rDMA], a
	ld a, OAM_COUNT
.wait
	dec a
	jr nz, .wait
	ret
.end



SECTION "STAT Handler", ROM0
HandleSTAT:
    ; Preserve Registers
    push af
    push bc
    push de
    push hl

    ; Set A = 2*hIndexSTAT
    ldh a, [hIndexSTAT]
    add a

    ; Fetch pointer and jump
    ld hl, STATHandleTable
    add a, l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hli]
    ld d, a
    ld h, [hl]
    ld l, d
    jp hl

STATHandleTable:
    dw SongMenu_FlipBGP_STAT
    dw SongMenu_ToggleWindow_STAT

; Table Index EQUs
DEF STATR_FLIP_BGP_MENU    EQU $00
DEF STATR_FLIP_WIN_EN_MENU EQU $01



SECTION "Common HRAM", HRAM
hOAMDMA: ds OAMDMA.end - OAMDMA

; Button order: Down, Up, Left, Right, Start, select, B, A
hHeldKeys: db
hPressedKeys: db

hIndexSTAT: db



SECTION "Shared Graphics", ROMX, BANK[1]

Fontset:
INCBIN "gfx/alphabet_symbols1.2bpp"
INCBIN "gfx/alphabet_numbers.2bpp"
INCBIN "gfx/alphabet_symbols2.2bpp"
INCBIN "gfx/alphabet_caps.2bpp"
INCBIN "gfx/alphabet_symbols3.2bpp"
INCBIN "gfx/alphabet_low.2bpp"
INCBIN "gfx/alphabet_symbols4.2bpp"
EndFontset:

CommonTiles:
INCBIN "gfx/separator.2bpp"
EndCommonTiles: