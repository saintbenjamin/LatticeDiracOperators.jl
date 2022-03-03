
abstract type AbstractFermionfields_2D{NC} <: AbstractFermionfields{NC,2}
end


function Base.setindex!(x::T,v,i1,i2,i5,i6)  where T <: AbstractFermionfields_2D
    @inbounds x.f[i1,i2 + x.NDW,i5 + x.NDW,i6] = v
end

function Base.getindex(x::T,i1,i2,i5,i6) where T <: AbstractFermionfields_2D
    #=
    i2new = i2 .+ x.NDW
    i3new = i3 .+ x.NDW
    i4new = i4 .+ x.NDW
    i5new = i5 .+ x.NDW
    @inbounds return x.f[i1,i2new,i3new,i4new,i5new,i6]
    =#
    @inbounds return x.f[i1,i2 .+ x.NDW,i5 .+ x.NDW,i6]
end

@inline function get_latticeindex_fermion(i,NC,NX,NT)
    #i =(((((ig-1)*NT+it-1)*NZ+iz-1)*NY+iy-1)*NX+ix-1)*NC+ic
    ic = (i-1) % NC + 1
    ii = div(i-ic,NC)
    #ii = (((ig-1)*NT+it-1)*NZ+iz-1)*NY+iy-1)*NX+ix-1
    ix = ii % NX + 1
    ii = div(ii-(ix-1),NX)
    #ii = ((ig-1)*NT+it-1)*NZ+iz-1)*NY+iy-1
    #ii = (ig-1)*NT+it-1
    it = ii % NT + 1
    ig = div(ii-(it-1),NT) + 1
    return ic,ix,it,ig        
end

Base.length(x::T) where T <: AbstractFermionfields_2D = x.NC*x.NX*x.NT*x.NG

function Base.size(x::AbstractFermionfields_2D{NC})  where NC
    return (x.NC,x.NX,x.NT,x.NG)
end

function Base.iterate(x::T,state = 1) where T <: AbstractFermionfields_2D
    if state > length(x)
        return nothing
    end
    
    return (x[state],state+1)
end


function Base.setindex!(x::T,v,i)  where T <: AbstractFermionfields_2D
    ic,ix,it,ig  = get_latticeindex_fermion(i,x.NC,x.NX,x.NT)
    @inbounds x[ic,ix,it,ig] = v
end

function Base.getindex(x::T,i) where T <: AbstractFermionfields_2D
    ic,ix,it,ig  = get_latticeindex_fermion(i,x.NC,x.NX,x.NT)
    @inbounds return x[ic,ix,it,ig]
end



function Base.getindex(F::Adjoint_fermionfields{T},i1,i2,i5,i6) where T <: Abstractfermion  #F'
    @inbounds return conj(F.parent[i1,i2,i5,i6])
end

function Base.setindex!(F::Adjoint_fermionfields{T},v,i1,i2,i5,i6,μ)  where T <: Abstractfermion 
    error("type $(typeof(F)) has no setindex method. This type is read only.")
end



function clear_fermion!(a::Vector{<: AbstractFermionfields_2D{NC}}) where NC 
    for μ=1:4
        clear_fermion!(a[μ])
    end
end

function clear_fermion!(a::AbstractFermionfields_2D{NC}) where NC 
    n1,n2,n5,n6 = size(a.f)
    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            a.f[i1,i2,i5,i6]= 0
                        end
                    end
                #end
            #end
        end
    end
end


function substitute_fermion!(a::AbstractFermionfields_2D{NC},b::AbstractFermionfields_2D{NC}) where NC 
    n1,n2,n5,n6 = size(a.f)
    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            a.f[i1,i2,i5,i6]= b.f[i1,i2,i5,i6]
                        end
                    end
                #end
            #end
        end
    end
end

function substitute_fermion!(a::AbstractFermionfields_2D{NC},b::Abstractfermion) where NC 
    NX = a.NX
    #NY = a.NY
    ##NZ = a.NZ
    NT = a.NT
    NG = a.NG
    @inbounds for i6=1:NG
        for i5=1:NT
            #for i4=1:NZ
                #for i3=1:NY
                    for i2=1:NX
                        @simd for i1=1:NC
                            a[i1,i2,i5,i6]= b[i1,i2,i5,i6]
                        end
                    end
                #end
            #end
        end
    end
    set_wing_fermion!(a)
