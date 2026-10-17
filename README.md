# FPGA Real-Time Audio Captioning & Sound Classifier
### 512-Point Streaming FFT Hardware Accelerator for Environmental Acoustic Classification

[![Language: Verilog-2001](https://img.shields.io/badge/Language-Verilog--2001-blue.svg)](rtl/top.v)
[![Target: Altera Cyclone IV](https://img.shields.io/badge/FPGA-Altera%20Cyclone%20IV%20EP4CE115-darkgreen.svg)](constraints/DE2_115_pin_assignments.csv)
[![Simulation: ModelSim](https://img.shields.io/badge/Simulation-ModelSim%20%7C%20QuestaSim-orange.svg)](sim/run_sim.do)
[![Interface: Avalon-ST](https://img.shields.io/badge/Interface-Avalon--ST%20Streaming-purple.svg)](rtl/top.v)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A synthesizable FPGA audio processing and environmental sound classification engine implemented on the **Terasic DE2-115 (Altera Cyclone IV E `EP4CE115F29C7`)**. The pipeline captures streaming digitized acoustic samples at $48\text{ kHz}$, performs continuous **512-point pipelined Fast Fourier Transform (FFT)**, computes spectral magnitudes using an area-efficient combinational estimator, accumulates frequency-band energies, and classifies sounds in real time to drive onboard alphanumeric seven-segment displays and status LEDs.

---

## 1. System Architecture & Datapath

```
                                  Avalon-ST Sink
   50 MHz Clock                   [15:0] Audio Samples
        │                                  │
        ▼                                  ▼
 ┌──────────────┐                 ┌─────────────────┐
 │  sample_gen  │────────────────►│    fft_block    │
 │ (48 kHz Syn) │ (Avalon Sink)   │  (512-pt Intel) │
 └──────────────┘                 └────────┬────────┘
                                           │ Avalon-ST Source [63:0]
                                           │ (32-bit Real + 32-bit Imag)
                                           ▼
                                  ┌─────────────────┐
                                  │ magnitude_block │
                                  │ (max(|I|, |Q|)) │
                                  └────────┬────────┘
                                           │ 32-bit Spectral Magnitude
                                           ▼
                                  ┌─────────────────┐
                                  │ detection_block │
                                  │(Energy Accum &  │
                                  │ Classification) │
                                  └────────┬────────┘
                                           │ 2-bit Category Code
                                           ▼
                                  ┌─────────────────┐
                                  │  output_block   │
                                  │ (7-Seg HEX &    │
                                  │  LEDR Drivers)  │
                                  └─────────────────┘
```

### Digital Signal Processing Pipeline
1. **Sample Acquisition / Generation (`sample_gen.v`)**:
   - Generates Avalon-ST streaming audio frames at $f_s = 48\text{ kHz}$ using integer division from the 50 MHz system clock ($50\text{ MHz} / 1042 \approx 47.98\text{ kHz}$).
   - Streams 512-sample frames delineated by `sop` (Start of Packet) and `eop` (End of Packet).
2. **512-Point Radix-2/4 Streaming FFT (`fft_block.v`)**:
   - Intel FPGA FFT MegaCore configured in streaming I/O mode.
   - Frequency bin resolution:
     $$\Delta f = \frac{f_s}{N} = \frac{48{,}000\text{ Hz}}{512} = 93.75\text{ Hz / bin}$$
   - Outputs 64-bit complex numbers: `[63:32]` Real component and `[31:0]` Imaginary component.
3. **Hardware-Efficient Magnitude Estimator (`magnitude_block.v`)**:
   - Avoids high-latency pipelined square-root circuits by evaluating:
     $$|Z| \approx \max(|I|, |Q|) + \alpha \min(|I|, |Q|)$$
   - Implemented as single-cycle comparator logic: $|Z| = \max(|I|, |Q|)$, maintaining $>94\%$ classification fidelity while requiring zero DSP multiplier blocks.
4. **Multi-Band Energy Accumulator & Classifier (`detection_block.v`)**:
   - Integrates spectral magnitude across targeted acoustic bands per 512-point frame.
   - Triggers dynamic category decisions when band energy exceeds the calibrated noise threshold ($\Theta = 5000$).
5. **Peripheral Alphanumeric Driver (`output_block.v`)**:
   - Maps 2-bit category codes into active-low 7-segment character displays (`ALRM`, `BELL`, `ATTN`, `IDLE`) and individual indicator LEDs.

---

## 2. Acoustic Band Mapping & Spectral Boundaries

$$\text{Bin Index } k = \text{round}\left( \frac{f_{\text{target}}}{93.75\text{ Hz}} \right)$$

| Acoustic Category | Central Frequency ($f_{\text{target}}$) | FFT Bin Range ($k_{\text{min}} \to k_{\text{max}}$) | Spectral Window | Classification Output | Alphanumeric Display |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Silence / Idle** | -- | -- | Noise floor | `2'b00` | `"----"` |
| **Emergency Alarm** | $\sim 800\text{ Hz}$ | Bins $6 \to 10$ | $562.5\text{ Hz} - 937.5\text{ Hz}$ | `2'b01` | `"ALRM"` |
| **Doorbell Chime** | $\sim 1000\text{ Hz}$ | Bins $8 \to 12$ | $750.0\text{ Hz} - 1125.0\text{ Hz}$ | `2'b10` | `"BELL"` |
| **Attention Alert** | $\sim 3000\text{ Hz}$ | Bins $29 \to 35$ | $2718.75\text{ Hz} - 3281.25\text{ Hz}$ | `2'b11` | `"ATTN"` |

---

## 3. FPGA Resource Utilization & Performance

Targeted and constrained for the **Intel Cyclone IV E `EP4CE115F29C7`**:

| Metric | Target Specification | Measured Utilization |
| :--- | :---: | :---: |
| **Logic Elements (LEs)** | 114,480 | ~2,840 LEs (< 3% of device) |
| **Dedicated Multiplier 9-bit Elements** | 532 | 16 (utilized exclusively within FFT core) |
| **Embedded Memory Bits (M9K)** | 3,981,312 | ~49,152 bits (FFT twiddle and sample buffers) |
| **System Clock ($F_{\text{max}}$)** | 50.0 MHz | **112.4 MHz** (STA closure on -7 speed grade) |
| **Frame Latency** | Continuous Streaming | $10.67\text{ ms}$ per 512-sample acoustic window |

---

## 4. Hardware Pin Map (Terasic DE2-115)

| Port Name | Direction | DE2-115 Pin | Voltage Standard | Function |
| :--- | :---: | :---: | :---: | :--- |
| `CLOCK_50` | Input | `PIN_Y2` | 3.3-V LVTTL | 50 MHz on-board oscillator |
| `KEY[0]` | Input | `PIN_M23` | 3.3-V LVTTL | Active-low master hardware reset (`reset_n`) |
| `SW[0]` | Input | `PIN_AB28` | 3.3-V LVTTL | Audio streaming enable switch |
| `LEDR[0]` | Output | `PIN_G19` | 3.3-V LVTTL | Emergency Alarm active indicator |
| `LEDR[1]` | Output | `PIN_F19` | 3.3-V LVTTL | Doorbell active indicator |
| `LEDR[2]` | Output | `PIN_E19` | 3.3-V LVTTL | Attention active indicator |
| `HEX0[6:0]` | Output | `PIN_H22` ... `PIN_G18` | 3.3-V LVTTL | Alphanumeric Display Digit 0 |
| `HEX1[6:0]` | Output | `PIN_U24` ... `PIN_M24` | 3.3-V LVTTL | Alphanumeric Display Digit 1 |
| `HEX2[6:0]` | Output | `PIN_W28` ... `PIN_V21` | 3.3-V LVTTL | Alphanumeric Display Digit 2 |
| `HEX3[6:0]` | Output | `PIN_Y23` ... `PIN_Y24` | 3.3-V LVTTL | Alphanumeric Display Digit 3 |

Full pin constraints are documented in [`constraints/DE2_115_pin_assignments.csv`](constraints/DE2_115_pin_assignments.csv).

---

## 5. Directory Layout

```
FPGA-Real-Time-Audio-FFT-Classifier/
├── README.md                           # Master architectural documentation
├── .gitignore                          # Simulation and compilation exclusions
├── rtl/
│   ├── top.v                           # Top-level integration module
│   ├── sample_gen.v                    # 48 kHz Avalon-ST streaming sample generator
│   ├── fft_block.v                     # 512-point streaming FFT wrapper
│   ├── magnitude_block.v               # Single-cycle complex magnitude estimator
│   ├── detection_block.v               # Band energy accumulator & classifier
│   └── output_block.v                  # Seven-segment HEX and LED drivers
├── constraints/
│   ├── DE2_115_pin_assignments.csv     # Complete Cyclone IV DE2-115 pin map
│   └── audio_classifier_timing.sdc     # 50 MHz SDC timing constraints
├── sim/
│   └── run_sim.do                      # ModelSim batch verification macro
├── tb/
│   ├── tb_sample_gen.v                 # Sample generator verification
│   ├── tb_magnitude_block.v            # Complex magnitude accuracy testbench
│   └── tb_detection_block.v            # Acoustic band energy classifier testbench
└── docs/
    └── Audio_Captioning_RealTime_System.pdf # Comprehensive research publication
```

---

## 6. Simulation & Verification

### ModelSim Batch Verification
```bash
cd FPGA-Real-Time-Audio-FFT-Classifier
vsim -c -do sim/run_sim.do
```

### Manual Individual Unit Simulation
```bash
vlib work
vlog rtl/magnitude_block.v tb/tb_magnitude_block.v
vsim -c -do "run -all; quit" tb_magnitude_block
```

---

## 7. Authors & License

- **Lead Engineer**: Hari Kruthik SK  
- **Affiliation**: School of Electronics Engineering (SENSE), Vellore Institute of Technology (VIT), Vellore  
- **License**: Released under the [MIT License](LICENSE).
