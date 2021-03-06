;----------------------------------------------------------------------------
; Macro & Constant Definitions
;----------------------------------------------------------------------------
MACRO FullPtr
    db LOW(BANK(\1)), LOW(\1), ((HIGH(BANK(\1)) << 7) | HIGH(\1))
ENDM

MACRO String
    db \1, 0
ENDM

DEF SongEntryCounter = 0
MACRO SongEntry
    FullPtr \1
    FullPtr \2
    FullPtr \3
    FullPtr \4
    FullPtr \5
    String \6
    String \7
    PRINTLN "Song {SongEntryCounter}: \6 by \7"
    REDEF SongEntryCounter = SongEntryCounter + 1
ENDM

;----------------------------------------------------------------------------
; Mapset Table
;----------------------------------------------------------------------------
SECTION "Mapset Table", ROM0

; Format:        SongEntry <song_ident>, <easy_map_ptr>, <medium_map_ptr>, <hard_map_ptr>, <extreme_map_ptr>, <song_title>,          <artist_name>
MapsetTotaka:    SongEntry totaka,       TotakaEasy,     NULL,             NULL,           NULL,              "Totaka's Song",       " Kazumi Totaka"
MapsetBday:      SongEntry birthday,     NULL,           NULL,             NULL,           NULL,              "Happy Birthday",      " Someone Maybe idk"
MapsetMoonlight: SongEntry moonlight,    NULL,           NULL,             NULL,           NULL,              "Moonlight Sonata",    " Beethoven"
MapsetDummy2:    SongEntry totaka,       NULL,           NULL,             NULL,           NULL,              "Renzokuken",          " HERO DIES FIRST"
MapsetDummy3:    SongEntry totaka,       NULL,           NULL,             NULL,           NULL,              "Dummy Song D",        " Dummy Artist D"
MapsetDummy4:    SongEntry totaka,       NULL,           NULL,             NULL,           NULL,              "Dummy Song E",        " Dummy Artist E"
MapsetDummy5:    SongEntry totaka,       NULL,           NULL,             NULL,           NULL,              "Dummy Song F",        " Dummy Artist F"
MapsetDummy6:    SongEntry totaka,       NULL,           NULL,             NULL,           NULL,              "Dummy Song G",        " Dummy Artist G"

; Pointer Table to song headers in the list above. Songs will be displayed in the same order as in the table,
; any songs in the list above must also be added here to be visible at all.
MapsetTable:
    dw MapsetTotaka
    dw MapsetBday
    dw MapsetMoonlight
    dw MapsetDummy2
    dw MapsetDummy3
    dw MapsetDummy4
    dw MapsetDummy5
    dw MapsetDummy6