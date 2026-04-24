module Dashboard

export print_dashboard

using ..Actors
using ..Registry

"""
    print_dashboard()
Prints a high-tech terminal view of all known actors and their memory lengths.
"""
function print_dashboard()
    println("\n" * "="^45)
    println("      ADVERL EXPERT OBSERVATORY (Grid View)      ")
    println("="^45)

    lock(Registry.RegistryLock) do
        if isempty(GlobalRegistry)
            println(" [WARN] No actors in Global Grid yet.")
            return nothing
        end

        println(rpad("ACTOR NAME", 20) * rpad("STATE", 15) * rpad("MAILBOX WAIT", 15))
        println("-"^45)

        for (name, actor) in GlobalRegistry
            state = if istaskdone(actor.task)
                if istaskfailed(actor.task)
                    "CRASHED"
                else
                    "DONE"
                end
            else
                "ALIVE"
            end

            mbox_wait = string(Base.n_avail(actor.inbox))

            println(rpad(string(name), 20) * rpad(state, 15) * rpad(mbox_wait, 15))
        end
    end
    println("="^45 * "\n")
end

end # module Dashboard
