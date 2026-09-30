# Google Chrome Dino Game on Xilinx Spartan-3E FPGA

A complete hardware implementation of the famous Google Chrome offline **T-Rex Dino game**, written from scratch in **Verilog HDL**. The entire game logic, pixel-mapped sprite rendering, physics, and VGA synchronization are executed natively on the **Xilinx Spartan-3E** FPGA hardware using the **Xilinx ISE Design Suite**.

## 🚀 Key Features

* **100% Hardware-Driven Architecture:** Driven entirely by digital logic, counters, and Finite State Machines (FSM) without any soft-core processor or operating system.
* **Custom Pixel-Art Sprite Rendering:** Built embedded ROM matrices inside the code (`dino_draw.v`) to render multi-frame animations for the Dino (running and ducking states), obstacles (cacti and birds), and moving clouds.
* **Integrated Score Font ROM (`digit_draw.v`):** A custom 8x16 bitmap font generator implemented in hardware to handle real-time decimal decomposition and on-screen rendering of Current Score and High Score.
* **Pseudorandom Obstacle Spawning:** Utilizes a Linear Feedback Shift Register (LFSR) module (`lfsr8.v`) combined with clock-driven delay logic to randomly spawn various obstacle types (birds at low/med/high altitudes and cacti) with increasing velocity as the score increases.
* **Hardware Anti-Bounce Interfacing:** Implemented low-level input synchronization and glitch filtering modules (`debounce.v`) to ensure stable player control via the physical pushbuttons.

---

## 🛠️ Hardware & Software Stack

* **FPGA Board:** Xilinx Spartan-3E Starter/Development Board
* **Hardware Description Language:** Verilog HDL
* **IDE / Synthesis Tool Chain:** Xilinx ISE Design Suite (Project Navigator)
* **Target Video Standard:** VGA 640x480 @ 60Hz (driven by a native 25 MHz pixel clock)

---

## 📂 Project Architecture & Verilog Modules

The hardware architecture uses a fully modular structure:

* **`TOP_DINO_VGA.v`** – The main top-level entity tying together the physics engine, game states, object tracking, and score accumulation.
* **`dino_draw.v`** – The pixel graphics engine containing hardcoded binary matrices for game sprites (Dino frames, cactus variants, flying birds, game-over banners, and ground textures).
* **`vga_controller.v` / `vga_sync.v`** – Generates standard HSYNC/VSYNC timing sequences and active area signals for digital video output.
* **`digit_draw.v`** – Hardware Font ROM mapping 4-bit BCD data to printable 8x16 digital numbers.
* **`clk_divider.v`** – Synthesizes the master 50 MHz oscillator input down to a synchronous 25 MHz pixel clock.
* **`debounce.v`** – Filters mechanical contact noise from physical jump and duck input keys.
* **`lfsr8.v`** – An 8-bit pseudo-random sequence generator providing seed values for variable obstacle spawn windows.

---

## 🎮 Game Mechanics & Controls

1. Synthesize and load the `.bit` bitstream file onto the Spartan-3E chip via Xilinx iMPACT.
2. Connect the FPGA board's DB15 connector to an external monitor via a **VGA cable**.
3. **Controls:**
   * **BTN 0 / Jump:** Initiates jump physics (gravity & velocity curve handling).
   * **BTN_DUCK / Duck:** Changes the Dino's hitbox and switches to the 32x64 compressed frame animation.
   * **START / Reset:** Initializes the game run or restarts it from the `GAME_OVER` screen.
