import sys, os

map_path = ""

try:
    map_path = sys.argv[1]
    if os.path.exists(map_path):
        print("Found map! {}".format(map_path))
    else:
        print("Map not found")
        quit()
except:
    print("No map path provided")
    print("Usage: python parser.py mapname")
    quit()

with open(map_path, "r") as fp:
    map_data = fp.read()

map_data = map_data.split("\n\n")

difficulty = map_data[4].split("\n")
if difficulty[0] != "[Difficulty]":
    print("Map data is not as expected: difficulty: {}".format(difficulty[0]))
    quit()
approach_rate = int(difficulty[4].split(":")[1])
1, 2, 3, 4, 5, 6, 7, 8, 9, 10
if approach_rate in [1, 2]:
    approach_rate = 1
elif approach_rate in [3, 4, 5]:
    approach_rate = 2
elif approach_rate in [6, 7, 8]:
    approach_rate = 3
elif approach_rate in [9, 10]:
    approach_rate = 4
else:
    print("Invalid approach rate {}".format(approach_rate))
    quit()

# We don't really care about those, let's just exit if there are more than two lines, we don't support that
timing_points = map_data[6].split("\n")
if timing_points[0] != "[TimingPoints]":
    print("Map data is not as expected: timing_points: {}".format(timing_points[0]))
    quit()
if len(timing_points) > 2:
    print("Timingpoints contains more than two values ({}), we don't support that yet!".format(len(timing_points)))
    quit()
timing_points = timing_points[1].split(",")

hit_objects = map_data[7].split("\n")
if (hit_objects[0] != "[HitObjects]") and (hit_objects[1] != "[HitObjects]"):
    print("Map data is not as expected: hit_objects: {}".format(hit_objects[0]))
    quit()

hit_objects = hit_objects[1::]
if hit_objects[0] == "[HitObjects]":
    del hit_objects[0]

# We start parsing the map objects to tgb format

# Hit object syntax: x,y,time,type,hitSound,objectParams,hitSample
# x and y don't matter for taiko maps
# The fields we care about are time and hitSound
cur_offset = 0
temp_objects = []
for line in hit_objects:
    line = line.split(",")
    if len(line) > 2:
        time_pos = int(line[2])
        hit_sound = int(line[4])
        if (hit_sound == 1) or (hit_sound == 0): # Normal hitsound
            hit_sound = 2
        elif (hit_sound == 2) or (hit_sound == 8): # Whistle or clap hitsound
            hit_sound = 1
        elif (hit_sound == 4) or (hit_sound == 5) or (hit_sound == 6) or (hit_sound == 12): # Big note
            hit_sound = 3
        
        temp = (int((time_pos / 16.7) / 4), hit_sound)
        if len(temp_objects) != 0:
            if temp[0] == temp_objects[-1][0]:
                temp_objects[-1] = (temp[0], temp_objects[-1][1] | temp[1])
            else:
                temp_objects.append(temp)
        else:
            temp_objects.append(temp)

prev_offset = 0
for i, object in enumerate(temp_objects):
    cur_offset = object[0]
    temp_objects[i] = (cur_offset - prev_offset, object[1])
    prev_offset = cur_offset

# Hacky
if temp_objects[0][0] == 0:
    temp_objects[0] = (1, temp_objects[0][1])

cur_pos = 0
cur_object = temp_objects[cur_pos]
cur_offset = cur_object[0]
cur_keys = 0
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
        cur_object = temp_objects[cur_pos]
        cur_keys = next_keys
        cur_offset = cur_object[0]
        next_keys = cur_object[1]
    except:
        output_data.append(next_keys << 6)
        converting = False
        break

map_header = [len(output_data) & 0xFF, (len(output_data) >> 8) & 0xFF, approach_rate]
output_path = map_path + ".tgb"
with open(output_path, "wb") as fp:
        fp.write(bytearray(map_header + output_data))
print("File exported to {}".format(output_path))