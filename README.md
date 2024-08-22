# VR Media Player
This is a simple video player / image viewer for virtual reality bult with [Godot](https://godotengine.org/).

When no VR device is detected, it still works in "desktop-mode"

Supports most Video-Formats, and images as png, bmp, tga, webp, jpg, or mpo. Gifs are not supported.

VR modes are flat screen (with zoom) , 180°, and 360° (equirectangular or equi-angular cubemap).

## Running from source:

- The project uses Godot 4.3. Make sure to get a compatble version. You can download a standalone binary on the [Godot Website](https://godotengine.org/download)

- Next, get the [EIRTeam.FFmpeg](https://github.com/EIRTeam/EIRTeam.FFmpeg/releases) plugin, and unzip it into the project folder.

- To be able to watch videos with uncommon codecs, download an appropriate version of [FFmpeg builds](https://github.com/BtbN/FFmpeg-Builds/releases) and copy all `.dll` or `.so` files into the `addons/ffmpeg/linux64/` or `addons/ffmpeg/win64/` folder. Overwrite existing files.

- To run the application, start Godot, import the project and click `run`.

To reate a standalone executable, follow this [Exporting projects](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html) Tutorial. 

Binary distribution coming soon...

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
