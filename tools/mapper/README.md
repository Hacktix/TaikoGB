# TaikoGB mapper

## Requirements
You need pygame 2.0 or higher, pygame-menu 4.1.3 (that's the tested version) and mutagen 1.45.1 (once again the tested version)

## Keybinds
| Key               | Function                                    |
|-------------------|---------------------------------------------|
|Scrollwheel up/down|Scroll / change object position in edit mode |
|Hold Left shift    |Medium scroll speed                          |
|Hold Left control  |Slow scroll speed                            |
|Space              |Start / stop song                            | 
|N                  |Add object to left lane                      |
|M                  |Add object to right lane                     |
|A                  |Edit mode (selects closes visible object)    |
|E                  |Export map                                   |
|Delete             |Deletes selected object in edit mode         |
|Home               |Jump to the beginning of the map             |
|End                |Jump to the end of the map                   |

## Usage
`mapper.py` needs to be in the base folder, which also contains folders `songs` and `output`.
Copy all the songs you want to map into the `songs` folder, so they will show up in the mapper.

Run `mapper.py` to start the mapper, select the desired song from the dropdown menu and click `Start mapping`.

After exporting the map, the exported `songname.tgb` file will be placed into the `output` folder.