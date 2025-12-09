# 🏙️ **Faisal Town Traffic — x86 Assembly Racing Game**

A fast-paced 16-bit DOS racing experience built in pure **x86 Assembly (NASM)**. Navigate the busy streets of Faisal Town, collect coins, refuel in time, and avoid deadly traffic collisions. One wrong move… and it’s over!

---

## 👥 **Project Team**

| Member                     | Roll Number |
| -------------------------- | ----------- |
| **Muhammad Abdullah Omar** | 24L-0576    |
| **Zoha Sarwar**            | 24L-0536    |

---

## 🎮 **Game Instructions**

### 🔼 **Controls**

* **Left / Right Arrow Keys** → Move your car horizontally
* **ESC** → Pause the game

### 🚗 **Gameplay Overview**

* **Collect Coins** to increase your score
* **Pick Up Fuel** to refill your tank
* **If Fuel Reaches Zero → Game Over**
* **If You Crash into Traffic → Game Over**

Your mission: survive the chaotic streets and rack up the highest score possible.

---

## 📁 **Project File Setup**

To run the game successfully, ensure **all files inside the `resource/` folder** are placed in the **same directory** as the following files:

```
proj.asm
nasm.exe
afd.exe
```

This is required for loading sprites, data, and resource assets.

---

## ⚙️ **How to Compile & Run (DOSBox)**

### 1️⃣ **Compile the Project**

Inside DOSBox, navigate to your project directory and run:

```bash
nasm proj.asm -o proj.com
```

### 2️⃣ **Run the Game**

```bash
proj.com
```

You’re ready to hit the roads of Faisal Town!

---

## ▶️ **Running via GitHub Repository**

Clone the official repository:

```bash
git clone https://github.com/ZohaSarwar/Faisal-Town-Traffic.git
```

Place the `resource/` files correctly (as mentioned above), then compile and run using DOSBox.

---

## 🚀 **About the Game**

**Faisal Town Traffic** showcases low-level programming, graphics using DOS interrupts, and real-time event handling — all crafted in assembly language. It’s a tribute to classic DOS gaming with a modern twist of creativity.

Enjoy navigating the streets of Faisal Town — and good luck surviving the traffic!
