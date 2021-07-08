;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------
DEF LY_SELECT   EQU $34
DEF SEL_HEIGHT  EQU 24
DEF MENU_SCX    EQU -14

SECTION "Song Menu", ROM0
;----------------------------------------------------------------------------
; Initialization Routine for the Song Selection Menu
;----------------------------------------------------------------------------
InitMenu:
    ; Initialize Palettes
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    ldh [rOBP1], a

    ; Clear VRAM
    ld hl, $8000
    ld bc, $4000
    ld d, 0
    call Memset

    ; Set to Bank 1 for Graphics Data
    xor a
    ld [rROMB1], a
    inc a
    ld [rROMB0], a

    ; Load Font into VRAM
    ld hl, $8410
    ld de, FontUppercase
    ld bc, EndFontUppercase - FontUppercase
    call Memcpy
    ld hl, $8610
    ld de, FontLowercase
    ld bc, EndFontLowercase - FontLowercase
    call Memcpy

    ; Load cursor into VRAM
    ld hl, $8010
    ld de, TaikoCursor
    ld c, EndTaikoCursor - TaikoCursor
    rst MemcpySmall

    ; Clear OAM
    ld hl, _OAMRAM
    ld bc, OAM_COUNT*4
    ld d, $00
    call Memset

    ; Load OAM with required data
    ld hl, _OAMRAM
    ld de, SongMenuOAM
    ld c, EndSongMenuOAM - SongMenuOAM
    rst MemcpySmall

    ; Initialize PPU Registers
    ld a, MENU_SCX
    ldh [rSCX], a
    xor a
    ldh [rSCY], a
    ld a, STATF_LYC
    ldh [rSTAT], a
    ld a, LY_SELECT - 1
    ldh [rLYC], a

    ; TODO: Remove Debug Data
    ld hl, $98E0
    ld de, str1
    call Strcpy
    ld hl, $9900
    ld de, str2
    call Strcpy
    ld hl, $9940
    ld de, str3
    call Strcpy
    ld hl, $9960
    ld de, str4
    call Strcpy

    ; Initialize Interrupts & LYC
    xor a
    ldh [rIF], a
    ldh [hIndexSTAT], a           ; Set STAT Handler to $00 (= FlipBGP_STAT)
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    ei

    ; Initialize LCD and Loop
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON
    ldh [rLCDC], a

;----------------------------------------------------------------------------
; Main Loop for the Song Selection Menu Game State
;----------------------------------------------------------------------------
SongMenuLoop:
    halt
    jr SongMenuLoop

;----------------------------------------------------------------------------
; Song Selection Menu STAT Handlers
;----------------------------------------------------------------------------
SongMenu_FlipBGP_STAT:
    ; Wait for HBlank
    ld a, [rSTAT]
    and STATF_BUSY
    jr nz, SongMenu_FlipBGP_STAT

    ; Flip BGP Bits
    ldh a, [rBGP]
    cpl 
    ldh [rBGP], a

    ; Update LYC
    ldh a, [rLYC]
    add SEL_HEIGHT
    cp LY_SELECT + 2*SEL_HEIGHT - 1
    jr nz, .noSkipOverflow
    sub 2*SEL_HEIGHT
.noSkipOverflow
    ldh [rLYC], a

    ; Restore Registers & Return
    pop hl
    pop de
    pop bc
    pop af
    reti



SECTION "Song Menu Graphics", ROMX, BANK[1]

TaikoCursor:
INCBIN "gfx/taiko.2bpp"
EndTaikoCursor:

SongMenuOAM:
db LY_SELECT + (SEL_HEIGHT/2) + 12, $0A, $01, $00
EndSongMenuOAM:

str1: db "Totakas Song", 0
str2: db "Kazumi Totaka", 0
str3: db "Another Song", 0
str4: db "Another Artist", 0