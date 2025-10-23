# WHERE EXE

![where_exe](res/where%20exe.jpg)
<br>
nuh uh not this time fellow developer, you can [build](#RUNNING) it tho

# MINIMUM REQUIREMENTS

- Apple's unreleased M5 ultra
- NVIDIA RTX PRO 6000 Blackwell Workstation Edition — the most powerful desktop GPU ever built, ready to conquer advanced models and demanding creative workflows. [source](https://www.nvidia.com/en-us/products/workstations/professional-desktop-gpus/rtx-pro-6000/) <sub>nvidia don't sue me</sub>

# RUNNING

## DEPENDENCIES

- aarch64-linux-gnu-as/ld: `sudo pacman -S aarch64-linux-gnu-gcc`
- QEMU: `sudo pacman -S qemu-user qemu-user-static`
- gdb<sub>only for debuggin</sub>: `sudo pacman -S gdb`

## BUILDING

```bash
aarch64-linux-gnu-as -mcpu=cortex-a78 factorial.asm -o factorial.o
aarch64-linux-gnu-ld factorial.o -o factorial
```

if you want to use `gdb`, add the `-g` flag to the assembler.

## RUN

```bash
qemu-aarch64 ./factorial
```

## DEBUGGING

```bash
qemu-aarch64 -g 1234 ./factorial
```
and in another terminal:
```bash
gdb -q --nh \
  -ex 'set architecture aarch64' \
  -ex 'file factorial' \
  -ex 'target remote localhost:1234' \
  -ex 'layout split' \
  -ex 'layout regs'
```

![enjoy](res/enjoy.jpg)
