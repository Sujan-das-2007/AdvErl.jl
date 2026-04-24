module Actors

export Actor, send!, receive!

using ..Buffer
using ..Mailboxes
import ..Mailboxes: send!, receive!

mutable struct Actor
    inbox::AtomicMailbox
    task::Task
    func::Function
    name::Symbol
    cleanup::Function

    function Actor(
        func::Function;
        inbox_size=1024,
        name::Symbol=:unnamed,
        cleanup::Function=(_)->nothing,
    )
        c = AtomicMailbox(inbox_size)
        t = Task(() -> func(c))

        actor = new(c, t, func, name, cleanup)

        # Starts the task on the scheduler
        schedule(t)
        return actor
    end
end

# send! for Actor delegates to Mailbox, some change
function send!(actor::Actor, msg)
    send!(actor.inbox, msg)
end

end # module Actors
