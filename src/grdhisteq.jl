"""
	grdhisteq(cmd0::String="", arg1=nothing, kwargs...)

Find the data values which divide a given grid file into patches of equal area. One common use of
grdhisteq is in a kind of histogram equalization of an image.

See full GMT (not the `GMT.jl` one) docs at [`grdhisteq`]($(GMTdoc)grdhisteq.html)

Parameters
----------

- **D** | **dump** :: [Type => Str or []]

    Dump level information to file, or standard output if no file is provided.
- **G** | **save** | **outgrid** | **outfile** :: [Type => Str]

    Output grid file name. Note that this is optional and to be used only when saving
    the result directly on disk. Otherwise, just use the G = grdhisteq(....) form.
- **N** | **gaussian** :: [Type => Number or []]

    Gaussian output.
- **Q** | **quadratic** :: [Type => Bool]

    Quadratic output. Selects quadratic histogram equalization. [Default is linear].
- $(GMT._opt_R)
- $(GMT.opt_V)

To see the full documentation type: ``@? grdhisteq``
"""
function grdhisteq(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:G :R :V_params])
	cmd  = parse_these_opts(cmd, d, [[:C :n_cells], [:D :dump], [:N :gaussian], [:Q :quadratic]])
	common_grd(d, cmd0, cmd, "grdhisteq ", arg1)		# Finish build cmd and run it
end

# ---------------------------------------------------------------------------------------------------
grdhisteq(arg1; kw...) = grdhisteq("", arg1; kw...)