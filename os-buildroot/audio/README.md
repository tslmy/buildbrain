# Experimental PW-SA3 audio (Buildroot)

## Status, 2026-10-11

Tested over USB SSH on a physical PW-SA3 booting the PW-SH3 device tree,
Linux `6.1.70-11866-gfba0b03ba25c-dirty` and Buildroot ALSA 1.2.8.

- The stock SGTL5000 node at bus 0 address `0x0a` never responds.
- Bus 0 address `0x1a` responds. Its register values match ROHM BU26154:
  MAPCON=0, CLKSEL=6, amplifier power=4, analog volume=10,
  SAI Tx/Rx=0x80, HPF1=1, digital volumes=0xff.
- `brain-bu26154.ko` registers playback at `hw:0,0` and capture at `hw:0,1`.
- The user confirmed the built-in speaker played a short 440 Hz tone.
- Three- and eight-second recordings completed without ALSA/kernel errors.
  Left-channel PCM is nonzero; the right slot is empty (mono ADC).
  Raising microphone gain from 6 to 27 dB increased the captured signal.
  The user listened to an amplified mono review copy on the Mac and confirmed
  **intelligible speech**. Recording fidelity and longer-term stability still
  need testing. The original recording is preserved unchanged.
- The module was unbound/unloaded and replaced successfully without reboot.
- Installed `asound.conf` on the device. Default mono/16 kHz recording and
  mono/16 kHz playback through ALSA conversion both completed successfully.

This is a bring-up module, not an upstream-ready codec driver. It intentionally
does not change the kernel submodule, boot image, or existing SGTL5000 experiments.
Do not auto-load it on other models. There is no chip ID; address and register
matches are evidence, not conclusive identification of every Brain model.

## Build and deploy

Build against the **exact running kernel configuration and Module.symvers**.
For the current Docker builder:

```sh
docker exec stoic_einstein make -C /work/os-buildroot/audio \
  KERNEL_DIR=/work/linux-brain ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
scp -O -i ~/.ssh/id_ed25519_brain_pwsh3_usb \
  os-buildroot/audio/brain-bu26154.ko root@192.168.7.2:/root/
ssh -i ~/.ssh/id_ed25519_brain_pwsh3_usb root@192.168.7.2
insmod /root/brain-bu26154.ko
```

The kernel was built with CONFIG_MODVERSIONS; a module built against another
kernel is not interchangeable. The running device already has `aplay`,
`arecord`, `amixer`, and `speaker-test` installed from the matching cached
Buildroot toolchain. The Buildroot defconfig now selects them for future builds.

## Hardware tests

Raw hardware is limited to **44.1 kHz, S16_LE, two I2S slots**. Only one stream
at a time is allowed; simultaneous playback/capture is deliberately rejected.
Playback opens headphones by default; the speaker must be selected explicitly.
Analog playback gain values are not percentages: 0=mute, 2=-24 dB,
6=-8 dB, 10=0 dB; higher values amplify (up to +18 dB). Digital output is
additionally attenuated by 12 dB. Begin quietly; do not start at maximum gain.

```sh
aplay -l
arecord -l
amixer -c 0 sset Output Speaker
amixer -c 0 sset Playback 6
aplay -D hw:0,0 /tmp/brain-test-tone.wav
arecord -D hw:0,1 -f S16_LE -r 44100 -c 2 -d 8 /tmp/test.wav
amixer -c 0 sset Output Headphone
```

The latest tested module was uploaded as `/root/brain-bu26154-next.ko` and is
loaded. Microphone gain defaults to 27 dB (control `Mic`, values 0–7 = 6–27 dB).
Recordings are in `/tmp/brain-spoken-test.wav` and `/tmp/brain-spoken-gain.wav`;
host copies and mono extractions are under `image/audio-tools/` (ignored).

`asound.conf` provides separate playback/capture defaults and maps only the
left capture slot. It is installed and validated on this device, including
mono/16 kHz recording and playback conversion. Back up any existing
`/etc/asound.conf` before installing it on another image. For example:

```sh
arecord -f S16_LE -r 16000 -c 1 -d 8 /tmp/voice.wav
aplay /tmp/voice.wav
```

## Unload / recovery

Close audio applications first. ALSA holds a module reference while the codec
is bound, so unbind before unloading (do not force removal):

```sh
echo 0-001a > /sys/bus/i2c/drivers/brain-bu26154/unbind
rmmod brain_bu26154
```

The module does not auto-load after reboot. No ROM/eMMC/boot partition was
modified. It writes only volatile codec registers; reboot returns to the
existing boot setup. Do not run forced I2C transactions while the codec is bound.

## Remaining work

Test longer recordings and audio quality; verify headphone output and power sequencing;
replace hard-coded device discovery with kernel codec/machine drivers and
model-specific DT bindings. Add proper regulator, clock and DAPM management,
error unwinding, suspend/resume, mixer dB scales and lifecycle tests before
enabling automatic loading or building a release image. The experimental
speaker selection currently leaves headphone amplifiers enabled too.

## Sources

- [ROHM BU26154 datasheet Rev.002](https://www.alldatasheet.com/datasheet-pdf/pdf/873342/ROHM/BU26154MUV.html),
  pp.21–23 (I2C/protocol and state transitions), 38 (register map),
  45–62 (clock, power, gain, I2S and filters). Read indexes are even; write
  indexes are odd, so plain regmap-i2c addressing is insufficient.
- [PW-SH4 Windows CE audio investigation](https://note.com/nyxb/n/nb263390f2c5e),
  2026-09-23: identifies `wavedev2_BU26154.dll` and I2C address 0x1a.
  This is supporting evidence for a related model, not a Linux driver.
- [Brainux hardware roadmap](https://wiki.brainux.org/beginners/roadmap/):
  older notes describe Yamaha/ROHM audio hardware and incomplete support.
