# VR Media Player

This is a simple video player / image viewer for virtual reality bult with [Godot](https://godotengine.org/).

When no VR device is detected, it still works in "desktop-mode"

Supports most Video-Formats, and images as png, bmp, tga, webp, jpg, or mpo. Gifs are not supported.

VR modes are flat screen (with zoom) , VR180, and VR360 (equirectangular or equi-angular cubemap).


## Running the Application:

### Linux:
First, make sure the following packages are installed:

`gcc ffmpeg wget unzip` (Arch Linux)

or 

`build-essential ffmpeg libavcodec-dev libswresample-dev libavformat-dev libavutil-dev libswscale-dev wget unzip` (Ubuntu)

Then run ```./build.sh```.

To run the application, run the `./Godot_v3.5.1-stable_x11.64` or use the generated `vr-media-player.desktop` file.

### Manual build:
The project uses Godot 3.5. Make sure to get a compatble version. You can download a standalone binary on the [Godot Website](https://godotengine.org/download)

Next, get the [Godot OpenXR plugin](https://github.com/GodotVR/godot_openxr), and add it to the project.

To watch videos, [godot-videodecoder](https://github.com/jamie-pate/godot-videodecoder) is used. This project includes the source code for the plugin and a simple build script for linux. Get the prerequisites listed above and run `./build.sh`. For other platforms, follow the instructions provided by the linked page.

To run the application, start Godot, import the project and click `run`. To reate a standalone executable, follow this [Exporting projects](https://docs.godotengine.org/en/3.5/tutorials/export/exporting_projects.html) Tutorial. 


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
