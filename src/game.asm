;----------------------------------------------------------------------------
; Constant Definitions
;----------------------------------------------------------------------------
DEF WX_NOTE_LANE EQU 100

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
    ; Load Window Tilemap

    ; Initially Clear Tilemaps
    ld hl, $9800
    ld bc, $A000-$9800
    ld d, 0
    call Memset

    ; Load Note Lane Tiles
    ld hl, $9800
    ld c, $0D
.noteLaneLoad
    ld de, NoteLaneTilemap
    call LoadTilemap
    dec c
    jr nz, .noteLaneLoad

    ; Load Taiko Tiles
    ld de, TaikoTilemap
    call LoadTilemap

    ;----------------------------------------------------------------------------
    ; Load Background Tilemap

    ; Load Score Label
    ld hl, $9C00
    ld b, 3
    ld a, $94
.scoreLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .scoreLabelLoad

    ; Load Points Label
    ld hl, $9C20
    ld de, $9C40
    ld a, $80
    ld b, 8
.pointLabelLoad
    ld [hli], a
    add $0A
    ld [de], a
    inc de
    sub $0A
    dec b
    jr nz, .pointLabelLoad

    ; Load Combo Label
    ld hl, $9E00
    ld b, 4
    ld a, $97
.comboLabelLoad
    ld [hli], a
    inc a
    dec b
    jr nz, .comboLabelLoad
    ld hl, $9DC0
    ld [hl], $80
    ld hl, $9DE0
    ld [hl], $8A

    ;----------------------------------------------------------------------------
    ; Load Tile Data into VRAM

    ; Load BG Tiles into VRAM
    ld hl, $8800
    ld de, GameTilesBG
    ld bc, EndGameTilesBG - GameTilesBG
    call Memcpy

    ; Load Sprite & Window Tiles into VRAM
    ld hl, $8020
    ld de, GameTilesSpritesWindow
    ld bc, EndGameTilesSpritesWindow - GameTilesSpritesWindow
    call Memcpy

    ;----------------------------------------------------------------------------
    ; Initialize (Shadow) OAM

    ; Initialize Shadow OAM
    ld hl, wShadowOAM
    ld b, OAM_COUNT
    ld c, OAMF_XFLIP
.initLoopOAM
    ld a, $FF
    ld [hli], a
    inc a
    ld [hli], a
    ld a, $03
    ld [hli], a
    ld a, c
    xor OAMF_XFLIP
    ld [hli], a
    ld c, a
    dec b
    jr nz, .initLoopOAM

    ; Transfer Shadow OAM to real OAM
    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ;----------------------------------------------------------------------------
    ; Initialize Registers & Variables

    ; PPU Registers
    xor a
    ldh [rWY], a
    dec a
    ldh [rLYC], a
    ld a, WX_NOTE_LANE
    ldh [rWX], a
    ld a, -4
    ldh [rSCX], a
    ldh [rSCY], a

    ;----------------------------------------------------------------------------
    ; Initialize Interrupts & Fall through to main loop

    ; Initialize Interrupts
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

    ; Initialize LCD and Loop
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WIN9800 | LCDCF_OBJON | LCDCF_WINON | LCDCF_BG8000 | LCDCF_OBJ16
    ldh [rLCDC], a

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
INCBIN "gfx/note_lane.2bpp"
INCBIN "gfx/miss.2bpp"
INCBIN "gfx/okay.2bpp"
INCBIN "gfx/great.2bpp"
INCBIN "gfx/perfect.2bpp"
EndGameTilesSpritesWindow:

NoteLaneTilemap:
db $01, $11, $01, $00, $01, $12, $01, $00, $01, $11, $01, $00, $01, $12, $19, $00, 0

TaikoTilemap:
db $01, $04, $01, $05, $01, $06, $01, $00, $01, $04, $01, $05, $01, $06, $19, $00
db $01, $07, $01, $08, $01, $09, $01, $00, $01, $07, $01, $08, $01, $09, $19, $00
db $01, $0A, $01, $0D, $01, $0C, $01, $00, $01, $0A, $01, $0B, $01, $0C, $19, $00
db $01, $0E, $01, $0F, $01, $10, $01, $00, $01, $0E, $01, $0F, $01, $10
db 0