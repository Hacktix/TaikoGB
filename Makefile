NAME = TAIKOGB
PADVAL = 0

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix
RGBGFX = rgbgfx

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -n taiko.sym
FIXFLAGS = -v -p $(PADVAL) -t $(NAME) -C
GFXFLAGS = -T -u -v -f

INCPATH = include
IMAGES = $(shell find . -name "*.png")

all: $(addsuffix .2bpp, $(basename $(IMAGES))) taiko.gb

%.2bpp: %.png
	$(info # Generating GFX - $@)
	@$(RGBGFX) $(GFXFLAGS) -o $@ $<

taiko.gb: taiko.o
	$(info # Linking & Fixing ROM Header...)
	@$(RGBLINK) $(LDFLAGS) -o $@ $^
	@$(RGBFIX) $(FIXFLAGS) $@

taiko.o: main.asm
	$(info # Assembling Main Game Code...)
	@$(RGBASM) $(ASFLAGS) -i $(INCPATH) -o $@ $<

.PHONY: clean
clean:
	$(info # Cleaning build files...)
	@$(RM_F) taiko.o taiko.gb taiko.sym
	$(info # Cleaning GFX...)
	@$(RM_F) $(shell find . -name "*.2bpp")
	@$(RM_F) $(shell find . -name "*.tilemap")