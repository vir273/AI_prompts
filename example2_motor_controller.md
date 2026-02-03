# Firmware Request: DC Motor Speed Controller

## AI Agent Context

**Role:** Embedded software engineer specializing in motor control and real-time systems.

**Coding Philosophy:** Performance-critical code demands direct register access where necessary. ISRs must be minimal and deterministic. Use fixed-point math only - no floating point in control loops. Overcurrent protection is safety-critical.

**Quality Priorities:** Execution speed first (for control loop), then reliability, then maintainability.

---

## Project Overview

**Target MCU:** STM32F031K6T6 (ARM Cortex-M0, 32KB flash, 4KB RAM)

**Toolchain:** ARM GCC with STM32 LL (Low-Layer) drivers

**Description:**
Build a closed-loop brushed DC motor speed controller with current limiting. The system uses PWM output, reads speed from a quadrature encoder, implements PID control, and accepts commands via I2C as a slave device. Designed for 12V motors up to 5A.

---

## Hardware Interfaces

**Inputs:**
- Quadrature encoder (100 PPR) for speed feedback
- Current sense amplifier output (50mV/A, 0.01Ω shunt)
- Direction input (GPIO)

**Outputs:**
- Complementary PWM to half-bridge driver (20 kHz, 500ns dead-time)
- Motor enable (GPIO, active high)
- Fault LED (GPIO)

**Communication:**
- I2C slave at address 0x42, 400 kHz

---

## Functional Requirements

1. **PWM Generation**
   - 20 kHz switching frequency, center-aligned
   - Complementary outputs with configurable dead-time
   - Duty cycle range: 0-100%

2. **Speed Measurement**
   - Hardware quadrature decoding (4x counting)
   - Calculate velocity in RPM at 1 kHz rate

3. **Current Monitoring**
   - Sample motor current synchronized to PWM center
   - Immediate shutdown if current exceeds limit

4. **PID Speed Control**
   - 1 kHz control loop
   - Fixed-point arithmetic (Q8.8 for gains)
   - Anti-windup on integral term

5. **Soft Start/Stop**
   - Configurable acceleration ramp (default: 1000 RPM/s)
   - Gradual speed changes to reduce mechanical stress

6. **I2C Command Interface**
   - Set speed setpoint and direction
   - Set current limit
   - Read actual speed and current
   - Configure PID gains
   - Enable/disable and fault clear

---

## Constraints

- **Flash usage:** < 20 KB
- **RAM usage:** < 4 KB
- **Control loop:** Must complete within 100 µs
- **Overcurrent response:** < 50 µs from detection to PWM shutdown

---

## Error Handling

- **Overcurrent:** Immediate PWM disable, set fault state
- **Stall detection:** High current + near-zero speed for 500ms → fault
- **Encoder fault:** No pulses while PWM active for 1 second → fault
- **Watchdog:** Enable with 200 ms timeout
- **Safe state:** PWM disabled, motor enable low, fault LED on

---

## Communication Protocol Details

**I2C Register Map:**

| Address | Name | R/W | Description |
|---------|------|-----|-------------|
| 0x00 | STATUS | R | Fault/running/direction flags |
| 0x01-02 | SPEED_CMD | R/W | Speed setpoint (RPM, 16-bit) |
| 0x03-04 | SPEED_ACT | R | Actual speed (RPM, 16-bit) |
| 0x05-06 | CURRENT | R | Motor current (mA, 16-bit) |
| 0x07-08 | CURRENT_LIM | R/W | Current limit (mA, 16-bit) |
| 0x09 | CONTROL | R/W | Enable, direction, fault clear |
| 0x0A-0C | KP/KI/KD | R/W | PID gains |

---

## Reference Documents

- **Datasheet:** STM32F031K6T6 (DS9773 Rev 10)
- **Reference Manual:** RM0360 Rev 4 (STM32F030x4/x6/x8/xC and STM32F070x6/xB)
- **SDK Version:** STM32CubeF0 v1.11.4 (LL drivers preferred)

---

## On-Target Testing

**Startup Self-Test (BIST):** Enable
- Verify PID calculation with known error input
- Verify encoder-to-RPM conversion math
- Verify current sense ADC offset is within expected range
- On failure: set fault state, do not enable motor

**Test Mode Trigger:** I2C command (write 0xAA to CONTROL register)

**Tests to Include:**
- PID calculation - step input test, verify proportional response and anti-windup
- Ramp generator - verify rate limiting and target tracking
- ADC to current conversion - verify against known test vector
- Encoder to RPM calculation - input known count/time, verify RPM output

**Test Output:**
- UART prints test results (if debug UART available)
- Otherwise: status LED blink pattern (1 blink = all pass, continuous = fail)
- Store test results in I2C status register for readback

**Production Build:** Keep startup BIST, compile out UART output, keep I2C test trigger for manufacturing

---

## Debug Infrastructure

- **Debug UART:** Optional but recommended for development (115200 baud, separate from I2C)
- **Startup message:** Print "MotorCtrl started, PWM=%dkHz, I2C=0x%02X" on boot
- **Runtime logging:** Log speed setpoint changes, fault events, and current limit triggers
- **Debug pins:** 
  - Toggle GPIO at PID loop entry/exit (verify 1kHz timing with scope)
  - Pulse GPIO on overcurrent detection (verify <50µs response)

---

## Implementation Stages

Build and verify in this order:

1. **Stage 1:** Clock setup (48MHz) + UART printf → verify startup message
2. **Stage 2:** PWM output at fixed 50% duty → verify 20kHz on scope, check dead-time
3. **Stage 3:** ADC current sense → print current reading, verify with DC supply + known load
4. **Stage 4:** Encoder reading → spin motor by hand, print position/velocity
5. **Stage 5:** Open-loop control → set duty cycle via variable, motor should spin
6. **Stage 6:** Overcurrent protection → apply overload, verify immediate shutdown
7. **Stage 7:** PID loop (without ramp) → step response test, tune gains
8. **Stage 8:** Soft start/stop ramp → verify smooth acceleration
9. **Stage 9:** I2C slave interface → test with I2C master/analyzer
10. **Stage 10:** Full integration with watchdog

---

## Verification Points

- **After init:** Fault LED OFF, motor enable LOW (safe state before commands)
- **PWM output:** Scope shows 20kHz, complementary signals, ~500ns dead-time
- **Current zero:** With motor disconnected, current reading should be near 0mA (check offset)
- **Encoder:** 400 counts per revolution (100 PPR × 4)
- **At 1000 RPM:** Velocity calculation matches tachometer within ±2%
- **Overcurrent:** Trigger at set limit, PWM stops within 50µs (verify with scope)
- **I2C:** Bus analyzer shows correct ACKs, register reads return expected values

---

## Additional Notes

- Motor specs: 12V, 3000 RPM max, 5A stall current
- System clock: 48 MHz from internal HSI48
- Dead-time chosen for typical MOSFET gate drivers
- PWM frequency above audible range
