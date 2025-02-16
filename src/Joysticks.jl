#= MIT License

Copyright (c) 2022 Uwe Fechner, Suavesito-Olimpiada

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

module Joysticks

export JSEvents, JSEvent, JSAxisState                     # types
export JS_EVENT_BUTTON, JS_EVENT_AXIS, JS_EVENT_INIT      # constants
export open_joystick, read_event, axis_state!             # functions

const JSIOCGAXES    = UInt(2147576337)
const JSIOCGBUTTONS = UInt(2147576338)

@enum JSEvents begin
    JS_EVENT_BUTTON = 0x1
    JS_EVENT_AXIS   = 0x02
    JS_EVENT_INIT   = 0x80
end

mutable struct JSDevice
    device::IOStream
    fd::Int32
    axis_count::Int32
    button_count::Int32
end

struct JSEvent
    time::UInt32
    value::Int16
    type::UInt8
    number::UInt8
end

mutable struct JSAxisState
    x::Int16
    y::Int16
    z::Int16
    u::Int16
    v::Int16
    w::Int16
end
function JSAxisState()
    JSAxisState(0, 0, 0, 0, 0, 0)
end

function open_joystick(filename = "/dev/input/js0")
    if  Sys.islinux()
        file = open(filename, "r+")
        device = JSDevice(file, fd(file), 0, 0)
        device.axis_count = axis_count(device) 
        device.button_count = button_count(device)
        return device
    else
        error("Currently Joystick.jl supports only Linux!")
        nothing
    end
end

function axis_count(js::JSDevice)
    axes = Ref{UInt8}()
    if @ccall(ioctl(js.fd::Cint, JSIOCGAXES::Culong; axes::Ref{UInt8})::Cint) == -1
        return -1
    end
    Int64(axes[])
end

function button_count(js::JSDevice)
    buttons = Ref{UInt8}()
    if @ccall(ioctl(js.fd::Cint, JSIOCGBUTTONS::Culong; buttons::Ref{UInt8})::Cint) == -1
        return -1
    end
    Int64(buttons[])
end

function read_event(js::JSDevice)
    event = read(js.device, sizeof(JSEvent); all = false)
    if sizeof(event) != sizeof(JSEvent)
        return nothing
    end
    reinterpret(JSEvent, event)[]
end

function axis_state!(axes::JSAxisState, event::JSEvent)
    axis = event.number+1
    if axis == 1
        axes.x = event.value
    elseif axis == 2
        axes.y = event.value
    elseif axis == 3
        axes.z = event.value
    elseif axis == 4
        axes.u = event.value
    elseif axis == 5
        axes.v = event.value
    elseif axis == 6
        axes.w = event.value
    end
    axis
end

end