end





struct Shifted_fermionfields_2D{NC,T} <: Shifted_fermionfields{NC,2}
    parent::T
    #parent::T
    shift::NTuple{2,Int8}
    NC::Int64

    #function Shifted_Gaugefields(U::T,shift,Dim) where {T <: AbstractGaugefields}
    function Shifted_fermionfields_2D(F::AbstractFermionfields_2D{NC},shift) where NC
        return new{NC,typeof(F)}(F,shift,NC)
    end
end

function Base.size(x::Shifted_fermionfields_2D)  
    return size(x.parent)
end
using InteractiveUtils

#=
function shift_fermion(U::AbstractFermionfields_2D{NC},ν::T) where {T <: Integer,NC}
    return shift_fermion(U,Val(ν))
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{1}) where {T <: Integer,NC}
    shift = (1,0,0,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{2}) where {T <: Integer,NC}
    shift = (0,1,0,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{3}) where {T <: Integer,NC}
    shift = (0,0,1,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{4}) where {T <: Integer,NC}
    shift = (0,0,0,1)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{-1}) where {T <: Integer,NC}
    shift = (-1,0,0,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{-2}) where {T <: Integer,NC}
    shift = (0,-1,0,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{-3}) where {T <: Integer,NC}
    shift = (0,0,-1,0)
    return Shifted_fermionfields_2D(U,shift)
end

function shift_fermion(U::AbstractFermionfields_2D{NC},::Val{-4}) where {T <: Integer,NC}
    shift = (0,0,0,-1)
    return Shifted_fermionfields_2D(U,shift)
end
=#


        #lattice shift
function shift_fermion(F::AbstractFermionfields_2D{NC},ν::T) where {T <: Integer,NC}
    if ν == 1
        shift = (1,0)
    elseif ν == 2
        shift = (0,1)
    elseif ν == -1
            shift = (-1,0)
    elseif ν == -2
            shift = (0,-1)
    else
        error("ν = $ν")
    end

    return Shifted_fermionfields_2D(F,shift)
end


function shift_fermion(F::TF,shift::NTuple{Dim,T}) where {Dim,T <: Integer,TF <: AbstractFermionfields_2D}
    return Shifted_fermionfields_2D(F,shift)
end

function Base.setindex!(F::T,v,i1,i2,i5,i6)  where T <: Shifted_fermionfields_2D
    error("type $(typeof(F)) has no setindex method. This type is read only.")
end

function Base.getindex(F::T,i1,i2,i5,i6)  where T <: Shifted_fermionfields_2D
    @inbounds return F.parent[i1,i2.+ F.shift[1],i5.+ F.shift[2],i6]
end

function Base.getindex(F::T,i1::N,i2::N,i5::N,i6::N)  where {T <: Shifted_fermionfields_2D,N <: Integer}
    @inbounds return F.parent[i1,i2 + F.shift[1],i5 + F.shift[2],i6]
end

#=

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(1,0,0,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2.+ 1, i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(-1,0,0,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2 .- 1, i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,1,0,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3 .+ 1,i4,i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,-1,0,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3 .- 1,i4,i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,0,1,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3 ,i4 .+ 1,i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,0,-1,0)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3,i4 .- 1 ,i5,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,0,0,1)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3 ,i4 ,i5 .+ 1,i6]
end

function Base.getindex(F::Shifted_fermionfields_2D{NC,T,Val{(0,0,0,-1)}},i1,i2, i5,i6)  where {NC,T,shift}
    @inbounds return F.parent[i1,i2,i3,i4 ,i5 .- 1,i6]
end
=#

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},A::T,x::T3) where {NC,T<:Abstractfields,T3 <:Abstractfermion}
    #@assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    @assert NC != 3 "NC should not be 3"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for k1=1:NC
                            y[k1,ix,it,ialpha] = 0
                            @simd for k2=1:NC
                                y[k1,ix,it,ialpha] += A[k1,k2,ix,it]*x[k2,ix,it,ialpha]
                            end
                        end
                    end
                #end
            #end
        end
    end
