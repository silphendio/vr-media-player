#!/bin/sh

# get openxr plugin
if [ ! -f godot-openxr.zip ]; then
    wget https://github.com/GodotVR/godot_openxr/releases/download/1.3.0/godot-openxr.zip
fi
unzip -n godot-openxr.zip
mv -n godot_openxr_1.3.0/addons .


# get godot
if [ ! -f Godot_v3.5.1-stable_x11.64.zip ]; then
    wget https://downloads.tuxfamily.org/godotengine/3.5.1/Godot_v3.5.1-stable_x11.64.zip
fi
unzip -n Godot_v3.5.1-stable_x11.64.zip

# build video-decoder
./build-godot-videodecoder.sh

printf "[Desktop Entry]\nType=Application\nTerminal=false\nExec=$PWD/Godot_v3.5.1-stable_x11.64\nPath=$PWD\nName=VR Media Player\nIcon=$PWD/thirdparty/tabler-icons/badge-vr.svg" > vr-media-player.desktop
