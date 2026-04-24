module Conduit 

include("Buffer.jl")
include("Mailbox.jl")
include("Actor.jl")
include("Supervisor.jl")
include("Scheduler.jl")
include("Registry.jl")
include("Dashboard.jl")

using .Buffer
using .Mailboxes
using .Actors
using .Supervisors
using .Scheduler
using .Registry
using .Dashboard

export OwnedBuffer, release!, claim!, check_ownership, OwnershipError
export Actor, send!, receive!, AtomicMailbox
export OneForOne, OneForAll, Supervisor, supervise, Monitor
export @fair
export GlobalRegistry, register!, whereis, sync_registry!
export print_dashboard

end # module Conduit
