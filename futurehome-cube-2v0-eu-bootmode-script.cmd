# U-Boot script for handling (re)booting the Futurehome cube-2v0-eu into various
# modes other than an installed operating system.
# SPDX-License-Identifier: GPL-2.0+

# Select the I2C0 bus as that is where the LED driver is attached and turn off
# all LED driver channels to get them to a known state
i2c dev 0
i2c mw 0x23 0x2 0x0
i2c mw 0x23 0x3 0x0
i2c mw 0x23 0x4 0x0
i2c mw 0x23 0x5 0x0

# Dim down the LEDs
i2c mw 0x23 0x0 0x0

# Values are written to memory for comparison purposes
mw.l 0x30800000 0x5242c300 1
if cmp.l 0x30800000 0xFF1005C8 1 ; then 
    echo "Reboot mode flag detected, normal reboot..."
fi

mw.l 0x30800000 0x5242c309 1
if cmp.l 0x30800000 0xFF1005C8 1 ; then 
    echo "Bootloader console starting, caused by detected reboot flag"
    i2c mw 0x23 0x2 0x22
    i2c mw 0x23 0x0 0x1
    mw.l 0xFF1005C8 0x5242c300 1
    setenv stderr serial,usbacm
    setenv stdin serial,usbacm
    setenv stdout serial,usbacm
    exit
fi

mw.l 0x30800000 0x5242c30C 1
if cmp.l 0x30800000 0xFF1005C8 1 ; then 
    echo "U-Boot usb mass storage mode starting, caused by detected reboot flag"
    i2c mw 0x23 0x4 0x4
    i2c mw 0x23 0x5 0x20
    i2c mw 0x23 0x0 0x1
    mw.l 0xFF1005C8 0x5242c300 1
    ums 0 mmc 0
    echo "Usb storage mode finished, resetting system"
    i2c mw 0x23 0x4 0x0
    i2c mw 0x23 0x5 0x0
    reset
fi

# No block here for harware maskrom mode as that case is not handled by U-Boot

mw.l 0x30800000 0x5242c301 1
if cmp.l 0x30800000 0xFF1005C8 1 ; then 
    echo "U-Boot rockusb mode starting, caused by detected reboot flag"
    i2c mw 0x23 0x3 0x18
    i2c mw 0x23 0x5 0x6
    i2c mw 0x23 0x0 0x1
    mw.l 0xFF1005C8 0x5242c300 1
    rockusb 0 mmc 0
    i2c mw 0x23 0x3 0x0
    i2c mw 0x23 0x5 0x0
    reset
fi

# Function button handling section
gpio read function_button 96
if test "${function_button}" = "0"; then
    echo "Release button now to enter bootloader console"
    i2c mw 0x23 0x2 0x22
    sleep 2

    gpio read function_button 96
    if test "${function_button}" = "1"; then
        echo "Bootloader console mode starting, caused by function button"
        i2c mw 0x23 0x0 0x1
        setenv stderr serial,usbacm
        setenv stdin serial,usbacm
        setenv stdout serial,usbacm
        exit
    else
        echo "Release button now to make eMMC storage available over USB..."
        i2c mw 0x23 0x2 0x0
        i2c mw 0x23 0x4 0x4
        i2c mw 0x23 0x5 0x20
        sleep 2
    fi

    gpio read function_button 96
    if test "${function_button}" = "1"; then
        echo "U-Boot usb mass storage mode starting, caused by function button"
        i2c mw 0x23 0x0 0x1
        ums 0 mmc 0
        i2c mw 0x23 0x4 0x0
        i2c mw 0x23 0x5 0x0
        reset
    else
        echo "Release button now to start U-Boot rockusb session"
        i2c mw 0x23 0x3 0x18
        i2c mw 0x23 0x4 0x0
        i2c mw 0x23 0x5 0x6
        sleep 2
    fi

    gpio read function_button 96
    if test "${function_button}" = "1"; then
        echo "U-Boot rockusb mode starting, caused by function button"
        i2c mw 0x23 0x0 0x1
        rockusb 0 mmc 0
        i2c mw 0x23 0x3 0x0
        i2c mw 0x23 0x5 0x0
    else
        echo "Release button now to enter hardware maskrom mode..."
        i2c mw 0x23 0x3 0x8
        i2c mw 0x23 0x4 0x10
        i2c mw 0x23 0x5 0x0
        sleep 2
    fi

    gpio read function_button 96
    if test "${function_button}" = "1"; then
        echo "Entering hardware maskrom mode..."
        i2c mw 0x23 0x0 0x1
        mw.l 0xFF1005C8 0xEF08A53C 1
        reset
    else
        echo "Function button was not released, resetting system..."
        i2c mw 0x23 0x3 0x0
        i2c mw 0x23 0x4 0x0
        reset
    fi

fi

# Normal boot, set LED yellow
i2c mw 0x23 0x4 0x16
i2c mw 0x23 0x5 0x13
i2c mw 0x23 0x0 0x1

#
# End of Futurehome cube-2v0-eu boot mode script
#