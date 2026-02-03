# Firmware Development Prompt Template

## AI Agent Context

**Role:** [e.g., Senior embedded systems engineer with experience in industrial/automotive/consumer applications]

**Coding Philosophy:** [e.g., Defensive programming, fail-safe behavior, assume hardware will misbehave]

**Quality Priorities:** [Rank: reliability, maintainability, performance, code size, portability]

---

## Project Overview

**Target MCU:** [Manufacturer and part number, e.g., STM32F030F4P6]

**Toolchain:** [e.g., ARM GCC with STM32 HAL, Keil MDK with LL drivers]

**Description:**
[2-3 sentences describing what the firmware should accomplish and its purpose]

---

## Hardware Interfaces

**Inputs:**
- [Sensor/input type and basic specs, e.g., "NTC thermistor 10K@25°C via voltage divider"]
- [Additional inputs...]

**Outputs:**
- [Actuator/output type, e.g., "PWM to motor driver", "GPIO alarm output"]
- [Additional outputs...]

**Communication:**
- [Protocol and parameters, e.g., "UART 115200 baud for debug logging"]
- [Additional interfaces...]

---

## Functional Requirements

1. **[Function Name]**
   - [What it should do, trigger condition, timing if critical]

2. **[Function Name]**
   - [Description...]

[Add more as needed]

---

## Constraints

- **Flash usage:** [e.g., < 12 KB of 16 KB available]
- **RAM usage:** [e.g., < 3 KB of 4 KB available]
- **Timing:** [e.g., Control loop must complete within 100 µs]
- **Power:** [If applicable, e.g., < 5 mA average]

---

## Error Handling

- **[Fault type]:** [Detection method] → [Response]
- **Watchdog:** [Enable/disable, timeout]
- **Safe state:** [What the system should do when faulted]

---

## Communication Protocol Details (if applicable)

[Message formats, register maps, command structures - only if the firmware implements a protocol that needs to be specified]

---

## Reference Documents

- **Datasheet:** [Exact part number and revision, e.g., STM32F030F4P6 Rev 5]
- **Reference Manual:** [e.g., RM0360 Rev 4 for STM32F0x0]
- **SDK/HAL Version:** [e.g., STM32CubeF0 v1.11.3, LPCOpen v3.02]
- **Other:** [Application notes, errata sheets if relevant]

---

## Verified Code Fragments (if available)

[Paste any known working code snippets for critical sections like clock init, peripheral setup, or communication. This gives the AI a correct starting point.]

```c
// Example: Clock configuration that works on my board
// [paste code here]
```

---

## On-Target Testing

Specify which testing approach to include in the firmware:

**Startup Self-Test (BIST):**
- [ ] Enable / [ ] Disable
- Tests to run: [e.g., CRC logic check, RAM test, flash checksum]
- On failure: [e.g., halt with LED pattern, enter safe mode]

**Test Mode Trigger:**
- [ ] UART command: [e.g., send "TEST" to trigger]
- [ ] GPIO jumper: [e.g., hold pin X low at boot]
- [ ] None

**Tests to Include:**
- [Logic description, e.g., "CRC calculation"] - verify against known test vector
- [Logic description] - verification method

**Test Output:**
- Format: [e.g., "PASS/FAIL" messages via UART]
- Include execution time measurement: [ ] Yes / [ ] No

**Production Build:**
- [ ] Compile out all tests (`#ifdef TEST_BUILD`)
- [ ] Keep startup BIST only
- [ ] Keep all tests (for field diagnostics)

---

## Debug Infrastructure

- **Debug UART:** [Required/optional, baud rate]
- **Startup message:** [What to print on boot, e.g., "System started, SYSCLK=48MHz"]
- **Runtime logging:** [What events/states to log]
- **Debug pins:** [Any GPIO toggles for timing measurement with scope]

---

## Implementation Stages

Build and verify in this order to isolate issues early:

1. **Stage 1:** [e.g., Clock + UART printf → verify with startup message]
2. **Stage 2:** [e.g., GPIO toggle → verify with LED or scope]
3. **Stage 3:** [e.g., ADC single read → print raw value]
4. **Stage 4:** [e.g., Timer interrupt → toggle LED at known rate]
5. **Stage N:** [Full integration]

---

## Verification Points

Measurable checkpoints to confirm correct operation:

- **After init:** [e.g., LED should be ON, pin X should be HIGH]
- **At idle:** [e.g., Current draw should be ~10mA]
- **During operation:** [e.g., ADC reads ~2048 counts with 1.65V input]
- **Communication:** [e.g., Scope shows 115200 baud, correct frame format]

---

## Additional Notes

[Domain-specific information, gotchas, preferences, or other context]
