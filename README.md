# FPGA Real-Time Audio Captioning & FFT Sound Classification System

[![Language: Verilog-2001](https://img.shields.io/badge/Language-Verilog--2001-blue.svg)]()
[![Target: Intel Cyclone IV](https://img.shields.io/badge/FPGA-EP4CE115F29C7-darkgreen.svg)]()
[![DSP: 512--pt FFT IP](https://img.shields.io/badge/DSP-Intel%20FFT%20MegaCore-purple.svg)]()
[![Simulation: ModelSim](https://img.shields.io/badge/Simulation-ModelSim%20Intel%20FPGA-orange.svg)]()

A synthesizable, hardware-accelerated real-time audio captioning and acoustic event classification architecture targeted for the **Altera/Intel Cyclone IV E (`EP4CE115F29C7`)** FPGA. 

The pipeline converts incoming digital audio into frequency-domain spectral energy distributions using a **512-point streaming Intel/Altera FFT MegaCore IP**, approximates spectral magnitude without floating-point units, detects characteristic acoustic frequency bands, and drives visual indicators (8-bit LEDs and dual 7-segment displays).

---

## 1. System Architecture

```
                    ┌──────────────────────────┐
                    │       sample_gen         │
                    │ (Synthetic Ramp Test Gen)│
                    └────────────┬─────────────┘
                                 │
                                 │ Avalon-ST (valid, ready, sop, eop)
                                 ▼
                    ┌──────────────────────────┐
                    │        fft_block         │
                    │  (512-Point Intel FFT IP)│
                    └────────────┬─────────────┘
                                 │
                                 │ Complex Data: [63:32] Re, [31:0] Im
                                 ▼
                    ┌──────────────────────────┐
                    │     magnitude_block      │
                    │   max(|Real|, |Imag|)    │
                    └────────────┬─────────────┘
                                 │
                                 │ 32-bit Spectral Magnitude
                                 ▼
                    ┌──────────────────────────┐
                    │     detection_block      │
                    │ (Alarm / Doorbell / Attn)│
                    └────────────┬─────────────┘
                                 │
                                 │ 2-bit Encoded Sound State
                                 ▼
                    ┌──────────────────────────┐
                    │       output_block       │
                    │ LEDR[7:0] & HEX0/1 Display│
                    └──────────────────────────┘
```

---

## 2. DSP & Spectral Specifications

- **Nominal Sample Rate ($F_s$)**: $48\text{ kHz}$
- **FFT Transform Length ($N$)**: $512\text{ points}$
- **Frequency Bin Resolution ($\Delta f$)**:
  $$\Delta f = \frac{F_s}{N} = \frac{48000\text{ Hz}}{512} = 93.75\text{ Hz / bin}$$

### Acoustic Classification Bands

| Sound Class | Characteristic Center Frequency | Target FFT Bins | Seven-Segment Indicator | Active LED Output |
| :--- | :---: | :---: | :---: | :---: |
| **ALARM** | $\sim 800\text{ Hz}$ | Bins $6 \to 10$ ($562.5\text{ Hz} \to 937.5\text{ Hz}$) | `'A'` (`7'b0001000`) | `LEDR[0]` (`8'b00000001`) |
| **DOORBELL** | $\sim 1000\text{ Hz}$ | Bins $8 \to 12$ ($750.0\text{ Hz} \to 1125.0\text{ Hz}$) | `'d'` (`7'b0100001`) | `LEDR[1]` (`8'b00000010`) |
| **ATTENTION / ALERT** | $\sim 3000\text{ Hz}$ | Bins $29 \to 35$ ($2718.7\text{ Hz} \to 3281.2\text{ Hz}$) | `'t'` (`7'b0000111`) | `LEDR[2]` (`8'b00000100`) |
| **SILENCE / NONE** | Ambient noise ($< \text{THRESHOLD}$) | — | `'n'` (`7'b0101011`) | All LEDs Off |

---

## 3. Engineering Decisions & Hardware Optimization

1. **Deterministic Phase 1 Verification (`sample_gen.v`)**:
   - Live I²S microphone audio was temporarily decoupled during initial pipeline bring-up to avoid non-deterministic acoustic noise during RTL timing validation.
   - The synthetic sample generator produces deterministic ramp frames across 512 samples with strict Avalon-ST `sop` (sample 0) and `eop` (sample 511) alignment.
2. **Hardware Magnitude Approximation**:
   - True Euclidean magnitude requires calculating $\sqrt{\text{Re}^2 + \text{Im}^2}$, requiring large DSP multipliers and iterative CORDIC/square-root hardware.
   - This architecture utilizes an $\alpha\text{-}\beta$ maximum estimator:
     $$\text{Mag} \approx \max(|\text{Re}|, |\text{Im}|)$$
   - Stripping IEEE-754 sign bits allows pure magnitude comparison within a single clock cycle.
3. **Race-Condition-Free Frame Evaluation**:
   - The detection block delays classification by one cycle (`eop_d`) after `eop` to ensure energy accumulators settle before threshold comparisons execute.

---

## 4. How to Simulate & Verify

Verify the Avalon-ST frame generator in ModelSim:
```bash
vlib work
vlog rtl/sample_gen.v tb/tb_sample_gen.v
vsim -c -do "run -all; quit" work.tb_sample_gen
```

Verify full system integration:
```bash
vlog rtl/sample_gen.v rtl/magnitude_block.v rtl/detection_block.v rtl/output_block.v rtl/top.v
```

---

## 5. Repository File Structure

```text
FPGA-Real-Time-Audio-FFT-Classifier/
├── README.md
├── .gitignore
│
├── rtl/
│   ├── top.v                             # Top-level integration module
│   ├── sample_gen.v                      # Deterministic 512-sample test generator
│   ├── fft_block.v                       # Avalon-ST wrapper for Intel FFT MegaCore
│   ├── magnitude_block.v                 # Lightweight spectral magnitude estimator
│   ├── detection_block.v                 # Energy accumulator & threshold classifier
│   └── output_block.v                    # LED array & dual 7-segment display driver
│
├── tb/
│   └── tb_sample_gen.v                   # Frame boundary & handshaking testbench
│
├── constraints/
│   └── DE2_115_pin_assignments.csv      # Intel DE2-115 Cyclone IV board pin mapping
│
└── docs/
    ├── FPGA_Audio_Classifier_Review1.pptx # Architectural review presentation
    ├── PIANO NOTE DETECTION USING FFT IN FPGA.pdf
    └── FPGA_TASK_4.pdf
```
