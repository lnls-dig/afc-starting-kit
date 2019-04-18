# AFC Starting Kit

## Project Folder Organization

```
*
|
|-- afc-gw:
|    |   AFC example gateware
|    |
|-- fpga-pcie-driver:
|    |   AFC linux driver and base libraries
|    |
|-- fpga-programming:
|    |   AFC FPGA programming scripts
```

## Cloning Instructions


To clone the whole repository use the following command:

```bash
    git clone --recursive https://github.com/lnls-dig/afc-starting-kit
```

For older versions of Git (<1.6.5), use the following:

```bash
    git clone https://github.com/lnls-dig/afc-starting-kit
    git submodule init
    git submodule update
```

To update each submodule within this project use:

```bash
    git submodule foreach git submodule update --init --recursive
```

## Build Instructions

1. Be sure you are using [OpenMMC](https://github.com/lnls-dig/openMMC) as MMC firmware.
The MMC is a microcontroller on the AFC board that controls power but it also controls
how clocks are distributed.  This starting kit assume the same clock distribution as
the one set by OpenMMC.

2. Build FPGA bitstream

```bash
    make gateware
```

3. Program the AFC with the generated gateware

```bash
    cd fpga-programming
    ./vivado-prog.py --svf=afc-scansta.svf --prog_serial --host_url=<mch_ip>:<board_port_number> \
        --bit=../afc-gw/hdl/syn/afc_v3/vivado/afc_pcie_leds/afc_pcie_leds.runs/impl_1/afc_pcie_leds.bit
```

4. Build driver/libs

```bash
    make driver
    sudo make driver_install
```

4. Build driver tool for FPGA accessing

```bash
    make driver_tools
```

The FPGA accessing tool should be available at: `fpga-pcie-driver/tests/pcie/bin/regAccess`

5. Read/Write LEDs to the AFC


```bash
    cd fpga-pcie-driver/tests/pcie/bin
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data <data_to_be_written> --address <base_address>
```

To control the AFC front panel LEDs we use the base address `0x00100100`, which is
the base address of a gpio module.

In order to enable an LED, you can do the following:

```bash
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data 0x1 --address 0x00100104
```

So, to enable the first LED:

```bash
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data 0x1 --address 0x00100104
```

The second one:

```bash
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data 0x2 --address 0x00100104
```

And the third one:

```bash
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data 0x4 --address 0x00100104
```

To clear the LED just replace the address with `--address 0x00100100`

6. Some words about the gateware

The `pcie_cntr` PCIe bridge defines 3 BARs: BAR0 (2KB) for registers, BAR2 (1MB)
for DDR and BAR4 (512KB) for a wishbone bus.
Both the DDR and WB areas are a window on a larger area.  Register 0x1c defines
the DDR page while register 0x24 defines the WB page.  Within the WB space, addresses
are shifted by 3.  So the first word can be read at address 0, but the second word
has to be read at address 0x20 (4 * 8).  Thus only 64KB of the WB space is visible
through the PCIe bridge.

In the starting kit, there is a WB crossbar behind the PCIe bridge.
At address 0x000000 there are the SDB data (a ROM that describe the hardware behind
the crossbar) and at address 0x100000 there is the `dbe_periph` core.  So if you
want to access to that core, register 0x24 has to be set to 0x20.

The `dbe_periph` also consists of a crossbar, with an UART at address 0x000, a gpio
core that controls the led at address 0x100, another gpio core for the buttons at
address 0x200, a timer at address 0x300 and the SDB at address 0x400.

The gpio core has four registers:
* `codr` at address 0x00: a 1 clears the corresponding bit
* `sodr` at address 0x04: a 1 sets the corresponding bit.
* `ddr` at address 0x08: define the direction of each port, but this is not used
  (ports are always outputs).
* `psr` at address 0x0c: to read the state of the gpios.
