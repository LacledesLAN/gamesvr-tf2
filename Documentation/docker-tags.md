# Docker Tags Dependency Chain

```text
┌─────────────────────────────────────────┐
│ :base-full                              │
│                                         │
│ A full installation of TF2 Linux        │
│ dedicated server.                       │
│ (non-functional)                        │
└─────────────────────┬───────────────────┘
                      │
                      │
┌─────────────────────▼───────────────────┐
│ :base-latest                            │
│                                         │
│ An up-to-date installation of TF2 Linux │
│ dedicated server.                       │
│ (non-functional)                        │
└──────────┬───────────────────┬──────────┘
           │                   │
           │                   │
 ┌─────────▼────────┐  ┌───────▼──────────┐
 │ :latest, :64-bit │  │ :32-bit          │
 │                  │  │                  │
 │ 64-bit Linux TF2 │  │ 32-bit Linux TF2 │
 │ dedicated server │  │ dedicated server │
 │ (functional)     │  │ (functional)     │
 └──────────────────┘  └──────────────────┘
```
