# Futurehome CUBE-2v0-EU
The contents in this repository is provided "as is". It MUST NOT be considered 
complete, accurate, or even fit for any paricular purpose. Things may be different
and/or work differently than described. You assume full responsibility for any 
risks, injuries, damages or other consequences that may result from even taking
into consideration anything presented.

## Hardware highlights
* Built around the [Dusun DSOM-010R System-on-Module](https://www.dusuniot.com/product/dsom-010r-rk3328-som/) ("SoM")
* RK3328 SoC
* 2 gigabytes of RAM
* 8 gigabytes of eMMC storage
* 100mbit ethernet using the RK3328 built-in PHY, an external PHY for using the rk3328 gigabit MAC is not included in the board design
* 1x USB-C port for powering the system (480mbit/s USB2, OTG capable)
* 1x USB type A port (USB3 5gbit/s in host mode, 480mbit/s in OTG mode)
* On-board GL850G USB 2.0 hub controller chip, used to connect on-board USB-to-UART bridges
* Battery backed PCF85063ATT RTC connected to the I2C1 bus
* EFR32MG12 module connected to CP2102N USB<->UART bridge
* EFR32BG22 module connected to SoM UART0 (no CTS/RTS)
* ZGM130S module connected to SoM UART1 (no CTS/RTS)
* RGBW LED module, driven by a TM1929 LED driver chip.
* UART2 breaks out to debug test points and pads (TEST_UART_*).
* CH340g USB<->UART bridge, accessible via test points and solder pads (CFG_UART_*).

## Entering Maskrom mode on a stock system
The factory installed U-Boot will enter loader mode and be visible over USB to a
computer if the function button is pressed when the device is starting to boot.
Typically this means holding the function button as the USB-C cable is inserted.
The device can then be rebooted into Maskrom mode using the **rkdeveloptool**
utility with an argument of **rd 3** where *rd* means "reset device" and *3* means
"into maskrom mode".
Next up is running **rkdeveloptool db \[name-of-your-bootloader-file\]** which
will essentially upload a bootloader file from a computer into the memory of the
device and run it. This can be the traditional "usbplug" image which has been
the go-to solution for flashing software onto rockchip devices, or other bootloaders.

## Rambooted U-Boot
After [some time](https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commits/ramboot-v1) [in the](https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commits/ramboot-v2) [making](https://source.denx.de/u-boot/contributors/kwiboo/u-boot/-/commits/ramboot-v3), U-Boot v2026.01 introduced a feature for Rockchip devices called *ramboot* which makes it possible
to load an U-Boot image into RAM and run it from there (just like the "usbplug")
using *rkdeveloptool*.

This repository provides a Makefile, *cube2v0-usb-mass-storage-rambootloader.make*,
which orchestrates the building of a ramboot-enabled U-Boot for the Futurehome
cube-2v0-eu, configured to automatically enter USB Mass Storage (UMS) mode
using the USB-C port.

Essentially, the internal storage of the smarthub will be presented to a host
computer as a USB storage device, similar to how the cube-1 microUSB port
allows access to the eMMC storage of that device.

### Building ramboot-enabled U-Boot
Aarch64 cross compilation toolchain needs to be present on the system, in
addition to standard tools like *make*, *git* and *install*. From there, it
should just be a matter of running *make*, specifying the makefile to use: 

```sh
make -f cube2v0-usb-mass-storage-rambootloader.make
```

## U-Boot mode selection script
The contents of **futurehome-cube-2v0-eu-bootmode-script.cmd** is intended to 
prepend any *actual* boot script. The purpose of this script is to allow the 
device to enter various modes instead of booting an operating system. These 
modes makes the device present itself as various peripherals to a computer 
through the USB-C port. In order to use the script to enter into a mode, the
function button next to the ethernet port can be held and released at the right
time as the device is preparing to boot. The case LED will indicate the right
time to release the button by changing the colour of the light.
The device can also reboot into a mode from Linux by giving the name of the 
wanted mode as an argument to the reboot command.

### Mode: Bootloader console
The U-Boot console can be entered either by releasing the funtion button when 
the case LED shines white, or by issuing the command "reboot bootloader" in Linux.

### Mode: UMS
In this mode, U-Boot will make the smarthub present its internal EMMC storage as
a USB mass storage device to a host computer.
This mode can be entered either by issuing the command "reboot ums" in Linux,
or the function button can be released when the case LED shines orange.

### Mode: U-Boot rockusb
This mode can be entered from Linux by issuing the command "reboot loader", or
the function button can be released when the case light shines purple.

### Hardware/"bare metal" maskrom mode
This mode can be entered either by releasing the function button while the case
LED is shining cyan/teal-ish, or by issuing the command "reboot maskrom" in Linux.

## SoM pins
The following list is a non-complete outline of how the pins on the SoM appears
to be connected to the rest of the board. Assume there being errors in the list.

* Pin 13: GPIO0_A2. Connected to HM4610H chip (marked DOOHAW). Active-high. Enables power for the USB type A port. 
* Pin 15: GPIO0_A0. Connected to TP38 and bottom-of-case connector.
* Pin 16: GPIO0_D6. Connected to TP37 and bottom-of-case connector.
* Pin 17: GPIO0_D3. Connected to TP39 and bottom-of-case connector.
* Pin 18: GPIO0_A4. Connected to TP36 and bottom-of-case connector.
* Pin 46: GPIO1_A5. EFR32MG12 power enable line.
* Pin 48: GPIO1_A0. EFR32MG12 nRESET line.
* Pin 52: GPIO1_A4. Connected to the reset pin (pin13) of the GL850G USB hub. Exposed through TP52.
* Pin 53: GPIO1_A3. connected to EFR32MG12 module, pin PA4, through resistor R154.
* Pin 56: UART0 TX. Exposed through TP54. Connected to EFR32BG22 UART RX (PA06)
* Pin 57: UART0 RX. Exposed through TP53. Connected to EFR32BG22 UART TX (PA05)
* Pin 88: UART2 TX. Connected to TP5 and solder pad TEST_UART_TX
* Pin 89: UART2 RX. Connected to TP4 and solder pad TEST_UART_RX
* Pin 117: GPIO2_C1. EFR32BG22 power enable line.
* Pin 118: GPIO2_C2. EFR32BG22 nRESET line. Exposed through TP16 and solder pad BT_RESET
* Pin 119: GPIO2_B7. ZGM130S power enable line.
* Pin 121: I2C0_SDA. Exposed through TP40 and bottom-of-case connector.
* Pin 122: I2C0_SCC. Exposed through TP41 and bottom-of-case connector.
* Pin 124: UART1 TX. Connected to ZGM130S chip. Exposed through TP43.
* Pin 126: UART1 RX. Connected to ZGM130S chip. Exposed through TP44.
* Pin 127: GPIO3_A7. ZGM130S nRESET line. Exposed through TP22 and solder pad ZW_RESET
* Pin 132: GPIO3_A0. Function button. Active-low, externally pulled high.

**Other SoM pins**: Dusun IOT has documented the 132 lines found along the edges of
the SoM in a data sheet accessible through their website. Note that many pins are
not used at all in the cube-2v0-eu board design.

## Utilizing the case light
The device features a RGBW LED module, which shines its light through a bit of
clear-ish plastic towards a corner of the logo on the outside of the case.
It is wired to a TM1929 LED driver, which is made by Titan Micro Electronics.

The LED driver chip accepts commands through the I2C0 bus, utilizing the i2c 
address 0x23. There are no drivers for abstracting interactions with this chip,
it must be controlled by sending I2C commands either with the **i2c** command
in U-Boot, or with the **i2ctransfer** program in Linux.

### Example command in Linux:
```shell
i2ctransfer -y 0 w2@0x23 0x4 0x0
```

#### Explanaion of the above i2ctransfer command:
* The -y flag tells the tool to not prompt for confirmation before sending the command.
* The zero is the number of the i2c bus we will be utilizing to talk to the chip.
* "w2" tells i2ctransfer that we will be writing two bytes.
* "@0x23", means that we will be talking to the chip which can be found **AT** the i2c address **0x23**.
* "0x4" is the identifier/address of the register that we will be writing to.
* "0x1" is the value we will be writing to said register.

### Example command in U-Boot:
```shell
i2c bus 0
i2c mw 0x23 0x4 0x6
```
Again, 0x23 is the address of the chip, 0x4 is the register we are writing to,
and 0x6 is the value to be written.

#### Registers used to control LED brightness
* 0x2: The white LED (driver line 1, pin 4 on the TM1929 chip)
* 0x3: The blue LED (driver line 2, pin 5 on the TM1929 chip)
* 0x4: The green LED (driver line 3, pin 6 on the TM1929 chip)
* 0x5: The red LED (driver line 4, pin 7 on the TM1929 chip)

The TM1929 is an 18-channel LED driver, so the registers goes all the way 
through 0x0F up to 0x13. There are no LEDs connected to these other lines, so
unless you solder your own LEDs to the unused driver pins, there really is no
point in thinking about them.

#### Values for the LED brightness registers
* 0x0: LED is off
* 0x1: LED is on, lowest brightness
* 0x2: LED is on, one step brighter than 0x1
... and so on ...
* 0x7F: LED is on, maximum brightness

It seems that there are 127 steps, because from value 0x80 we basically start
over from the led being off again, all the way up to max (same brightness as
with 0x7F) at value 0xFF.

* 0x80: LED is off
* 0x81: LED is on, lowest brightness
* 0x82: LED is on, one step brighter than 0x81
... and so on ...
* 0xFF: LED is on, maximum brightness

## Unbricking the device
If the installed operating system or U-Boot on the device is totally messed up,
there *is* a way to possibly recover/unbrick the device. The RK3328 SoC is 
apparently designed to enter Maskrom mode if no bootable storage media is 
detected upon boot. So how can SoC NOT detect the onboard eMMC when powered on?
Apparently by pulling the EMMC_KEY line at SoM pin 81 high by bridging it to SoM
pin 109 (3v3) for a couple of seconds as the device is being connected to a USB
port which can provide enough power for the device to run.

## A note about RTCs
The cube-2v0-eu actually contains *two* RTCs; a Rockchip one on the DSOM-010r,
and a separate NXP PCF85063ATT RTC chip.
The NXP RTC is backed by a battery, the Rockchip one is not. In other words;
the Rockchip RTC will lose track of time when the device is disconnected from
power, the NXP RTC will not.
