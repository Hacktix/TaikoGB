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
; Fetches the input state to the two corresponding HRAM addresses
;----------------------------------------------------------------------------
FetchInput:
    ; Fetch D-Pad State
    ld c, LOW(rP1)
	ld a, $20
	ldh [c], a
	ldh a, [c]
	or $F0
	ld b, a
	swap b

    ; Fetch Button State
	ld a, $10
	ldh [c], a
	ldh a, [c]
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
; Button order: Down, Up, Left, Right, Start, select, B, A
hHeldKeys: db
hPressedKeys: db

hIndexSTAT: db



SECTION "Shared Graphics", ROMX, BANK[1]

FontUppercase:
INCBIN "gfx/alphabet_caps.2bpp"
EndFontUppercase:

FontLowercase:
INCBIN "gfx/alphabet_low.2bpp"
EndFontLowercase:

CommonTiles:
INCBIN "gfx/separator.2bpp"
EndCommonTiles: