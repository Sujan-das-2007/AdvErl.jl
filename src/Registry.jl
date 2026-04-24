module Registry

export GlobalRegistry, register!, whereis, sync_registry!

using ..Actors
using ZMQ
using Serialization

# Our Global DHT mapping names to Actors
const GlobalRegistry = Dict{Symbol,Actor}()
const RegistryLock = ReentrantLock()

const ctx = Context()

"""
    register!(name::Symbol, actor::Actor)
Announces an actor to the "Global Grid".
"""
function register!(name::Symbol, actor::Actor)
    lock(RegistryLock) do
        GlobalRegistry[name] = actor
        actor.name = name # update self-awareness
    end
    return actor
end

"""
    whereis(name::Symbol) -> Actor
Looks up the Actor logically mapped to the Name, giving location transparency.
"""
function whereis(name::Symbol)
    lock(RegistryLock) do
        if haskey(GlobalRegistry, name)
            return GlobalRegistry[name]
        else
            error("Registry Lookup Failed: No Actor registered as '$name'")
        end
    end
end

# Make send! easier by supporting Symbols directly to prove Location Transparency
function Actors.send!(name::Symbol, msg)
    actor = whereis(name)
    send!(actor, msg)
end

"""
    sync_registry!(port::Int)
Starts a ZMQ SUB socket listener to keep the GlobalRegistry aware of networked actors.
"""
function sync_registry!(port::Int)
    listener = errormonitor(
        Threads.@spawn begin
            sock = Socket(ctx, SUB)
            ZMQ.bind(sock, "tcp://*:\$port")
            ZMQ.subscribe(sock, "")

            println("[Registry] Network Sync Active on TCP port \$port")
            while true
                msg_bytes = ZMQ.recv(sock)
                try
                    payload = deserialize(IOBuffer(msg_bytes))
                    if payload isa Tuple{Symbol,Actor}
                        name, remote_actor = payload
                        lock(RegistryLock) do
                            GlobalRegistry[name] = remote_actor
                            println("[Registry] Networked Actor '\$name' imported.")
                        end
                    end
                catch e
                    @warn "[Registry] Failed to decode network message" exception=(e)
                end
            end
        end
    )
    return listener
end

end # module Registry
