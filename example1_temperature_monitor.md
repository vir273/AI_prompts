# Firmware Request: Multi-Channel Temperature Monitor

## AI Agent Context

**Role:** Senior embedded systems engineer with experience in industrial monitoring systems.

**Coding Philosophy:** Defensive programming - assume sensors can fail and ADC readings can be noisy. Every hardware interface must have error handling.

**Quality Priorities:** Reliability first, then maintainability, then performance.

---

## Project Overview

**Target MCU:** STM32F030F4P6 (ARM Cortex-M0, 16KB flash, 4KB RAM)

**Toolchain:** ARM GCC with STM32 HAL

**Description:**
Build a 4-channel temperature monitoring system using NTC thermistors. The system should continuously sample temperatures, apply filtering, and trigger an alarm output when any channel exceeds configurable thresholds. Readings should be logged via UART.

---

## Hardware Interfaces

**Inputs:**
- 4× NTC thermistor (10K at 25°C, B=3950) via voltage dividers
- Voltage divider configuration: NTC to GND, 10K resistor to 3.3V

**Outputs:**
- 1× Alarm output (GPIO, active high)
- 1× Status LED (GPIO)

**Communication:**
- UART TX at 115200 baud for logging

---

## Functional Requirements

1. **Temperature Acquisition**
   - Sample all 4 channels at 10 Hz (100 ms interval)
   - Use DMA for efficient ADC data transfer

2. **Temperature Calculation**
   - Convert ADC values to temperature using simplified Steinhart-Hart (B-parameter equation)
   - Resolution: 0.1°C
   - Valid range: -40°C to +125°C

3. **Filtering**
   - Apply 8-sample moving average to reduce noise

4. **Alarm Logic**
   - Configurable high/low thresholds per channel
   - Assert alarm output when any channel exceeds threshold
   - Hysteresis: alarm clears only after 10 seconds within safe range

5. **UART Logging**
   - Output all temperatures and alarm status every 1 second
   - Format: human-readable ASCII

---

## Constraints

- **Flash usage:** < 12 KB
- **RAM usage:** < 3 KB
- **Alarm response time:** < 200 ms from threshold breach to output assertion
- **All calculations must complete before next sample period**

---

## Error Handling

- **Sensor fault:** ADC reading near rail (< 50 or > 4000 counts) indicates open/short → flag channel as faulted, use last valid reading
- **Watchdog:** Enable with ~500 ms timeout
- **Safe state:** On fault, assert alarm output and blink status LED rapidly

---

## Reference Documents

- **Datasheet:** STM32F030F4P6 (DS9773 Rev 10)
- **Reference Manual:** RM0360 Rev 4 (STM32F030x4/x6/x8/xC and STM32F070x6/xB)
- **SDK Version:** STM32CubeF0 v1.11.4

---

## On-Target Testing

**Startup Self-Test (BIST):** Enable
- Verify ADC-to-temperature conversion with known test vector
- Check moving average filter logic
- On failure: fast blink status LED, do not enter normal operation

**Test Mode Trigger:** UART command "TEST\r\n"

**Tests to Include:**
- ADC to temperature conversion - input known ADC value, verify output matches expected temperature (include test vector in code comments)
- Moving average filter - step input test, verify convergence
- Threshold logic - verify alarm triggers and hysteresis timing

**Test Output:**
- UART prints "PASS" or "FAIL (expected X, got Y)" for each test
- Print total execution time of conversion function (for performance verification)

**Production Build:** Keep startup BIST only, compile out UART test command

---

## Debug Infrastructure

- **Debug UART:** Required, same UART used for logging (115200 baud)
- **Startup message:** Print "TempMon started, SYSCLK=%dMHz, ADC calibrated" on boot
- **Runtime logging:** Log each temperature reading cycle, alarm state changes, and any sensor faults
- **Debug pins:** Toggle a spare GPIO at start/end of ADC conversion for timing verification with scope

---

## Implementation Stages

Build and verify in this order:

1. **Stage 1:** Clock setup (48MHz) + UART printf → verify with startup message
2. **Stage 2:** Single ADC channel read (no DMA) → print raw ADC value, verify with known voltage
3. **Stage 3:** 4-channel ADC scan with DMA → print all 4 raw values
4. **Stage 4:** Temperature conversion → print calculated temperatures, verify against reference thermometer
5. **Stage 5:** Moving average filter → observe smoothed readings
6. **Stage 6:** Alarm logic + GPIO output → trigger alarm with hot air, verify output with multimeter
7. **Stage 7:** Full integration with watchdog

---

## Verification Points

- **After init:** Status LED should turn ON, UART prints startup message with clock speed
- **ADC calibration:** Should complete without timeout
- **At room temperature:** ADC channels should read ~2000-2500 counts (depending on actual temp)
- **Temperature reading:** Should match reference thermometer within ±2°C
- **Alarm test:** Heating one sensor above threshold → alarm pin goes HIGH within 200ms
- **Fault test:** Disconnect one NTC → that channel flagged as fault within 1 second

---

## Additional Notes

- Temperature range of interest is 0°C to 80°C (industrial monitoring)
- System clock: 48 MHz using internal oscillator with PLL
- Prefer DMA over polling for ADC to free CPU for calculations
