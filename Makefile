########## Install locations ##########
GCCBASE=/usr/bin
XMCLIBBASE=/opt/XMClib

USBBASE=./USB

########## Shortcuts for the programs to use ##########
# C compiler, generates machine code from C code and optimizes it. Takes C source files *.c and ouputs object files *.o.
CC = $(GCCBASE)/arm-none-eabi-gcc
# Linker, replaces symbolic names by addresses. Takes object files *.o and creates executables.
LD = $(GCCBASE)/arm-none-eabi-gcc
# Archiver, create, modify or extract files from archives. Necessary e.g. to extract single functions from libraries.
AR = $(GCCBASE)/arm-none-eabi-ar
# Assembly compiler, generates machine code from assembly code. Takes ASM source files *.s and outputs object files *.o.
AS = $(GCCBASE)/arm-none-eabi-as
# Objcopy, copies or translates to different formats object files.
OC = $(GCCBASE)/arm-none-eabi-objcopy
# Displays information about object files.
OD = $(GCCBASE)/arm-none-eabi-objdump
# Prints size of executables
SZ = $(GCCBASE)/arm-none-eabi-size
# Debugger for command line debugging
DB = $(GCCBASE)/arm-none-eabi-gdb

########## Project options ##########
# Project name (for linker description filename)
LDname=pwm_modification
# Which version of XMClib to use (for easy switching to debug version dependent issues)
XMCLIBDIR=XMC_Peripheral_Library_v2.0.0
# Specify device series, package and FLASH size separately to derive device dependent file names more easily
XMCseries=4500
XMCpackage=F100
XMCsize=1024

