NAME = TAIKOGB
PADVAL = 0

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix
RGBGFX = rgbgfx

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -w -n taiko.sym
FIXFLAGS = -v -p $(PADVAL) -t $(NAME) -m 0x1b -r 0x02
GFXFLAGS = -u -v -f

INCPATH = include
IMAGES = $(shell find . -name "*.png")
SONGS = $(shell find ./music -name "*.asm")

all: $(addsuffix .2bpp, $(basename $(IMAGES))) $(addsuffix .o, $(basename $(SONGS))) taiko.gb
nogfx: $(addsuffix .o, $(basename $(SONGS))) taiko.gb
gfx: $(addsuffix .2bpp, $(basename $(IMAGES)))

%.2bpp: %.png
	$(info # Generating GFX - $@)
	@$(RGBGFX) $(GFXFLAGS) -o $@ $<

taiko.gb: hUGEDriver.o taiko.o $(addsuffix .o, $(basename $(SONGS)))
	$(info # Linking & Fixing ROM Header...)
	$(info Linking: $^)
	@$(RGBLINK) $(LDFLAGS) -o $@ $^
	@$(RGBFIX) $(FIXFLAGS) $@

music/%.o: music/%.asm
	$(info Assembling Song File: $^)
	@$(RGBASM) $(ASFLAGS) -i $(INCPATH) -o $@ $<

hUGEDriver.o: hUGEDriver.asm
	$(info # Assembling hUGEDriver...)
	@$(RGBASM) $(ASFLAGS) -i $(INCPATH) -o $@ $<

taiko.o: main.asm
	$(info # Assembling Main Game Code...)
	@$(RGBASM) $(ASFLAGS) -i $(INCPATH) -o $@ $<

.PHONY: clean
clean:
	$(info # Cleaning build files...)
	@$(RM_F) $(shell find . -name "*.sym")
	@$(RM_F) $(shell find . -name "*.o")
	@$(RM_F) $(shell find . -name "*.gb")
	$(info # Cleaning GFX...)
	@$(RM_F) $(shell find . -name "*.2bpp")
	@$(RM_F) $(shell find . -name "*.tilemap")