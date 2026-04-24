module Scheduler

export @fair

"""
    @fair expr
A traffic cop macro for Scheduling Fairness.
Injects `yield()` into a long-running for-loop to prevent starvation of the 
Interactive thread pool (like Supervisors running health checks).

Transforms:
```julia
@fair for i in 1:100000
    # heavy math
end
```
into:
```julia
for i in 1:100000
    if i % 1000 == 0
        yield()
    end
    # heavy math
end
```
"""
macro fair(expr)
    if expr.head != :for
        error("@fair macro must be applied to a for loop")
    end

    # Extract the loop variable, iterable, and body
    loop_assignment = expr.args[1]
    loop_var = loop_assignment.args[1] # usually `i`
    loop_body = expr.args[2]

    # Assume we inject the yield check at the start of the loop body
    yield_injection = quote
        # Using a hardcoded reduction limit of 1000 iterations for the PoC
        # In a real system, we'd use a thread-local counter, but since this
        # assumes `i` is an Integer, this works beautifully.
        if $loop_var isa Integer && $loop_var % 1000 == 0
            yield()
        end
    end

    # Prepend the injection to the loop body
    new_body = quote
        $yield_injection
        $loop_body
    end

    # Reconstruct the for-loop
    return esc(Expr(:for, loop_assignment, new_body))
end

end # module Scheduler