# Where to find CMSIS, device and XMClib header files
CFLAGS  = -I$(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Include/
# Where to find device specific header files
CFLAGS += -I$(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Infineon/XMC$(XMCseries)_series/Include/
# Where to find XMClib headers
CFLAGS += -I$(XMCLIBBASE)/$(XMCLIBDIR)/XMClib/inc/
# Where to find USB Headers
CFLAGS += -I./
CFLAGS += -I$(USBBASE)/
CFLAGS += -I$(USBBASE)/Core/
CFLAGS += -I$(USBBASE)/Core/XMC4000/
# Which device
CFLAGS += -DXMC$(XMCseries)_$(XMCpackage)x$(XMCsize)
# Which core architecture
CFLAGS += -mcpu=cortex-m4 -mfloat-abi=softfp -mfpu=fpv4-sp-d16 -mthumb
# Debug level and format
CFLAGS += -g3 -gdwarf-2 
# Compile without linking
CFLAGS += -c
# Enable standard warnings
CFLAGS += -Wall
# Write separate *.lst file for each source
CFLAGS += -Wa,-adhlns="$@.lst"
# Until here all options are also necessary for compiling startup_XMC4500.S
SFLAGS = $(CFLAGS)
# Put functions into separate sections, so they can be omitted by linker if unused
CFLAGS += -ffunction-sections
# Optimisation level, Debug level and type, language dialect
CFLAGS += -O0 -std=gnu99
# Option for assembly compilation
SFLAGS += -x assembler-with-cpp
# Tell the linker to use our own linker script and startup files
LFLAGS  = -T$(LDname).ld -nostartfiles
# Where to find the precompiled math libraries
LFLAGS += -L$(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Lib/GCC/
# Create a map file
LFLAGS += -Wl,-Map,"$@.map"
# Also tell the linker core architecture
LFLAGS += -mcpu=cortex-m4 -mthumb
# Inform about debug info
LFLAGS += -g3 -gdwarf-2

########## Project files ##########
# Always give the object files, not the source files, i.e. myproject.o instead of myproject.c
# First of all we need the start up files
SOBJS = startup_XMC$(XMCseries).o system_XMC$(XMCseries).o
# And the LibcStubs
LCOBJS= System_LibcStubs.o
# Then of course our own source files
OBJS  = main.o
OBJS += pwm.o
OBJS += projectGpio.o
OBJS += delay.o
OBJS += timerUtility.o

OBJS += VirtualSerial.o
OBJS += Descriptors.o

# Finally we probably need some library files
LOBJS  = xmc4_scu.o
LOBJS += xmc4_gpio.o
LOBJS += xmc_ccu4.o
LOBJS += xmc_usbd.o

# USB Files
USB_CORE_OBJS     = ConfigDescriptors.o Events.o HostStandardReq.o USBTask.o
USB_CORE_DEV_OBJS = EndpointStream_XMC4000.o Endpoint_XMC4000.o USBController_XMC4000.o
USB_CLASS_OBJS    = CDCClassDevice.o

USB_CORE_OBJSD      = $(USB_CORE_OBJS:%.o=$(USBBASE)/Lib/Core/%.o)
USB_CORE_DEV_OBJSD  = $(USB_CORE_DEV_OBJS:%.o=$(USBBASE)/Lib/Core/Dev/%.o)
USB_CLASS_OBJSD		= $(USB_CLASS_OBJS:%.o=$(USBBASE)/Lib/Class/%.o)
# Define directories to put above files (no need to change)
BINDIR = bin
LIBDIR = Lib
SUPDIR = Startup
# Complement paths to SOBJS and LOBJS
LOBJSD = $(LOBJS:%.o=${LIBDIR}/%.o)
LCOBJSD = $(LCOBJS:%.o=${LIBDIR}/%.o)
SOBJSD = $(SOBJS:%.o=${SUPDIR}/%.o)

########## Set the rules which specify how to make the target ##########
all: ${BINDIR}/main.elf ${BINDIR}/main.lst

%.elf: $(OBJS) $(LOBJSD) $(LCOBJSD) $(SOBJSD) $(USB_CORE_OBJSD) $(USB_CLASS_OBJSD) $(USB_CORE_DEV_OBJSD) $(LDname).ld
	mkdir -p ${BINDIR}
	$(LD) $(LFLAGS) -o $@ $(OBJS) $(LOBJSD) $(LCOBJSD) $(SOBJSD) $(USB_CORE_OBJSD) $(USB_CLASS_OBJSD) $(USB_CORE_DEV_OBJSD)
	-@echo ""
	$(SZ) $@
	-@echo ""

program: ${BINDIR}/main.hex JLinkCommands
	JLinkExe -Device XMC$(XMCseries) -If SWD -Speed 1000 -CommanderScript JLinkCommands

debug: ${BINDIR}/main.elf GDBCommands
	echo "##### Debug session started at $(date) #####" >JLinkLog
	JLinkGDBServer -device XMC$(XMCseries) -endian little -if SWD -speed 1000 -halt -logtofile -log JLinkLog -silent -vd &
	sleep 1
	$(DB) -command=GDBCommands -tui
	killall JLinkGDBServer

%.bin: %.elf
	$(OC) -O binary $< $@

%.hex: %.elf
	$(OC) -O ihex $< $@

%.lst: %.elf
	$(OD) -h -S $< > $@

# Compile object files
${SUPDIR}/startup_XMC$(XMCseries).o: ${SUPDIR}/startup_XMC$(XMCseries).S
	$(CC) $(SFLAGS) -o $@ $<

${USBBASE}/Lib/Class/%.o: ${USBBASE}/Class/Device/%.c
	mkdir -p ${USBBASE}/Lib/Class
	$(CC) $(CFLAGS) -o $@ $<

${USBBASE}/Lib/Core/%.o: ${USBBASE}/Core/%.c
	mkdir -p ${USBBASE}/Lib/Core
	$(CC) $(CFLAGS) -o $@ $<

${USBBASE}/Lib/Core/Dev/%.o: ${USBBASE}/Core/XMC4000/%.c
	mkdir -p ${USBBASE}/Lib/Core/Dev
	$(CC) $(CFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# If the linker or a library or a start-up file is missing, copy it from the respective source directory
${LIBDIR}/%.c:
	mkdir -p ${LIBDIR}
	cp -n $(XMCLIBBASE)/$(XMCLIBDIR)/XMClib/src/$(notdir $@) ${LIBDIR}/

${SUPDIR}/startup_XMC$(XMCseries).S:
	mkdir -p ${SUPDIR}
	cp -n $(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Infineon/XMC$(XMCseries)_series/Source/GCC/startup_XMC$(XMCseries).S ${SUPDIR}/

${SUPDIR}/system_XMC$(XMCseries).c:
	mkdir -p ${SUPDIR}
	cp -n $(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Infineon/XMC$(XMCseries)_series/Source/system_XMC$(XMCseries).c ${SUPDIR}/

${LIBDIR}/System_LibcStubs.c:
	mkdir -p ${LIBDIR}
	cp -n $(XMCLIBBASE)/System_LibcStubs.c ${LIBDIR}/

$(LDname).ld:
	cp -n $(XMCLIBBASE)/$(XMCLIBDIR)/CMSIS/Infineon/XMC$(XMCseries)_series/Source/GCC/XMC$(XMCseries)x$(XMCsize).ld ./$(LDname).ld

# Write a script file for JLinkExe
JLinkCommands:
	echo "h" > JLinkCommands
	echo "loadfile ${BINDIR}/main.hex" >> JLinkCommands
	echo "r" >> JLinkCommands
	echo "g" >> JLinkCommands
	echo "q" >> JLinkCommands

# Write a script file for GDB
GDBCommands:
	echo "file ${BINDIR}/main.elf" > GDBCommands
	echo "target remote localhost:2331" >> GDBCommands
	echo "monitor reset" >> GDBCommands
	echo "load" >> GDBCommands
	echo "break main" >> GDBCommands

clean:
	find ./ -regextype posix-egrep -regex '.*[.](elf|bin|hex|lst|map|o)' -delete
	rm -f GDBCommands  JLinkCommands

