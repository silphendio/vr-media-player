# VR Media Player

This is a simple video player / image viewer for virtual reality bult with [Godot](https://godotengine.org/).

When no VR device is detected, it still works in "desktop-mode"

Supports most Video-Formats, and images as png, bmp, tga, webp, jpg, or mpo. Gifs are not supported.

VR modes are flat screen (with zoom) , VR180, and VR360 (equirectangular or equi-angular cubemap).


## Dependencies:

### Godot
Built with version 3.5. Later versions of the 3.x branch might work too.

### godot-openxr
Download it from [here](https://github.com/GodotVR/godot_openxr/releases/download/1.3.0/godot-openxr.zip)
and place the `addons` folder into the project folder.

### godot-videodecoder (optional)
Godot natively only supports webm and ogv and no frame-seeking.
To play other formats, this project uses [godot-videodecoder](https://github.com/jamie-pate/godot-videodecoder).

Because compilation is difficult, the source code and a costum build script is included here (Linux only).
To build it this way, a compiler and ffmpeg development libraries need to be installed. For Ubuntu run

```
sudo apt install build-essential libavcodec-dev libswresample-dev libavformat-dev libavutil-dev libswscale-dev
```

and then run 
```./build-godot-videodecoder.sh```.

To use the plugin, make sure ffmpeg is installed. (`sudo apt install ffmpeg` for Ubuntu)

--
## Running:
Open the project with Godot and click "run", or use the export function to generate a binary, like so:

```
mkdir bin
Godot_v3.5-stable_x11.64 --export "Linux/X11" bin/vr-media-player
```



## Controls:

- Mouse:
  - right click to open/close the menu
  - middle click, or hold left button to look around (desktop-mode only)
  - wheel to change volume

- Keyboard:
  - ASDW to move the camera around (for flat projection only)
  - Space to pause video
  - Left or Right to skip forward or backward 10 seconds for video
  - Left or Right to load next/previous image in current folder
  - Up or Down to control volume

- VR Controller (either hand):
  - `B` to open/close menu
  - when menu is closed:
    - trigger to pause video
    - joystick left or right to skip forward or backward 10 seconds for video
    - joystick left or right to load next/previous image in current folder
    - joystick up or down to control volume
  - when menu is open:
  - trigger or `A` to click on menu
  - joystick up or down to scroll
