module Supervisors

export OneForOne, OneForAll, Supervisor, supervise

using ..Actors

"""
    OneForOne
The classic Erlang supervisor strategy: If a child task crashes, 
it restarts only that task.
"""
struct OneForOne end

"""
    OneForAll
Advanced strategy: If one child task crashes, all sibling tasks are
terminated, cleaned up, and then the entire pool is restarted.
"""
struct OneForAll end

"""
    Supervisor
Monitors an array of child actors. If an actor's task fails, it uses the 
provided strategy to recover the state.
"""
struct Supervisor
    children::Vector{Actor}
    strategy::Any
    watcher::Task

    function Supervisor(
        children::Vector{Actor}, strategy=OneForOne(); name::Symbol=:supervisor
    )
        watcher = errormonitor(
            Threads.@spawn begin
                # Continuous monitoring loop
                while true
                    for actor in children
                        if istaskfailed(actor.task)
                            @warn "[Supervisor] CRITICAL: Actor '$(actor.name)' CRASHED! Catching and restarting..." exception=(
                                actor.task.exception
                            )

                            # Resource Cleanup phase 1 for failed actor
                            actor.cleanup(actor)

                            # Execute strategy
                            if strategy isa OneForOne
                                # Keep the mailbox, spawn a new task using the original function!
                                new_task = Task(() -> actor.func(actor.inbox))
                                actor.task = new_task
                                schedule(new_task)
                                b = if typeof(actor.inbox) == Channel{Any}
                                    length(actor.inbox.data)
                                else
                                    0
                                end
                                println(
                                    "[Supervisor] RECOVERY SUCCESS: Actor '$(actor.name)' restarted.",
                                )
                            elseif strategy isa OneForAll
                                @warn "[Supervisor] OneForAll triggered: Shutting down all sibling actors."
                                # Stop siblings
                                for sibling in children
                                    if sibling !== actor && !istaskdone(sibling.task)
                                        # Interrupt them if possible, or assume they crash due to system reset
                                        schedule(
                                            sibling.task, InterruptException(), error=true
                                        )
                                        wait(sibling.task) # wait for graceful/forced exit
                                    end
                                    if sibling !== actor
                                        sibling.cleanup(sibling)
                                    end
                                end

                                # Respawn all
                                for sibling in children
                                    new_t = Task(() -> sibling.func(sibling.inbox))
                                    sibling.task = new_t
                                    schedule(new_t)
                                end
                                println(
                                    "[Supervisor] RECOVERY SUCCESS: All actors restarted under OneForAll.",
                                )
                                break # escape loop to avoid restarting actors we just refreshed
                            end
                        end
                    end

                    # Check health 10 times a second
                    sleep(0.1)
                end
            end
        )
        new(children, strategy, watcher)
    end
end

"""
    supervise(children::Vector{Actor}, strategy=OneForOne(); name::Symbol=:supervisor)
Convenience function to attach a Supervisor to a set of Actors.
"""
function supervise(children::Vector{Actor}, strategy=OneForOne(); name::Symbol=:supervisor)
    return Supervisor(children, strategy; name=name)
end

# Backward compatibility alias
const Monitor = Supervisor
export Monitor, supervise

end # module Supervisors
