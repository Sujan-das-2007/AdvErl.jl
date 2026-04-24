# AdvErl (Julia-BEAM)

An ultra-high-performance, fault-tolerant Actor Framework modeled after the legendary Erlang/OTP BEAM VM, natively implemented in modern Julia.

AdvErl fuses twenty years of distributed systems theory (supervision trees, location-transparent registries, message-passing) with the modern raw power of Julia's zero-copy memory capabilities, atomic primitives, and high-performance threading.

## Why AdvErl?

When building mission-critical pipelines—from satellite telemetry processing engines to HFT platforms—you need two things that often conflict:

1. **Lethal Performance:** Zero-copy transfers and lock-free execution to process millions of ops/sec.
2. **Indestructible Reliability:** Systems should crash beautifully and recover automatically without losing throughput. 

AdvErl delivers both.

---

## Core Pillars of Architecture

### 1. High-Velocity Actors (Zero-Copy)

Actors in AdvErl communicate with extreme speed. Mailboxes have been upgraded to custom `AtomicMailbox` implementations running lock-free, circular ring buffers powered by base Julia `Threads.Atomic`.

Large payload swaps leverage **Zero-Copy Memory Ownership**, allowing pointers (e.g. Gigabytes of image arrays or matrix data) to be swapped between tasks in O(1) time semantics without duplicating data.

```julia
using AdvErl

# Create a high-throughput actor
actor = Actor(inbox_size=4096, name=:satellite_ingest) do inbox
    while true
        msg = receive!(inbox)
        # process msg
    end
end
```

### 2. The Supervision Roll-Cage

Code crashes. Hardware fails. Hardware resources (like GPU/Network sockets) leak. AdvErl addresses this via formal Supervision with robust **Resource Cleanup Hooks**.

**Supervision Strategies:**

- `OneForOne`: If one actor crashes, it alone is restarted while retaining its inbox backlog.
- `OneForAll`: If a critical pipeline stage fails, the entire pipeline of sibling actors is gracefully terminated, cleaned up, and uniformly respawned to guarantee deterministic data state.

```julia
# Providing a cleanup routine for hardware assets
my_worker = Actor(my_logic, name=:gpu_worker, cleanup=(a) -> free_vram!(a.state))

# Link it to a Supervisor
pool = supervise([my_worker], OneForAll())
```

### 3. Distributed Name Registry (True Network Transparency)

Actors can logically route messages using names rather than physical memory references. Overhauled with `ZMQ.jl` wrappers, the `GlobalRegistry` gives actors Location Transparency. You can synchronize registries across different physical servers across the globe over standard TCP:

```julia
# Local Server
sync_registry!(5555)
register!(:russia_node, remote_actor)

# Remote messages simply target the symbol
send!(:russia_node, data)
```

### 4. Scheduler Partitioning & Fairness

Using the `@fair` macro, actors yield predictably ensuring smooth concurrent multiplexing across Julia threads without starving the core thread pools.

---

## Getting Started

1. Set up your environment and install dependencies.

   ```julia
   import Pkg; Pkg.add(["ZMQ", "Serialization"])
   ```

2. Spawn your tasks, assign cleanup procedures, and start sending!

## Examples

See the `/examples` directory for demonstrations such as `legacy_killer_demo.jl` which showcases continuous failure-injection recovery.

---

*MIT Licensed.*

# AdvErl.jl