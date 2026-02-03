# Firmware Request: RS-485 Modbus Sensor Node

## AI Agent Context

**Role:** Embedded systems engineer specializing in resource-constrained microcontrollers and industrial protocols.

**Coding Philosophy:** Every byte counts. Direct register access only - no abstraction layers. No dynamic memory allocation. Protocol compliance is non-negotiable for interoperability.

**Quality Priorities:** Code size first (critical constraint), then reliability, then maintainability.

---

## Project Overview

**Target MCU:** LPC810M021FN8 (ARM Cortex-M0+, 4KB flash, 1KB RAM, 8-pin)

**Toolchain:** ARM GCC with LPCOpen library

**Description:**
Build a compact Modbus RTU slave that reads temperature/humidity from an SHT31 sensor and ambient light from an LDR. Communicates over RS-485 with configurable address and baud rate stored in flash. Designed for minimal component count.

---

## Hardware Interfaces

**Inputs:**
- SHT31 temperature/humidity sensor via I2C (address 0x44)
- LDR via analog comparator (successive approximation technique)

**Outputs:**
- RS-485 driver enable (GPIO for DE/RE control)

**Communication:**
- RS-485 half-duplex, Modbus RTU
- Configurable baud: 9600 / 19200 / 38400 / 115200
- Format: 8 data bits, even parity, 1 stop bit (8E1)

---

## Functional Requirements

1. **Modbus RTU Protocol**
   - Slave address: 1-247 (configurable)
   - Support function codes: 0x03 (read), 0x06 (write single), 0x10 (write multiple)
   - Proper 1.5/3.5 character timeout detection
   - CRC-16 validation

2. **SHT31 Sensor Reading**
   - Periodic measurement (configurable 1-60 seconds)
   - Temperature resolution: 0.01°C
   - Humidity resolution: 0.01%
   - Validate sensor CRC

3. **Light Level Measurement**
   - 8-bit resolution (0=dark, 255=bright)
   - Use comparator with internal reference ladder

4. **RS-485 Direction Control**
   - Assert DE before transmitting
   - Release DE after last byte transmitted

5. **Configuration Storage**
   - Store slave address, baud rate, poll interval in flash
   - Apply on boot, update via Modbus write

---

## Constraints

- **Flash usage:** < 3.5 KB (of 4 KB available)
- **RAM usage:** < 900 bytes (of 1 KB available)
- **Response time:** Modbus response within 10 ms of request
- **No floating point** - integer math with scaling only

---

## Error Handling

- **CRC error:** Ignore frame silently (per Modbus spec)
- **Invalid function:** Return exception code 0x01
- **Invalid register:** Return exception code 0x02
- **Sensor failure:** Set status flag, return last valid reading
- **Watchdog:** Enable with 1 second timeout
- **Safe state:** Continue responding with error flags set

---

## Communication Protocol Details

**Modbus Register Map:**

| Address | Name | R/W | Description |
|---------|------|-----|-------------|
| 0x0000 | TEMPERATURE | R | Temperature × 100 (0.01°C units) |
| 0x0001 | HUMIDITY | R | Humidity × 100 (0.01% units) |
| 0x0002 | LIGHT | R | Light level (0-255) |
| 0x0003 | STATUS | R | Sensor status flags |
| 0x0010 | SLAVE_ADDR | R/W | Modbus address (1-247) |
| 0x0011 | BAUD_CODE | R/W | 0=9600, 1=19200, 2=38400, 3=115200 |
| 0x0012 | POLL_INTERVAL | R/W | Sensor poll interval (seconds) |
| 0x00FF | SAVE_CONFIG | W | Write 0x55AA to persist config |

---

## Reference Documents

- **Datasheet:** LPC810M021FN8 (Rev 4.1)
- **User Manual:** UM10601 LPC81x User Manual (Rev 1.6)
- **SDK Version:** LPCOpen v3.02
- **Other:** Modbus over Serial Line Specification v1.02

---

## Verified Code Fragments (if available)

```c
// LPC810 clock setup - 12MHz IRC (known working)
// The IRC is default, no PLL setup needed for basic operation
// Just ensure MAINCLKSEL = 0 (IRC) and SYSAHBCLKDIV = 1
```

---

## On-Target Testing

**Startup Self-Test (BIST):** Enable
- Verify Modbus CRC with test vector: {0x01, 0x03, 0x00, 0x00, 0x00, 0x01} → 0x840A
- Verify SHT31 CRC function
- Check I2C communication with SHT31 (read device ID)
- On failure: respond to Modbus with fault flag set in status register

**Test Mode Trigger:** Modbus command (write 0x55 to register 0x00FE)

**Tests to Include:**
- Modbus CRC-16 calculation - verify against known test vectors
- SHT31 CRC-8 calculation - verify with known data
- Temperature/humidity conversion - verify boundary values
- Frame validation logic - test address match and CRC rejection

**Test Output:**
- Results returned via Modbus read from test result register (0x00FD)
- Bit flags: bit0=CRC pass, bit1=SHT31 CRC pass, bit2=conversion pass, bit7=all pass

**Production Build:** Keep startup BIST (minimal flash cost), keep Modbus test command for field diagnostics

---

## Debug Infrastructure

- **Debug UART:** Same as Modbus UART (shared) - use during development before RS-485 transceiver installed
- **Startup message:** Send "MBS v1.0 A=%d B=%d" (address, baud code) on boot - disable in production
- **Runtime logging:** Not feasible in production (half-duplex bus), use LED patterns instead
- **Debug LED:** Blink pattern on spare GPIO if available:
  - 1 blink = valid frame received
  - 2 blinks = response sent
  - Fast blink = fault condition

---

## Implementation Stages

Build and verify in this order:

1. **Stage 1:** UART TX only → send "Hello" at 9600 baud, verify with USB-serial adapter
2. **Stage 2:** UART RX + echo → receive byte, echo back, verify bidirectional
3. **Stage 3:** Modbus frame detection → detect 3.5 char timeout, print "frame received"
4. **Stage 4:** CRC validation → calculate and validate CRC, print pass/fail
5. **Stage 5:** Function code 0x03 → respond to read request with dummy data
6. **Stage 6:** I2C master to SHT31 → read temperature, print raw value
7. **Stage 7:** SHT31 CRC validation → verify sensor data integrity
8. **Stage 8:** Comparator light sensing → print 8-bit light level
9. **Stage 9:** Flash config storage → write config, power cycle, verify persistence
10. **Stage 10:** RS-485 direction control → add transceiver, verify half-duplex timing
11. **Stage 11:** Full integration with watchdog, remove debug prints

---

## Verification Points

- **After init:** Startup message received on terminal (before RS-485 installed)
- **UART timing:** Scope shows correct baud rate, 8E1 format
- **Modbus frame:** Frame detected within 1ms of 3.5 char silence
- **CRC check:** Known good frame (from Modbus tool) passes CRC
- **SHT31 present:** I2C ACK received at address 0x44
- **Temperature:** Reading within ±1°C of reference thermometer
- **RS-485 DE timing:** DE asserts >50µs before TX, releases <100µs after last byte
- **Response time:** Modbus response starts within 10ms of request end (verify with analyzer)
- **Flash write:** Config survives power cycle (test 10+ times)

---

## Additional Notes

- Boot defaults: address 1, 9600 baud, 10 second poll
- SHT31 CRC polynomial: 0x31
- Modbus CRC: polynomial 0xA001, initial 0xFFFF
- Pin multiplexing may be needed due to 8-pin package
- Flash wear consideration: only write config on explicit save command
- System clock: 12 MHz internal RC oscillator
