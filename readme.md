# macOS Floating Countdown Timer

A lightweight, minimalist countdown timer for macOS written in Objective-C using the Cocoa framework. The application features a borderless, always-on-top window that can be dragged across the screen and persists across all macOS Spaces.

By default, the timer is set to a 1-hour countdown, but it can be easily adjusted in the source code.

## 🌟 Features

* **Always on Top:** The timer floats above other desktop windows (`NSStatusWindowLevel`), making it perfect for tracking time while working in other apps.
* **Borderless & Draggable:** A clean UI with no standard window controls. You can move the timer simply by clicking and dragging its background.
* **Spaces Support:** Follows you across different macOS desktops/Spaces.
* **Visual Pause Indicator:** Displays an asterisk (`*`) next to the time when the countdown is paused.
* **Keyboard & Mouse Support:** Fully controllable via intuitive mouse clicks and keyboard shortcuts.

---

## 🎮 Controls

The application relies entirely on mouse clicks and keyboard shortcuts for interaction:

| Action | Input / Shortcut | Description |
| --- | --- | --- |
| **Pause / Resume** | `Left-Click` or `Spacebar` | Toggles the countdown. |
| **Reset Timer** | `R` | Resets the timer back to its initial state (1 hour). |
| **Toggle Fullscreen** | `F` | Enters or exits fullscreen mode. |
| **Exit Fullscreen** | `Esc` | Exits fullscreen mode and returns to floating window. |
| **Safe Quit** | `Right-Click` | Prompts a confirmation dialog asking if you want to quit. |
| **Quick Quit** | `Q` | Immediately terminates the application without a prompt. |

---

## 🛠 How to Compile and Run

Because this is a standalone Objective-C file, you do not strictly need Xcode to build it. You can compile and run it directly from the macOS Terminal using `clang`.

**1. Save the code:**
Save the provided code into a file named `main.m`.

**2. Compile via Terminal:**
Open your Terminal, navigate to the folder containing `main.m`, and run the following command to compile it with ARC (Automatic Reference Counting) and the Cocoa framework:

```bash
clang -fobjc-arc -framework Cocoa main.m -o FloatingTimer
```

**3. Run the App:**
Execute the compiled binary:

```bash
./FloatingTimer
```

---

## ⚙️ Customization

If you want to change the default duration of the timer, locate the `initWithFrame:` method in the `TimerView` implementation.

Change the `_initialSeconds` variable to your desired time in seconds:

```objective-c
// Example: Change to 25 minutes for a Pomodoro timer
_initialSeconds = 25 * 60; 
```

To change the dimensions of the timer window, adjust the `NSRect` values in the `main()` function:

```objective-c
// NSRect frame = NSMakeRect(x, y, width, height);
NSRect frame = NSMakeRect(200, 200, 140, 50);
```