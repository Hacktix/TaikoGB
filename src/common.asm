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

; Table Index EQUs
DEF STATR_FLIP_BGP_MENU EQU $00



SECTION "Common HRAM", HRAM
hIndexSTAT: db



SECTION "Shared Graphics", ROMX, BANK[1]

FontUppercase:
INCBIN "gfx/alphabet_caps.2bpp"
EndFontUppercase:

FontLowercase:
INCBIN "gfx/alphabet_low.2bpp"
EndFontLowercase: