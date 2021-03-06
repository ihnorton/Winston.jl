import Tk

using Base.Graphics

function drawingwindow(name, w, h, closecb=nothing)
    win = Tk.Window(name, w, h)
    c = Tk.Canvas(win, w, h)
    Tk.pack(c, expand = true, fill = "both")
    if !is(closecb,nothing)
        Tk.bind(win, "<Destroy>", closecb)
    end
    c
end

_saved_canvas = nothing

function tk(self::PlotContainer, args...)
    global _saved_canvas
    opts = Winston.args2dict(args...)
    width = get(opts,"width",Winston.config_value("window","width"))
    height = get(opts,"height",Winston.config_value("window","height"))
    reuse_window = isinteractive() #&& Winston.config_value("window","reuse")
    device = _saved_canvas
    if device === nothing || !reuse_window
        device = drawingwindow("Julia", width, height,
                               (x...)->(_saved_canvas=nothing))
        _saved_canvas = device
    else
        @osx_only begin
            device.initialized = false
            Tk.configure(device)
            device.initialized = true
        end
    end
    display(device, self)
    self
end

display(args...) = tk(args...)

function display(c::Tk.Canvas, pc::PlotContainer)
    c.draw = function (_)
        ctx = getgc(c)
        set_source_rgb(ctx, 1, 1, 1)
        paint(ctx)
        Winston.page_compose(pc, Tk.cairo_surface(c))
    end
    Tk.draw(c)
    Tk.update()
end

function get_context(c::Tk.Canvas, pc::PlotContainer)
    device = CairoRenderer(Tk.cairo_surface(c))
    ext_bbox = BoundingBox(0,width(c),0,height(c))
    _get_context(device, ext_bbox, pc)
end

get_context(pc::PlotContainer) = get_context(_saved_canvas, pc)
