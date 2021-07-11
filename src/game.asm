SECTION "Main Game", ROM0
;----------------------------------------------------------------------------
; Initialization Routine for the Main Game
;----------------------------------------------------------------------------
InitGame:
    ;----------------------------------------------------------------------------
    ; Basic Initialization

    ; Initialize Palettes
    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP0], a
    cpl
    ldh [rOBP1], a

    ; Set to Bank 1 for Graphics Data
    xor a
    ld [rROMB1], a
    inc a
    ld [rROMB0], a

    ;----------------------------------------------------------------------------
    ; Load Tile Data into VRAM

    ; Load Font into VRAM
    ld hl, $9210
    ld de, Fontset
    ld bc, EndFontset - Fontset
    call Memcpy

    ; Load BG Tiles into VRAM
    ld hl, $9000
    ld de, GameTilesBG
    ld bc, EndGameTilesBG - GameTilesBG
    call Memcpy

    ; Load Sprite & Window Tiles into VRAM
    ld hl, $8010
    ld de, GameTilesSpritesWindow
    ld bc, EndGameTilesSpritesWindow - GameTilesSpritesWindow
    call Memcpy

    ;----------------------------------------------------------------------------
    ; Initialize (Shadow) OAM

    ; Clear out shadow OAM
    ld hl, wShadowOAM
    ld bc, OAM_COUNT * 4
    ld d, $00
    call Memset

    ; Transfer Shadow OAM to real OAM
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    jr @



SECTION "Shadow OAM", WRAM0, ALIGN[8]
wShadowOAM::
    ds OAM_COUNT * 4



SECTION "Ingame Graphics", ROMX, BANK[1]

GameTilesBG:
INCBIN "gfx/numbers.2bpp"
INCBIN "gfx/score.2bpp"
INCBIN "gfx/combo.2bpp"
EndGameTilesBG:

GameTilesSpritesWindow:
INCBIN "gfx/circle.2bpp"
INCBIN "gfx/drums.2bpp"
INCBIN "gfx/miss.2bpp"
INCBIN "gfx/okay.2bpp"
INCBIN "gfx/great.2bpp"
INCBIN "gfx/perfect.2bpp"
EndGameTilesSpritesWindow: