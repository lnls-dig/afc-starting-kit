CMDSEP = ;

MAKE ?=		make
BASH ?=     bash
DEPMOD ?=   depmod

KERNEL_VERSION ?= $(shell uname -r)
AFC_GW_DIR = afc-gw
AFC_GW_SYN_DIR = $(AFC_GW_DIR)/hdl/syn/afc_v3/vivado/pcie_leds
AFC_GW_MAKEFILE = $(AFC_GW_SYN_DIR)/Makefile
FPGA_PCIE_DRIVER_DIR = fpga-pcie-driver
FPGA_PCIE_DRIVER_TESTS_DIR = $(FPGA_PCIE_DRIVER_DIR)/tests/pcie
FPGA_PROGRAMMING_DIR = fpga-programming

.PHONY: all gateware gateware_clea gen_gw_makefile clean_gw_makefile \
	driver driver_clean driver_install driver_uninstall driver_tools \
	driver_tools_clean install uninstall clean \
	clone_submodules clone_fpga_pcie_driver clone_afc_gw clone_fpga_programming

clone_submodules: clone_fpga_pcie_driver clone_afc_gw clone_fpga_programming

clone_fpga_pcie_driver:
	if [ ! -z "$(shell ls -A ${FPGA_PCIE_DRIVER_DIR})" ]; then \
		git submodule update --init --recursive -- $(FPGA_PCIE_DRIVER_DIR); \
	fi

clone_afc_gw:
	if [ ! -z "$(shell ls -A ${AFC_GW_DIR})" ]; then \
		git submodule update --init --recursive -- $(AFC_GW_DIR); \
	fi

clone_fpga_programming:
	if [ ! -z "$(shell ls -A ${FPGA_PROGRAMMING_DIR})" ]; then \
		git submodule update --init --recursive -- $(FPGA_PROGRAMMING_DIR); \
	fi

driver: clone_fpga_pcie_driver
	$(MAKE) -C $(FPGA_PCIE_DRIVER_DIR) all

driver_clean:
	$(MAKE) -C $(FPGA_PCIE_DRIVER_DIR) clean

# Install just the driver and lib, not udev rules
driver_install: driver
	$(MAKE) -C $(FPGA_PCIE_DRIVER_DIR) core_driver_install lib_driver_install etc_driver_install
	$(DEPMOD) -a $(KERNEL_VERSION)

driver_uninstall:
	$(MAKE) -C $(FPGA_PCIE_DRIVER_DIR) core_driver_uninstall lib_driver_uninstall etc_driver_uninstall

driver_tools:
	$(MAKE) -C $(FPGA_PCIE_DRIVER_TESTS_DIR) regAccess

driver_tools_clean:
	$(MAKE) -C $(FPGA_PCIE_DRIVER_TESTS_DIR) clean

gateware: clone_afc_gw gen_gw_makefile
	$(MAKE) -C $(AFC_GW_SYN_DIR)

gateware_clean: gen_gw_makefile
	$(MAKE) -C $(AFC_GW_SYN_DIR) clean

gen_gw_makefile: $(AFC_GW_MAKEFILE)
ifeq ($(wildcard $(AFC_GW_SYN_DIR)/Makefile),)
	$(BASH) -c "cd $(AFC_GW_SYN_DIR) && ./build_synthesis_sdb.sh && hdlmake -a makefile"
endif

clean_gw_makefile:
ifneq ($(wildcard $(AFC_GW_SYN_DIR)/Makefile),)
	$(BASH) -c "cd $(AFC_GW_SYN_DIR) && rm -f Makefile"
endif

install: driver_install

uninstall: driver_uninstall

clean: gateware_clean driver_clean driver_tools_clean
