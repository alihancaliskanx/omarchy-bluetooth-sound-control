# Omarchy Bluetooth Sound Control

A lightweight tool and Omarchy bar widget to toggle between high-quality stereo playback (A2DP) and headset microphone mode (HFP/HSP) for Bluetooth audio devices under PipeWire and WirePlumber.

## Features

- **High Quality Mode (A2DP):**
  - Switches to stereo high fidelity codec (AAC, LDAC, SBC-XQ).
  - Disables WirePlumber's automatic profile switching (`bluetooth.autoswitch-to-headset-profile = false`) so recording requests do not degrade sound quality.
  - Automatically un-mutes and routes audio input to the machine's built-in microphone so recording still works.
- **Headset Mic Mode (HFP):**
  - Switches Bluetooth device to bidirectional headset profile (mSBC).
  - Enables WirePlumber autoswitching.
- **Desktop Feedback:**
  - Emits native `omarchy-osd` indicators on profile change.
- **Omarchy Bar Widget:**
  - Displays headphones icon (`󰋋`) during A2DP and headset mic icon (`󰍬`) during HFP.
  - Left-click toggles mode; middle-click opens Omarchy Bluetooth panel.

## CLI Usage

Run directly:
```bash
./bin/omarchy-bluetooth-sound-control status
./bin/omarchy-bluetooth-sound-control toggle
./bin/omarchy-bluetooth-sound-control a2dp
./bin/omarchy-bluetooth-sound-control hfp
```

## Omarchy Plugin Installation

To install as an Omarchy shell bar widget:
```bash
omarchy plugin add /home/sups/Documents/Code/omarchy-bluetooth-sound-control --enable
```
