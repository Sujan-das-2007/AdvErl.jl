module Mailboxes

export AtomicMailbox, send!, receive!

using ..Buffer
using Base.Threads: Atomic
# minor git push changes    
# A simple bounded lock-free circular buffer for high frequency atomic mailboxes
mutable struct AtomicMailbox
    buffer::Vector{Any}
    capacity::Int
    head::Atomic{Int}
    tail::Atomic{Int}

    function AtomicMailbox(capacity::Int=1024)
        new(Vector{Any}(undef, capacity), capacity, Atomic{Int}(1), Atomic{Int}(1))
    end
end

function send!(inbox::AtomicMailbox, msg)
    if typeof(msg) <: OwnedBuffer
        release!(msg)
    end

    # Simple spin-wait if full
    while true
        h = inbox.head[]
        t = inbox.tail[]
        next_t = mod1(t + 1, inbox.capacity)
        if next_t != h
            inbox.buffer[t] = msg
            Threads.atomic_cas!(inbox.tail, t, next_t)
            break
        end
        yield() # backoff
    end
end

function receive!(inbox::AtomicMailbox)
    local msg
    while true
        h = inbox.head[]
        t = inbox.tail[]
        if h != t
            msg = inbox.buffer[h]
            if Threads.atomic_cas!(inbox.head, h, mod1(h + 1, inbox.capacity)) == h
                break
            end
        end
        yield() # block until message arrives
    end

    if typeof(msg) <: OwnedBuffer
        claim!(msg)
    end
    return msg
end

end # module