end

@inline function updatefunc!(y,A,x,ix, it,ialpha)
    #@code_llvm  @inbounds x[1,ix, it,ialpha]
    #@code_typed x[1,ix, it,ialpha]
    #error("dd")
    #@code_lowered x[1,ix, it,ialpha]
    x1 = x[1,ix, it,ialpha]
    x2 = x[2,ix, it,ialpha]
    x3 = x[3,ix, it,ialpha]
    y[1,ix, it,ialpha] = A[1,1,ix, it]*x1 + 
                                A[1,2,ix, it]*x2+ 
                                A[1,3,ix, it]*x3
    y[2,ix, it,ialpha] = A[2,1,ix, it]*x1+ 
                                A[2,2,ix, it]*x2 + 
                                A[2,3,ix, it]*x3
    y[3,ix, it,ialpha] = A[3,1,ix, it]*x1+ 
                                A[3,2,ix, it]*x2 + 
                                A[3,3,ix, it]*x3
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{3},A::T,x::T3) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 3 == x.NC "dimension mismatch! NC in y is 3 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            #println("it = ",it, " ialpha = $ialpha")
            ##for iz=1:NZ
            #    #for iy=1:NY
                    for ix=1:NX
                        #updatefunc!(y,A,x,ix, it,ialpha)
                        #error("oo")
                        # #=
                        x1 = x[1,ix, it,ialpha]
                        x2 = x[2,ix, it,ialpha]
                        x3 = x[3,ix, it,ialpha]
                    
                        y[1,ix, it,ialpha] = A[1,1,ix, it]*x1 + 
                                                    A[1,2,ix, it]*x2+ 
                                                    A[1,3,ix, it]*x3
                        y[2,ix, it,ialpha] = A[2,1,ix, it]*x1+ 
                                                    A[2,2,ix, it]*x2 + 
                                                    A[2,3,ix, it]*x3
                        y[3,ix, it,ialpha] = A[3,1,ix, it]*x1+ 
                                                    A[3,2,ix, it]*x2 + 
                                                    A[3,3,ix, it]*x3
                        # =#
                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{3},A::T,x::T3,iseven::Bool) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 3 == x.NC "dimension mismatch! NC in y is 3 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            #println("it = ",it, " ialpha = $ialpha")
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        evenodd = ifelse((ix + iy + iz + it) % 2 == 0,true,false)
                        if evenodd == iseven
                        #updatefunc!(y,A,x,ix, it,ialpha)
                        #error("oo")
                        # #=
                            x1 = x[1,ix, it,ialpha]
                            x2 = x[2,ix, it,ialpha]
                            x3 = x[3,ix, it,ialpha]
                            y[1,ix, it,ialpha] = A[1,1,ix, it]*x1 + 
                                                        A[1,2,ix, it]*x2+ 
                                                        A[1,3,ix, it]*x3
                            y[2,ix, it,ialpha] = A[2,1,ix, it]*x1+ 
                                                        A[2,2,ix, it]*x2 + 
                                                        A[2,3,ix, it]*x3
                            y[3,ix, it,ialpha] = A[3,1,ix, it]*x1+ 
                                                        A[3,2,ix, it]*x2 + 
                                                        A[3,3,ix, it]*x3
                        end
                        # =#
                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{2},A::T,x::T3) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 2 == x.NC "dimension mismatch! NC in y is 2 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        x1 = x[1,ix, it,ialpha]
                        x2 = x[2,ix, it,ialpha]
                        y[1,ix, it,ialpha] = A[1,1,ix, it]*x1 + 
                                                    A[1,2,ix, it]*x2
                        y[2,ix, it,ialpha] = A[2,1,ix, it]*x1+ 
                                                    A[2,2,ix, it]*x2

                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{2},A::T,x::T3,iseven::Bool) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 2 == x.NC "dimension mismatch! NC in y is 2 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        evenodd = ifelse((ix + it) % 2 == 0,true,false)
                        if evenodd == iseven
                            x1 = x[1,ix, it,ialpha]
                            x2 = x[2,ix, it,ialpha]
                            y[1,ix, it,ialpha] = A[1,1,ix, it]*x1 + 
                                                        A[1,2,ix, it]*x2
                            y[2,ix, it,ialpha] = A[2,1,ix, it]*x1+ 
                                                        A[2,2,ix, it]*x2
                        end

                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},x::T3,A::T) where {NC,T<:Abstractfields,T3 <:Abstractfermion}
    #@assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for k1=1:NC
                            y[k1,ix, it,ialpha] = 0
                            @simd for k2=1:NC
                                y[k1,ix, it,ialpha] += x[k1,ix, it,ialpha]*A[k1,k2,ix, it]
                            end
                        end
                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},x::T3,A::T,iseven::Bool) where {NC,T<:Abstractfields,T3 <:Abstractfermion}
    #@assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        evenodd = ifelse((ix + it) % 2 == 0,true,false)
                        if evenodd == iseven

                            for k1=1:NC
                                y[k1,ix, it,ialpha] = 0
                                @simd for k2=1:NC
                                    y[k1,ix, it,ialpha] += x[k1,ix, it,ialpha]*A[k1,k2,ix, it]
                                end
                            end
                        end
                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{3},x::T3,A::T) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 3 == x.NC "dimension mismatch! NC in y is 3 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        x1 = x[1,ix, it,ialpha]
                        x2 = x[2,ix, it,ialpha]
                        x3 = x[3,ix, it,ialpha]
                        y[1,ix, it,ialpha] = x1*A[1,1,ix, it] + 
                                                    x2*A[2,1,ix, it]+ 
                                                    x3*A[3,1,ix, it]
                        y[2,ix, it,ialpha] = x1*A[1,2,ix, it]+ 
                                                    x2*A[2,2,ix, it] + 
                                                    x3*A[3,2,ix, it]
                        y[3,ix, it,ialpha] = x1*A[1,3,ix, it]+ 
                                                    x2*A[2,3,ix, it] + 
                                                    x3*A[3,3,ix, it]
                    end
                #end
            #end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{2},x::T3,A::T) where {T<:Abstractfields,T3 <:Abstractfermion}
    #@assert 2 == x.NC "dimension mismatch! NC in y is 2 but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        x1 = x[1,ix, it,ialpha]
                        x2 = x[2,ix, it,ialpha]
                        y[1,ix, it,ialpha] = x1*A[1,1,ix, it] + 
                                                    x2*A[2,1,ix, it]
                        y[2,ix, it,ialpha] = x1*A[1,2,ix, it]+ 
                                                    x2*A[2,2,ix, it]

                    end
                #end
            #end
        end
    end
end



function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},A::T,x::T3) where {NC,T<:Number,T3 <:Abstractfermion}
    @assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG

    @inbounds for ialpha=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for k1=1:NC
                            y[k1,ix, it,ialpha] = A*x[k1,ix, it,ialpha]
                        end
                    end
                #end
            #end
        end
    end
end

"""
mul!(u,x,y) -> u_{ab} = x_a*y_b
"""
function LinearAlgebra.mul!(u::T1,x::AbstractFermionfields_2D{NC},y::AbstractFermionfields_2D{NC}) where {T1 <: AbstractGaugefields,NC}
    NX = x.NX
    #NY = x.NY
    ##NZ = x.NZ
    NT = x.NT
    NG = x.NG
    clear_U!(u)

    for ik=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for ib=1:NC
                            @simd for ia=1:NC
                                u[ia,ib,ix, it] += x[ia,ix, it,ik]*y[ib,ix, it,ik]
                            end
                        end
                    end
                #end
            #end
        end
    end
    set_wing_U!(u)
end

function LinearAlgebra.mul!(u::T1,x::Abstractfermion,y::Adjoint_fermionfields{<: AbstractFermionfields_2D{NC}}) where {T1 <: AbstractGaugefields,NC}
    _,NX,NT,NG = size(y)
    clear_U!(u)

    for ik=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for ib=1:NC
                            @simd for ia=1:NC
                                u[ia,ib,ix, it] += x[ia,ix, it,ik]*y[ib,ix, it,ik]
                            end
                        end
                    end
                #end
            #end
        end
    end
    set_wing_U!(u)
end

function LinearAlgebra.mul!(u::T1,x::Adjoint_fermionfields{<: Shifted_fermionfields_2D{NC,T}},y::Abstractfermion) where {T1 <: AbstractGaugefields,NC,T}
    _,NX,NT,NG = size(x)
    clear_U!(u)

    for ik=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for ib=1:NC
                            @simd for ia=1:NC
                                u[ia,ib,ix, it] += x[ia,ix, it,ik]*y[ib,ix, it,ik]
                            end
                        end
                    end
                #end
            #end
        end
    end
    set_wing_U!(u)
end


function LinearAlgebra.mul!(u::T1,x::Adjoint_fermionfields{<: AbstractFermionfields_2D{NC}},y::Abstractfermion) where {T1 <: AbstractGaugefields,NC}
    _,NX,NT,NG = size(x)
    clear_U!(u)

    for ik=1:NG
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for ib=1:NC
                            @simd for ia=1:NC
                                u[ia,ib,ix, it] += x[ia,ix, it,ik]*y[ib,ix, it,ik]
                            end
                        end
                    end
                #end
            #end
        end
    end
    set_wing_U!(u)
end




function cross!(u::T1,x::Adjoint_fermionfields{<: Shifted_fermionfields_2D{NC,T}},y::Abstractfermion) where {T1 <: AbstractGaugefields,NC,T}
    mul!(u,y,x)
end

function cross!(u::T1,x::AbstractFermionfields_2D{NC},y::Abstractfermion) where {T1 <: AbstractGaugefields,NC}
    mul!(u,y,x)
end

function cross!(u::T1,x::Abstractfermion,y::Adjoint_fermionfields{<: AbstractFermionfields_2D{NC}}) where {T1 <: AbstractGaugefields,NC}
    mul!(u,y,x)
end

function cross!(u::T1,x::Adjoint_fermionfields{<: AbstractFermionfields_2D{NC}},y::Abstractfermion) where {T1 <: AbstractGaugefields,NC}
    mul!(u,y,x)
end




"""
mul!(y,A,x,α,β) -> α*A*x+β*y -> y
"""
function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},A::T,x::T3,α::TA,β::TB) where {NC,T<:Number,T3 <:Abstractfermion,TA <: Number,TB <: Number}
    @assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG
    if A == one(A)
        @inbounds for ialpha=1:NG
            for it=1:NT
                ##for iz=1:NZ
                    ##for iy=1:NY
                        for ix=1:NX
                            for k1=1:NC
                                y[k1,ix, it,ialpha] = α*x[k1,ix, it,ialpha] + β*y[k1,ix, it,ialpha] 
                            end
                        end
                    #end
                #end
            end
        end
    else
        @inbounds for ialpha=1:NG
            for it=1:NT
                ##for iz=1:NZ
                    ##for iy=1:NY
                        for ix=1:NX
                            for k1=1:NC
                                y[k1,ix, it,ialpha] = A*α*x[k1,ix, it,ialpha] + β*y[k1,ix, it,ialpha] 
                            end
                        end
                    #end
                #end
            end
        end
    end
end

function LinearAlgebra.mul!(y::AbstractFermionfields_2D{NC},A::T,x::T3,α::TA,β::TB,iseven::Bool) where {NC,T<:Number,T3 <:Abstractfermion,TA <: Number,TB <: Number}
    @assert NC == x.NC "dimension mismatch! NC in y is $NC but NC in x is $(x.NC)"
    NX = y.NX
    #NY = y.NY
    ##NZ = y.NZ
    NT = y.NT
    NG = y.NG
    if A == one(A)
        @inbounds for ialpha=1:NG
            for it=1:NT
                ##for iz=1:NZ
                    ##for iy=1:NY
                        for ix=1:NX
                            evenodd = ifelse((ix + it ) % 2 == 0,true,false)
                            if evenodd == iseven
                                for k1=1:NC
                                    y[k1,ix, it,ialpha] = α*x[k1,ix, it,ialpha] + β*y[k1,ix, it,ialpha] 
                                end
                            end
                        end
                    #end
                #end
            end
        end
    else
        @inbounds for ialpha=1:NG
            for it=1:NT
                ##for iz=1:NZ
                    ##for iy=1:NY
                        for ix=1:NX
                            evenodd = ifelse((ix + it ) % 2 == 0,true,false)
                            if evenodd == iseven
                                for k1=1:NC
                                    y[k1,ix, it,ialpha] = A*α*x[k1,ix, it,ialpha] + β*y[k1,ix, it,ialpha] 
                                end
                            end
                        end
                    #end
                #end
            end
        end
    end
