# Makefile for producing a build of U-Boot for the Futurehome cube-2v0-eu which
# can be uploaded to and booted from RAM through rkdeveloptool when the device
# is in maskrom mode. Configured to immediately start UMS mode, making the
# internal eMMC storage available to a host computer as a USB mass storage
# device. Aarch64 cross compilation toolchain needed.

.DEFAULT_GOAL := cube2v0-usb-mass-storage-rambootloader.bin

ATF_GIT_TAG := v2.13.0
UBOOT_GIT_TAG := v2026.01
DDR_BLOB ?= rk3328_ddr_933MHz_v1.16.bin

WORKDIR ?= /tmp/cube2v0-usb-mass-storage-rambootloader-workdir
WORKDIR_UBOOT := $(WORKDIR)/u-boot_${UBOOT_GIT_TAG}
WORKDIR_ATF := $(WORKDIR)/arm-trusted-firmware_$(ATF_GIT_TAG)
WORKDIR_DDRBLOB := $(WORKDIR)/$(DDR_BLOB)
NPROCS := $(shell nproc || printf 1)

cube2v0-usb-mass-storage-rambootloader.bin:
	@ if [ ! -d $(WORKDIR_ATF) ]; then \
		echo "# ATF sources needed, downloading..." ; \
		git clone -b ${ATF_GIT_TAG} --depth 1 https://github.com/ARM-software/arm-trusted-firmware $(WORKDIR_ATF) ; \
	fi

	@ if [ ! -f $(WORKDIR)/1000-rk3328-add-efuse-initialization-in-ATF.patch ]; then \
		echo "# Sourcing ATF efuse init patch from Armbian..." ; \
		wget --directory-prefix=$(WORKDIR)/ -q -nc https://raw.githubusercontent.com/armbian/build/refs/heads/main/patch/atf/atf-rockchip64/v2.13/1000-rk3328-add-efuse-initialization-in-ATF.patch ; \
	fi
	@if [ ! -f $(WORKDIR_ATF)/plat/rockchip/rk3328/drivers/efuse/efuse.c ]; then \
		echo "# Applying efuse init patch..." ; \
		cd $(WORKDIR_ATF) && git apply ../1000-rk3328-add-efuse-initialization-in-ATF.patch ; \
	fi

	@if [ ! -f $(WORKDIR_ATF)/build/rk3328/release/bl31/bl31.elf ]; then \
		echo "# Building BL31..." \
		&& cd $(WORKDIR_ATF) \
		&& make realclean \
		&& CROSS_COMPILE=aarch64-linux-gnu- make -j $(NPROCS) PLAT=rk3328 bl31 ; \
	fi

	@ if [ ! -f $(WORKDIR_DDRBLOB) ]; then \
		echo "# Sourcing RAM init blob for the build..." ; \
		wget -q -nc -O "$(WORKDIR_DDRBLOB)" "https://github.com/armbian/rkbin/raw/refs/heads/master/rk33/$(DDR_BLOB)" ; \
	fi

	@ if [ ! -d $(WORKDIR_UBOOT) ]; then \
		echo "# U-Boot sources needed, downloading..." ; \
		git clone -b $(UBOOT_GIT_TAG) --depth 1 https://github.com/u-boot/u-boot.git $(WORKDIR_UBOOT) ; \
	fi

	@ if [ ! -f $(WORKDIR)/RK3328MINIALL.ini ]; then \
		echo "# Sourcing RK3328MINIALL.ini from Kwiboo..." ; \
		wget --directory-prefix=$(WORKDIR)/ -q -nc https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/raw/d09dde0b70430fbfb8735de5aa93761619f20265/RK3328MINIALL.ini ; \
	fi

	@ if [ ! -f $(WORKDIR)/boot_merger ]; then \
		echo "# Sourcing Rockchip boot_merger tool..." ; \
		wget --directory-prefix=$(WORKDIR)/ -q -nc https://github.com/rockchip-linux/rkbin/raw/refs/heads/master/tools/boot_merger \
		&& chmod +x $(WORKDIR)/boot_merger ; \
	fi

	# Installing board support files into u-boot source tree...
	@ install -m 0644 rk3328-futurehome-cube-2v0-eu.dts $(WORKDIR_UBOOT)/dts/upstream/src/arm64/rockchip/rk3328-futurehome-cube-2v0-eu.dts
	@ install -m 0644 rk3328-futurehome-cube-2v0-eu-u-boot.dtsi $(WORKDIR_UBOOT)/arch/arm/dts/rk3328-futurehome-cube-2v0-eu-u-boot.dtsi
	@ install -m 0644 futurehome-cube-2v0-eu_defconfig $(WORKDIR_UBOOT)/configs/futurehome-cube-2v0-eu_defconfig

	# Creating U-Boot config file...
	@ echo "CONFIG_BOOTDELAY=0" > $(WORKDIR_UBOOT)/board/rockchip/cube2v0-bootcmd.config
	@ echo 'CONFIG_BOOTCOMMAND="i2c dev 0; i2c mw 0x23 0x0 0x1; i2c mw 0x23 0x2 0x0; i2c mw 0x23 0x3 0x0; i2c mw 0x23 0x4 0x4; i2c mw 0x23 0x5 0x20; ums 0 mmc 0; i2c mw 0x23 0x4 0x0; i2c mw 0x23 0x5 0x0"' >> $(WORKDIR_UBOOT)/board/rockchip/cube2v0-bootcmd.config
	@ echo "# CONFIG_ENV_OFFSET is not set" >> $(WORKDIR_UBOOT)/board/rockchip/cube2v0-bootcmd.config
	@ echo "CONFIG_ENV_SIZE=0x8000" >> $(WORKDIR_UBOOT)/board/rockchip/cube2v0-bootcmd.config
	@ echo "# CONFIG_ENV_IS_IN_MMC is not set" >> $(WORKDIR_UBOOT)/board/rockchip/cube2v0-bootcmd.config
	@ cd $(WORKDIR_UBOOT) && make futurehome-cube-2v0-eu_defconfig rockchip-ramboot.config cube2v0-bootcmd.config

	# Building U-Boot...
	@ cd $(WORKDIR_UBOOT) \
	&& make clean \
	&& ROCKCHIP_TPL=$(WORKDIR_DDRBLOB) BL31=$(WORKDIR_ATF)/build/rk3328/release/bl31/bl31.elf CROSS_COMPILE=aarch64-linux-gnu- make -j $(NPROCS)

	# Generating bootloader .bin file...
	@ cd $(WORKDIR_UBOOT) \
	&& cp $(WORKDIR)/RK3328MINIALL.ini . \
	&& ../boot_merger ./RK3328MINIALL.ini

	install -m 0644 $(WORKDIR_UBOOT)/u-boot-rockchip-rk3328-loader.bin $@
	
	echo ""
	# Done!
	# USB mass storage bootloader file should now have appeared at $@

