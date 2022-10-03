

#graphing demogrpahics
#need to run grantsandpapers.jl first!

if false
  using Pkg
  Pkg.add("Makie");
  Pkg.add("Cairo");
  Pkg.add("FileIO");
  Pkg.add("Statistics");
  Pkg.add("Gtk");
  Pkg.add("GraphViz")
end

using Cairo, FileIO, Statistics, Gtk, CairoMakie

#alex a. magic here...
using GraphViz

canvas = @GtkCanvas()
window = GtkWindow(canvas, "Makie", 500, 500)

function drawonto(canvas, scene)
    @guarded draw(canvas) do _
       resize!(scene, Gtk.width(canvas), Gtk.height(canvas))
       screen = CairoMakie.CairoScreen(scene, Gtk.cairo_surface(canvas), getgc(canvas), nothing)
       CairoMakie.cairo_draw(screen, scene)
    end
end



scene = heatmap(rand(50, 50)) # or something

drawonto(canvas, scene)
show(canvas); # trigger rendering