end

#Overwrite Y with X*a + Y*b, where a and b are scalars. Return Y.
function LinearAlgebra.axpby!(a::Number, X::T, b::Number, Y::AbstractFermionfields_2D{NC}) where {NC,T <: AbstractFermionfields_2D}
    n1,n2,n5,n6 = size(Y.f)

    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            Y.f[i1,i2,i5,i6] = a*X.f[i1,i2,i5,i6] + b*Y.f[i1,i2,i5,i6]
                        end
                    end
                #end
            #end
        end
    end
    return Y
end

function LinearAlgebra.axpy!(a::Number, X::T, Y::AbstractFermionfields_2D{NC}) where {NC,T <: AbstractFermionfields_2D}
    LinearAlgebra.axpby!(a,X,1,Y)
    return Y
end

function Base.:*(a::Number,x::AbstractFermionfields_2D{NC}) where {NC}
    y = similar(x)
    n1,n2,n5,n6 = size(y.f)

    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            y.f[i1,i2,i5,i6] = a*x.f[i1,i2,i5,i6] 
                        end
                    end
                #end
            #end
        end
    end
    return y
end

function LinearAlgebra.rmul!(x::AbstractFermionfields_2D{NC},a::Number) where {NC}
    n1,n2,n5,n6 = size(x.f)

    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            x.f[i1,i2,i5,i6] = a*x.f[i1,i2,i5,i6] 
                        end
                    end
                #end
            #end
        end
    end
    return x
end




function add_fermion!(c::AbstractFermionfields_2D{NC},α::Number,a::T1,β::Number,b::T2) where {NC,T1 <: Abstractfermion,T2 <: Abstractfermion}#c += alpha*a + beta*b
    n1,n2,n5,n6 = size(c.f)

    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            #println(a.f[i1,i2, i5,i6],"\t",b.f[i1,i2, i5,i6] )
                            c.f[i1,i2,i5,i6] += α*a.f[i1,i2, i5,i6] + β*b.f[i1,i2, i5,i6] 
                        end
                    end
                #end
            #end
        end
    end
    return
end

function add_fermion!(c::AbstractFermionfields_2D{NC},α::Number,a::T1) where {NC,T1 <: Abstractfermion}#c += alpha*a 
    n1,n2,n5,n6 = size(c.f)

    @inbounds for i6=1:n6
        for i5=1:n5
            #for i4=1:n4
                #for i3=1:n3
                    for i2=1:n2
                        @simd for i1=1:NC
                            #println(a.f[i1,i2, i5,i6],"\t",b.f[i1,i2, i5,i6] )
                            c.f[i1,i2, i5,i6] += α*a.f[i1,i2, i5,i6] 
                        end
                    end
                #end
            #end
        end
    end
    return
end

"""
c-------------------------------------------------c
c     Random number function for Gaussian  Noise
    with σ^2 = 1/2
c-------------------------------------------------c
    """
function gauss_distribution_fermion!(x::AbstractFermionfields_2D{NC}) where NC
    NX = x.NX
    #NY = x.NY
    ##NZ = x.NZ
    NT = x.NT
    n6 = size(x.f)[end]
    σ = sqrt(1/2)

    for ialpha = 1:n6
        for it=1:NT
            ##for iz=1:NZ
                ##for iy=1:NY
                    for ix=1:NX
                        for ic=1:NC 
                            x[ic,ix, it,ialpha] = σ*randn()+im*σ*randn()
                        end
                    end
                #end
            #end
        end
    end
    set_wing_fermion!(x)
    return
end

"""
c-------------------------------------------------c
c     Random number function for Gaussian  Noise
    with σ^2 = 1/2
c-------------------------------------------------c
    """
