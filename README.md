# LED Control Setup for XPEnology (UGreen NAS)
(Based on this original post: https://www.bilibili.com/opus/1004368610304458758)

## Instructions

### Installation

1. **Verify required libraries**  
   Ensure your DSM has the necessary libraries by running:  
   ```bash
   lsmod | grep i2c
   ```
   Expected output (example):  
   ```
   i2c_algo_bit           16384  1 i915  
   i2c_i801               28672  0
   ```

2. **Compatibility Note**  
   - The script was tested on `DS3622xs` (lacks `i2c` support by default).  
   - Either install the libraries manually **or** switch to a compatible model like `SA6400`.

3. **Download the CLI Tool**  
   Get the latest release:  
   [ugreen_leds_cli](https://github.com/miskcoo/ugreen_leds_controller/releases/download/v0.1-debian12/ugreen_leds_cli)

   Get the ug_leds_en.sh script from this repo.

5. **Folder Setup**  
   Create this structure (replace `xxxx` with your username):  
   ```
   /volume1/homes/xxxx/ugreen_leds/
   ├── ug_leds_en.sh  
   └── ugreen_leds_cli
   ```

---

### Job Setup (Scheduled Task)

1. **DSM Task Scheduler**  
   - **Path**: `Control Panel → Task Scheduler`  
   - **Action**: Add a new *User-defined script* task.  

2. **Task Configuration**  
   - **Name**: `ugreen_led`  
   - **User**: `root`  
   - **Frequency**: Every 5 minutes (adjustable)  
   - **Run Command**:  
     ```bash
     cd /volume1/homes/xxxx/ugreen_leds  
     chmod +x ug_leds_en.sh  
     chmod +x ugreen_leds_cli  
     bash ug_leds_en.sh
     ```

---

### LED Behavior Overview

| **Component** | **Status** | **Color/Behavior** | **Condition** |
|---------------|------------|---------------------|---------------|
| **Power**     | Normal     | White               | Default       |
|               | Alert      | Red (blinking)      | CPU temp > 90°C *(requires `sensors` plugin in RR)* |
| **Network**   | Online     | Blue                | Gateway reachable |
|               | Offline    | Red                 | No connection |
| **Disk (1–8)**| Healthy    | Green               | SMART OK |
|               | Failed     | Red                 | SMART Failure |
|               | Unknown    | Yellow              | Undetermined state |
|               | Overheat   | Yellow (blinking)   | Temp > 50°C |

---

### Notes
- Replace `xxxx` in paths with your actual DSM username.  
- Ensure scripts are executable (`chmod +x`).  
- For CPU temp alerts, install `lm-sensors` if missing.  

Let me know if you'd like any adjustments!
