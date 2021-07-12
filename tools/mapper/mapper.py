# A map editor for TaikoGB

import os, pygame, pygame_menu, pygame.freetype, time
from mutagen.mp3 import MP3

song_files = []
num_songs = 0
selected_song = 0
song_pos = 0
song_length = 0
edit_mode = False
selected_obj = 0

scroll_speed = 100

text_timer = 0
display_text = False

circ1_img = pygame.image.load('assets/circle1.png')
circ2_img = pygame.image.load('assets/circle2.png')

MUSIC_END = pygame.USEREVENT+1
pygame.init()
GAME_FONT = pygame.freetype.SysFont('Helvetica', 30)
WIDTH = 960
HEIGHT = 540
BG_COLOR = (100, 145, 10)


# The game supports 4 different approach rates defined in pixels per frame
# these rates in milliseconds are:
# 1: 1803
# 2: 902
# 3: 601
# 4: 451
selected_difficulty = 1
app_rate = int(1803 / selected_difficulty)
app_step = (HEIGHT - 40) / app_rate

map_objects = [] # (offset, B/A)

def init_mapper():
    if not os.path.isdir("songs"):
        os.mkdir("songs")
        print("'songs' folder was missing, created it!")
    if not os.path.isdir("output"):
        os.mkdir("output")
        print("'output' folder was missing, created it!")

    global song_files, num_songs, screen
    song_files = os.listdir('songs')
    num_songs = len(song_files)
    if num_songs == 0:
        print("The 'songs' folder needs to have atleast one song in it")
        exit()
    else:
        pygame.mixer.init()
        pygame.font.init()
        screen = pygame.display.set_mode((WIDTH, HEIGHT))

        pygame.display.set_caption('TaikoGB mapper')
        screen.fill(BG_COLOR)
        text_surface, rect = GAME_FONT.render("SONGPOS: 0", (0, 0, 0))
        
        screen.blit(text_surface, (0, 510))
        pygame.display.flip()

def init_menu():
    global menu
    menu = pygame_menu.Menu('TaikoGB mapper', WIDTH, HEIGHT, theme=pygame_menu.themes.THEME_DARK)

    temp_arr = []
    for i in range(num_songs):
        temp_arr.append((song_files[i], i))
        
    menu.add.dropselect('Song :', temp_arr, onchange=select_song, default=0)
    menu.add.button('Start mapping', main_loop)
    menu.add.button('Quit', pygame_menu.events.EXIT)
    menu.mainloop(screen)



def select_song(value, song):
    global selected_song
    selected_song = value[1]

def load_song(song_num):
    global song_length
    file_path = "songs/" + song_files[song_num]
    pygame.mixer.music.set_endevent(MUSIC_END)
    pygame.mixer.music.load(file_path)
    pygame.mixer.music.set_volume(0.5)
    pygame.mixer.music.play()
    pygame.mixer.music.pause()
    song = MP3(file_path)
    song_length = int(song.info.length * 1000)

