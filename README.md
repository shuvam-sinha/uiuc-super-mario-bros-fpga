# Mario FPGA

> Collaborative project with [@adjoshi24](https://github.com/adjoshi24).

>This repository contains the final files from my ECE 385 project, committed as a single snapshot.

A hardware recreation of side-scrolling Super Mario Bros., targeting the Xilinx Spartan-7 on a RealDigital Urbana board. The game engine lives in SystemVerilog; a MicroBlaze soft processor runs a C firmware layer on top of it.

- Scrolling tile-based backgrounds, sprite drawing, a score/HUD overlay, and 1-bit square-wave audio out over the 3.5mm jack
- The engine is wrapped as a custom AXI4-Lite IP core (`mario_controller_v1_0`) that the MicroBlaze drives
- Player movement uses 8.8 fixed-point arithmetic
- Keyboard input arrives over USB and is decoded in firmware

Toolchain: Vivado 2022.2 plus the matching Vitis release.

## Repo structure

```
hardware/
├── constrs/          # Pin constraints (.xdc)
├── bd/                # Vivado block design (MicroBlaze + peripherals)
├── src/               # Top-level SystemVerilog game logic
└── ip_repo/
    └── mario_controller_1_0/   # Custom AXI4-Lite IP core (packaged)
        ├── hdl/       # IP core SystemVerilog source
        └── src/       # COE memory-initialization files (tile/sprite ROMs)
software/
└── src/               # MicroBlaze C firmware (Vitis application)
    └── lw_usb/        # USB HID driver (keyboard input)
```

## What you'll need

- Vivado 2022.2, or a nearby version
- A matching install of Vitis
- A RealDigital Urbana board (Spartan-7). Targeting anything else means reworking `hardware/constrs/mb_usb_hdmi_top.xdc` first.

## Building the hardware

1. Start a fresh Vivado project against the Spartan-7 part on the Urbana board.
2. Point Vivado at `hardware/ip_repo/` under **Settings → IP → Repository** so that `mario_controller_1_0` shows up as an available core.
3. Bring in the block design at `hardware/bd/mb_block.bd` and let Vivado regenerate its output products.
4. Add the SystemVerilog files under `hardware/src/` as design sources.
5. Add `hardware/constrs/mb_usb_hdmi_top.xdc` as a constraints source.
6. Synthesize, implement, and write the bitstream.

**About the constraints file:** `mb_usb_hdmi_top.xdc` came over unchanged from an earlier, unrelated lab project — it wasn't written specifically for this design. Different hardware, or even a different board revision, will likely need the pin mapping edited before the I/O comes out correct.

## Building the software

1. After implementation, export the hardware (`.xsa`) from Vivado and use it to create a platform project in Vitis.
2. Add an application project on that platform from the "Empty Application" template.
3. Copy everything under `software/src/` — the `lw_usb/` folder included — into the application's `src/` directory.
4. Build, then program the FPGA and launch the application via Run or Debug.

## Notes

- There are two separate files whose names differ only in capitalization: `color_mapper.sv` at the top level and `Color_Mapper.sv` inside the IP core. That's carried over from how the project was originally laid out, and both need to stay as they are.
- `component.xml` is auto-generated IP metadata from Vivado. Without it, Vivado won't recognize `mario_controller_1_0` as a packaged core when importing.
