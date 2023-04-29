"""
	gmtspectrum1d(cmd0::String="", arg1=nothing, kwargs...)

Compute auto- [and cross- ] spectra from one [or two] time-series.

See full GMT (not the `GMT.jl` one) docs at [`spectrum1d`]($(GMTdoc)spectrum1d.html)

Parameters
----------

- **S** | **size** :: [Type => Str]        ``Arg = segment_size``

    ``segment_size`` is a radix-2 number of samples per window for ensemble averaging.
- **C** | **response_fun** :: [Type => Str | []]        ``Arg = [xycnpago]``

    Read the first two columns of input as samples of two time-series, X(t) and Y(t).
    Consider Y(t) to be the output and X(t) the input in a linear system with noise.
- **D** | **sample_dist** :: [Type => Number]   ``Arg = dt``

    Set the spacing between samples in the time-series [Default = 1].
- **L** | **leave_trend** :: [Type => Str | []]     ``Arg = [h|m]``

    Leave trend alone. By default, a linear trend will be removed prior to the transform.
- **N** | **time_col** :: [Type => Int]      ``Arg = t_col``

    Indicates which
- **T** :: [Type => Bool]

    Disable the writing of a single composite results file to stdout.
- **W** | **wavelength** :: [Type => Bool | Str]

    Write Wavelength rather than frequency in column 1 of the output file[s] [Default = frequency, (cycles / dt)].
- $(GMT.opt_V)
- $(GMT.opt_write)
- $(GMT.opt_append)
- $(GMT.opt_b)
- $(GMT.opt_d)
- $(GMT.opt_e)
- $(GMT._opt_f)
- $(GMT.opt_g)
- $(GMT._opt_h)
- $(GMT._opt_i)
- $(GMT.opt_swap_xy)

To see the full documentation type: ``@? spectrum1d``
"""
function spectrum1d(cmd0::String="", arg1=nothing; kwargs...)

	d = init_module(false, kwargs...)[1]		# Also checks if the user wants ONLY the HELP mode
	cmd, = parse_common_opts(d, "", [:V_params :b :d :e :g :h :i :yx])
	cmd  = parse_these_opts(cmd, d, [[:C :response_fun], [:D :sample_dist], [:L :leave_trend], [:N :time_col],
	                                 [:S :size], [:T], [:W :wavelength]])
	common_grd(d, cmd0, cmd, "spectrum1d ", arg1)		# Finish build cmd and run it
end

# -------------------------------------------------------------------------------------------------
spectrum1d(arg1; kw...) = spectrum1d("", arg1; kw...)