def draw_frame(song_pos):
    global display_text, selected_difficulty
    # Reset screen
    screen.fill(BG_COLOR)

    # Display current position in song (millis)
    text_surface, rect = GAME_FONT.render("Songpos: {}".format(song_pos), (0, 0, 0))
    screen.blit(text_surface, (0, 510))

    # Display current selected speed mode
    text_surface, rect = GAME_FONT.render("Current speed: {}".format(selected_difficulty), (0, 0, 0))
    screen.blit(text_surface, (0, 480))

    # BEGIN ALIGNMENT LINES
    temp_pos = song_pos % app_rate
    if temp_pos == 0:
        temp_pos = 1
    alignment_height = (HEIGHT - 40) * (temp_pos / app_rate)
    pygame.draw.line(screen, (70, 70, 70), (490, alignment_height), (574, alignment_height), 5)
    pygame.draw.line(screen, (70, 70, 70), (590, alignment_height), (674, alignment_height), 5)
    pygame.draw.line(screen, (70, 70, 70), (490, (alignment_height + ((HEIGHT - 40) // 2)) % (HEIGHT - 40)), (574, (alignment_height + ((HEIGHT - 40) // 2)) % (HEIGHT - 40)), 5)
    pygame.draw.line(screen, (70, 70, 70), (590, (alignment_height + ((HEIGHT - 40) // 2)) % (HEIGHT - 40)), (674, (alignment_height + ((HEIGHT - 40) // 2)) % (HEIGHT - 40)), 5)
    # END ALIGNMENT LINES

    # BEGIN MAP LINES 
    pygame.draw.line(screen, (0, 0, 0), (490, 0), (490, HEIGHT - 40), 5)
    pygame.draw.line(screen, (0, 0, 0), (574, 0), (574, HEIGHT - 40), 5)
    pygame.draw.line(screen, (0, 0, 0), (590, 0), (590, HEIGHT - 40), 5)
    pygame.draw.line(screen, (0, 0, 0), (674, 0), (674, HEIGHT - 40), 5)

    pygame.draw.line(screen, (0, 0, 0), (590, HEIGHT - 40), (674, HEIGHT - 40), 5)
    pygame.draw.line(screen, (0, 0, 0), (590, HEIGHT - 40 - 64), (674, HEIGHT - 40 - 64), 5)
    pygame.draw.line(screen, (0, 0, 0), (490, HEIGHT - 40), (574, HEIGHT - 40), 5)
    pygame.draw.line(screen, (0, 0, 0), (490, HEIGHT - 40 - 64), (574, HEIGHT - 40 - 64), 5)
    # END MAP LINES 


    # BEGIN MAP OBJECTS
    render_objects = []
    for object in map_objects:
        if song_pos in range(object[0] - app_rate, object[0] + 1):
            render_objects.append(object)

    for object in render_objects:
        position = app_step * (app_rate - (object[0] - song_pos))
        if object[1] == 1:
            screen.blit(circ1_img, (500, position - 64))
        else:
            screen.blit(circ2_img, (600, position - 64))
    # END MAP OBJECTS

    if display_text:
        text_surface, rect = GAME_FONT.render("Exported song!", (0, 0, 0))
        screen.blit(text_surface, (0, 0))
        if ((time.time()*1000) - text_timer) > 3000:
            display_text = False

    # Update display and wait approx 1 frame amount
    pygame.display.flip()
    pygame.time.wait(16)

def export_map():
    global map_objects, selected_song, song_files, display_text, text_timer
    map_objects.sort()
    temp_objects = map_objects[:]

    

    output_objects = []
    for i, object in enumerate(temp_objects):
        cur_offset = int((object[0] / 16.7) / 4)
        temp_objects[i] = (cur_offset, object[1])

    for object in temp_objects:
        if len(output_objects) > 0:
            if object[0] == output_objects[-1][0]:
                output_objects[-1] = (output_objects[-1][0], output_objects[-1][1] | object[1])
            else:
                output_objects.append(object)
        else:
            output_objects.append(object)

    prev_offset = 0
    for i, object in enumerate(output_objects):
        cur_offset = object[0]
        output_objects[i] = (cur_offset - prev_offset, object[1])
        prev_offset = cur_offset

    cur_pos = 0
    cur_object = output_objects[cur_pos]
    cur_offset = cur_object[0]
    cur_keys = 0
    next_keys = cur_object[1]
    if cur_offset == 0:
        cur_pos += 1
        cur_object = output_objects[cur_pos]
        cur_keys = next_keys
        cur_offset = cur_object[0]
        next_keys = cur_object[1]

    output_data = []

    converting = True
    while converting:
        while cur_offset > 63:
            output_data.append((cur_keys << 6) | 63)
            cur_keys = 0
            cur_offset -= 63

        output_data.append((cur_keys << 6) | cur_offset)

        cur_pos += 1
                    
        try:
            cur_object = output_objects[cur_pos]
            cur_keys = next_keys
            cur_offset = cur_object[0]
            next_keys = cur_object[1]
        except:
            output_data.append(next_keys << 6)
            converting = False
            break
        
    output_file_path = "output/" + song_files[selected_song].split(".")[0] + ".tgb"
    map_header = [len(output_data) & 0xFF, (len(output_data) >> 8) & 0xFF, selected_difficulty]
    with open(output_file_path, "wb") as fp:
        fp.write(bytearray(map_header + output_data))

    display_text = True
    text_timer = time.time()*1000
        
        
def handle_events():
    global song_pos, map_objects, song_length, scroll_speed, edit_mode, selected_obj, selected_difficulty, app_rate, app_step
    cur_pos = pygame.mixer.music.get_pos()
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            quit()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE: # Start/stop music
                if pygame.mixer.music.get_busy():
                    song_pos += cur_pos
                    pygame.mixer.music.pause()
                else:
                    pygame.mixer.music.play(0, song_pos / 1000)
            elif event.key == pygame.K_n: # Add an object to the left lane
                temp_object = (song_pos, 1)
                if temp_object not in map_objects:
                    map_objects.append(temp_object)
                    map_objects.sort() # might be slow 
            elif event.key == pygame.K_m: # Add an object to to right lane
                temp_object = (song_pos, 2)
                if temp_object not in map_objects:
                    map_objects.append(temp_object)
                    map_objects.sort()
            elif event.key == pygame.K_e: # Export map
                export_map()
            elif event.key == pygame.K_LSHIFT: # Medium scroll speed
                scroll_speed = 10
            elif event.key == pygame.K_LCTRL: # Slowest scroll speed
                scroll_speed = 1
            elif event.key == pygame.K_a: # Edit mode
                edit_mode ^= True
                selected_obj = 0
                for i in range(len(map_objects)):
                    if map_objects[i][0] >= song_pos:
                        selected_obj = i
                        break
            elif event.key == pygame.K_DELETE:
                if edit_mode:
                    del map_objects[selected_obj]
                    edit_mode = False
            elif event.key == pygame.K_HOME:
                if not pygame.mixer.music.get_busy():
                    song_pos = 0
            elif event.key == pygame.K_END:
                if not pygame.mixer.music.get_busy():
                    song_pos = song_length
            elif event.key == pygame.K_UP:
                selected_difficulty += 1
                app_rate = int(1803 / selected_difficulty)
                app_step = (HEIGHT - 40) / app_rate
                
                
            elif event.key == pygame.K_DOWN:
                selected_difficulty -= 1
                if selected_difficulty < 1:
                    selected_difficulty = 1
                app_rate = int(1803 / selected_difficulty)
                app_step = (HEIGHT - 40) / app_rate
        elif event.type == pygame.KEYUP:
            if (event.key == pygame.K_LSHIFT) or (event.key == pygame.K_LCTRL):
                scroll_speed = 100
        elif event.type == pygame.MOUSEWHEEL:
            if not edit_mode:
                if pygame.mixer.music.get_busy():
                    song_pos += cur_pos
                    pygame.mixer.music.pause()
                    pygame.mixer.music.unpause()
                song_pos += scroll_speed*event.y
                if song_pos < 0:
                    song_pos = 0
                elif song_pos > song_length:
                    song_pos = song_length
                if pygame.mixer.music.get_busy():
                    pygame.mixer.music.play(0, song_pos / 1000)
            else:
                if len(map_objects) == 0:
                    edit_mode = False
                    break
                new_pos = map_objects[selected_obj][0] + scroll_speed*event.y
                if new_pos < 0:
                    new_pos = 0
                elif new_pos > song_length:
                    new_pos = song_length
                map_objects[selected_obj] = (new_pos, map_objects[selected_obj][1])
        elif event.type == MUSIC_END:
            song_pos = 0
    return cur_pos

def main_loop():
    load_song(selected_song)
    
    while True:
        cur_pos = handle_events()

        if pygame.mixer.music.get_busy():
            draw_frame(song_pos + cur_pos)
        else:
            draw_frame(song_pos)

if __name__ == "__main__":
    init_mapper()
    init_menu()
    