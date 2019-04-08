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

1. Build FPGA bitstream

```bash
    make gateware
```

2. Program the AFC with the generated gateware

```bash
    cd fpga-programming
    ./vivado-prog.py --svf=afc-scansta.svf --prog_serial --host_url=<mch_ip>:<board_port_number> \
        --bit=../afc-gw/hdl/syn/afc_v3/vivado/afc_pcie_leds/afc_pcie_leds.runs/impl_1/afc_pcie_leds.bit
```

3. Build driver/libs

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
    ./regAccess --devicefile /dev/fpga-<slot_number> --write -n 4 --data 0x1 --address <0x00100100 + 0x4*(LED number)>
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
