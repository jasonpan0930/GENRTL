# timing_plan.md Format Reference (English)

Agent2 overwrites `workflow-b-pipeline/timing_plan.md` using this structure.

---

## 1. Overview

- **Design name**:
- **Clock**: edge, frequency assumption
- **Reset**: style, sync/async, polarity
- **Dataflow one-liner**: e.g. input → decode (C) → buffer (S) → output (C)

## 2. Hierarchy

| Module | Type | Notes |
|--------|------|-------|
| top | top | External ports |

## 3. Stages

### Stage N — \<name\>

- **Type**: `Combinational` | `Sequential` | `Mixed`
- **Module**:
- **Function**:

#### Inputs

| Signal | Width | Source (stage/port) | Registered? |
|--------|-------|---------------------|-------------|

#### Outputs

| Signal | Width | Destination | Next cycle? |
|--------|-------|-------------|-------------|

#### Timing

- **Clock** / **Reset** / **Latency (cycles)**

#### Combinational / sequential contents

#### Handshake / backpressure

## 4. Connectivity (ASCII)

```
[port in] --> Stage0(C) --> Stage1(S) --> [port out]
```

## 5. FSM (if any)

States, encodings, transition table.

## 6. Alignment checklist

- [ ] All ports assigned to top or a stage
- [ ] No unintended combinational loops
- [ ] Throughput/latency match spec or `[ASSUMPTION]`

## 7. Open items / risks
