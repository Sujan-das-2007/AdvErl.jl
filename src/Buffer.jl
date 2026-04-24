module Buffer

export OwnedBuffer, release!, claim!, check_ownership, OwnershipError

struct OwnershipError <: Exception
    msg::String
end

Base.showerror(io::IO, e::OwnershipError) = print(io, "OwnershipError: ", e.msg)

mutable struct OwnedBuffer{T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    owner::Union{Nothing,Task}
end

# Constructor
function OwnedBuffer(data::AbstractArray{T,N}) where {T,N}
    OwnedBuffer{T,N,typeof(data)}(data, current_task())
end

# Ownership Checking
function check_ownership(buf::OwnedBuffer)
    if buf.owner !== current_task()
        throw(
            OwnershipError(
                "Task $(current_task()) tried to access memory owned by $(buf.owner)"
            ),
        )
    end
end

# Array Interface implementation with ownership checks
Base.size(buf::OwnedBuffer) = (check_ownership(buf); size(buf.data))
Base.getindex(buf::OwnedBuffer, I...) = begin
    check_ownership(buf)
    getindex(buf.data, I...)
end
Base.setindex!(buf::OwnedBuffer, v, I...) = begin
    check_ownership(buf)
    setindex!(buf.data, v, I...)
end
Base.IndexStyle(::Type{<:OwnedBuffer{T,N,A}}) where {T,N,A} = IndexStyle(A)

# Hand-off Mechanism
function release!(buf::OwnedBuffer)
    check_ownership(buf) # Only the owner can release it
    buf.owner = nothing
    return buf
end

function claim!(buf::OwnedBuffer)
    if buf.owner !== nothing
        throw(OwnershipError("Cannot claim buffer, currently owned by $(buf.owner)"))
    end
    buf.owner = current_task()
    return buf
end

end # module Buffer
