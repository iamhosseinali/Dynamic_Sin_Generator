# Sine_Wave_Gen

## Overview

`Sine_Wave_Gen` is a synthesizable VHDL module that generates an 8-bit sine wave using a precomputed lookup table. The frequency of the output signal is configurable through a 32-bit input vector. This module is designed to be compatible with AXI Stream (AXIS) interfaces.

>  **Inspired by**: [SINE_WAVE_VHDL_GENERATOR](https://github.com/iamhosseinali/SINE_WAVE_VHDL_GENERATOR)

---

## Features

- Outputs 8-bit signed sine wave samples
- Uses a 1024-entry sine lookup table
- Configurable output frequency via 32-bit `Config` input
- Supports runtime frequency reconfiguration

---

## Ports

| Signal         | Direction | Width | Description |
|----------------|-----------|-------|-------------|
| `M_AXIS_ACLK`  | `in`      | 1     | Clock input |
| `M_AXIS_ARESETN` | `in`    | 1     | Active-low reset |
| `M_AXIS_tDATA` | `out`     | 8     | Sine wave output (signed) |
| `M_AXIS_tVALID`| `out`     | 1     | Indicates valid output |
| `Config`       | `in`      | 32    | Control input: <br>Bit 31: Valid flag <br>Bits 30:0: `IP_INPUT_FREQ / OUT_FREQ / 1024` |

---

## Generics

| Name                            | Default       | Description |
|---------------------------------|---------------|-------------|
| `IP_INPUT_FREQUENCY`           | `100_000_000` | Input clock frequency (Hz) |
| `DEFAULT_OUTPUT_SIGNAL_FREQUENCY` | `50`        | Default sine output frequency (Hz) |

>  Maximum default output frequency is limited by:  
> `DEFAULT_OUTPUT_SIGNAL_FREQUENCY <= IP_INPUT_FREQUENCY / 2048`
>  But you can reach (IP_INPUT_FREQUENCY / 1024) by setting Config(30:0) to 0 at runtime. 

## Behavior

1. `Config(30:0)` is used to dynamically change the output frequency when `Config(31)` is high.

2. A block RAM-styled lookup table stores precomputed sine values.



# Clone and Recreation
This project was built with vivado 2018.2, so make sure you are using this exact version.  
PL projects often come with some custom IPs, these IPs can be HDL or HLS, sth like this: 
```
ip_repo
    ├───HDL
    │   ├───HDL_IP_1
    │   └───HDL_IP_2
    └───HLS
        ├───HLS_IP_1
        └───HLS_IP_2
```
> This is the recommended directory structure of your custom IPs. 

After cloning and before running the project_name.tcl to recreate the whole vivado project, firstly recreate the HLS IPs projects. 

## Recreating the PL Project
In vivado command prompt or TCL Consol of the GUI run: 

``` source c:\...\project_name\project_name.tcl ```

Wait untill recreation is completed. 

Refer to this [repo](https://github.com/iamhosseinali/vivado-git) and look for the right branch based on your vivado version to use vivado and git together like the project above.