function gauss_distribution_fermion!(x::AbstractFermionfields_2D{NC},randomfunc,σ) where NC
  
    NX = x.NX
    #NY = x.NY
    ##NZ = x.NZ
    NT = x.NT
    n6 = size(x.f)[end]
    #σ = sqrt(1/2)

    for mu = 1:n6
        for ic=1:NC
            for it=1:NT
                ##for iz=1:NZ
                    ##for iy=1:NY
                        for ix=1:NX
                            v1 = sqrt(-log(randomfunc()+1e-10))
                            v2 = 2pi*randomfunc()

                            xr = v1*cos(v2)
                            xi = v1 * sin(v2)

                            x[ic,ix, it,mu] = σ*xr + σ*im*xi
                        end
                    #end
                #end
            end
        end
    end

    set_wing_fermion!(x)

    return
end

function gauss_distribution_fermion!(x::AbstractFermionfields_2D{NC},randomfunc) where NC
    σ = 1
    gauss_distribution_fermion!(x,randomfunc,σ)
end

function Z2_distribution_fermion!(x::AbstractFermionfields_2D{NC})  where NC
    NX = x.NX
    #NY = x.NY
    ##NZ = x.NZ
    NT = x.NT
    n6 = size(x.f)[6]
    #σ = sqrt(1/2)

    for mu = 1:n6
        for it=1:NT
            #for iz=1:NZ
                #for iy=1:NY
                    for ix=1:NX
                        for ic=1:NC
                            x[ic,ix, it,mu] = rand([-1,1])
                        end
                    end
                #end
            #end
        end
    end

    set_wing_fermion!(x)

    return
end

function uniform_distribution_fermion!(x::AbstractFermionfields_2D{NC})  where NC
    NX = x.NX
    #NY = x.NY
    #NZ = x.NZ
    NT = x.NT
    n6 = size(x.f)[6]
    #σ = sqrt(1/2)

    for mu = 1:n6
        for it=1:NT
            #for iz=1:NZ
                #for iy=1:NY
                    for ix=1:NX
                        for ic=1:NC
                            x[ic,ix, it,mu] = rand()*2 - 1 #each element should be in (-1,1)   
                        end
                    end
                #end
            #end
        end
    end

    set_wing_fermion!(x)

    return
end

function fermion2vector!(vector,x::AbstractFermionfields_2D{NC}) where NC
    vector .= 0
    NX = x.NX
    #NY = x.NY
    #NZ = x.NZ
    NT = x.NT
    n6 = size(x.f)[6]
    #σ = sqrt(1/2)

    count = 0
    for mu = 1:n6
        for it=1:NT
            #for iz=1:NZ
                #for iy=1:NY
                    for ix=1:NX
                        for ic=1:NC
                            count += 1
                            vector[count] = x[ic,ix, it,mu] 
                        end
                    end
                #end
            #end
        end
    end

end

function fermions2vectors!(vector,x::Vector{<: AbstractFermionfields_2D{NC}}) where NC
    M = length(x)
    n,m = size(vector)
    @assert M == m

    vector .= 0
    NX = x[1].NX
    #NY = x[1].NY
    #NZ = x[1].NZ
    NT = x[1].NT
    n6 = size(x[1].f)[6]
    #σ = sqrt(1/2)

    for im = 1:M
        count = 0
        for mu = 1:n6
            for it=1:NT
                #for iz=1:NZ
                    #for iy=1:NY
                        for ix=1:NX
                            for ic=1:NC
                                count += 1
                                vector[count,im] = x[im][ic,ix, it,mu] 
                            end
                        end
                    #end
                #end
            end
        end
    end

end


function LinearAlgebra.dot(a::AbstractFermionfields_2D{NC},b::AbstractFermionfields_2D{NC}) where {NC}
    NT = a.NT
    #NZ = a.NZ
    #NY = a.NY
    NX = a.NX
    NG = a.NG

    c = 0.0im
    @inbounds for α=1:NG
        for it=1:NT
            #for iz=1:NZ
                #for iy=1:NY
                    for ix=1:NX
                        @simd for ic=1:NC
                            c+= conj(a[ic,ix, it,α])*b[ic,ix, it,α]
                        end
                    end
                #end
            #end
        end
    end  
    return c
end
