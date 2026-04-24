# jbeam Documentation

Welcome to **jbeam**, a high-performance, fault-tolerant actor framework in Julia inspired by Erlang OTP. jbeam brings "let it crash" philosophy, high-concurrency memory safety, and robust supervision to the Julia ecosystem.

## Core Philosophy
jbeam separates actor execution and state management, providing safety through a system of non-blocking channels and true supervision trees. Its architecture consists of multiple layers:

- **Layer 1: High-Velocity Actor**
  Provides zero-copy memory pointer hand-off between actors and bounded, atomic mailboxes.
- **Layer 2: Supervision Roll-Cage**
  Implements standard restart strategies (`OneForOne`, `OneForAll`) and hardware cleanup hooks.
- **Layer 3: Distributed Name Registry**
  Network transparent actor referencing using `ZMQ.jl`.

---

## 1. Buffers & Memory Safety
jbeam implements `OwnedBuffer` to provide exclusive ownership semantics to actors over chunks of memory. This ensures zero-copy message passing with strict memory safety: only the actor possessing the token is allowed to mutate the memory.

```julia
using jbeam

# Create a buffer of a specific size
buf = OwnedBuffer(1024)

# Claim ownership for the current thread/actor
claim!(buf)

# Mutate buffer...
buf.data[1] = 0x01

# Release ownership to pass to another actor
release!(buf)
```

---

## 2. Actors & Mailboxes
Actors in jbeam are lightweight, green-threaded entities bound to an `AtomicMailbox`. Mailboxes are lock-free and designed for high throughput.

### Spawning an Actor
You can spawn an actor by passing a process loop function to the `Actor` constructor. The actor automatically begins execution on the scheduler.

```julia
actor_loop = (mb) -> begin
    while true
        msg = receive!(mb)
        println("Actor received: ", msg)
    end
end

actor_ref = Actor(actor_loop, inbox_size=100, name=:demo_actor)
```

### Messaging
Actors communicate asynchronously by sending messages to mailboxes:

```julia
send!(mailbox, "Hello jbeam!")
```

---

## 3. Supervision Strategies
Just like Erlang OTP, actors are not meant to run unmonitored. Supervisors catch exceptions and cleanly restart failed actors or entire groups of actors depending on the chosen strategy.

### OneForOne
Restarts only the actor that crashed.
```julia
strategy = OneForOne()
supervisor = Supervisor(strategy)
supervise(supervisor, actor_ref, actor_loop, mailbox, "initial_state")
```

### OneForAll
If one actor crashes, all actors supervised by this supervisor are terminated and restarted together. This is crucial for pipeline-dependent workloads.
```julia
strategy = OneForAll()
# Supervisor setup...
```

---

## 4. Distributed Name Registry
You can register an actor using a name (a `Symbol`) and message it logically, abstracting the physical memory reference. This is transparent across the network, backed by ZeroMQ.

```julia
# Local Node
sync_registry!(5555)
register!(:db_actor, db_actor_ref)

# In any other part of the system or network
target_ref = whereis(:db_actor)
send!(target_ref, "query")
```

---

## 5. Threading & Scheduling
jbeam includes a `@fair` macro that automatically injects yield points into tight actor loops, preventing starvation of the core Julia thread pools.

```julia
actor_loop = (mb, state) -> begin
    while true
        msg = receive!(mb)
        @fair process_heavy_task(msg)
    end
end
```

## Running Tests
To ensure the framework is functioning correctly, navigate to the package root and run the test suite:
```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```
