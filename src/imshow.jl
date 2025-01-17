"""
    imshow(arg1; kw...)

Is a simple front end to the [`grdimage`](modules/grdimage)  [`grdview`](modules/grdview) programs that accepts GMTgrid, GMTimage,
2D array of floats or strings with file names of grids or images. The normal options of the *grdimage*
and *grdview* programs also apply here but some clever guessing of suitable necessary parameters is done
if they are not provided. Contrary to other image producing modules the "show' keyword is not necessary to
display the image. Here it is set by default. If user wants to use *imshow* to create layers of a more complex
fig he can use *show=false* for the intermediate layers.

This module uses an internal logic to decide whether use `grdimge`, `grdview` or `plot`. Namely, when the
`view` option is used `grdview` is choosed and a default vertical scale is assigned. However, sometimes we want
a rotated plot, optionally tilted, but not 3D view. In that case use the option `flat=true`, which forces
the use of `grdimage`.

# Examples
```julia-repl
# Plot vertical shaded illuminated view of the Mexican hat
julia> G = gmt("grdmath -R-15/15/-15/15 -I0.3 X Y HYPOT DUP 2 MUL PI MUL 8 DIV COS EXCH NEG 10 DIV EXP MUL =");
julia> imshow(G, shade="+a45")

# Same as above but add automatic contours
julia> imshow(G, shade="+a45", contour=true)

# Plot a random heat map
julia> imshow(rand(128,128))

# Display a web downloaded jpeg image wrapped into a sinusoidal projection
julia> imshow(gmtread()"http://larryfire.files.wordpress.com/2009/07/untooned_jessicarabbit.jpg"), region=:global, frame="g", proj=:sinu)

# Plot images in the walls of the cube for the 3D view cases. Replace file names with those that exist for you.
julia> viz(G, zsize=6, facades=("cenora_base.jpg", "bunny_cenora.webp", "burro_cenora.webp"))
```
See also: [`grdimage`](@ref), [`grdview`](@ref)
"""
function imshow(arg1, x::AbstractVector{Float64}=Float64[], y::AbstractVector{Float64}=Float64[]; kw...)
	# Take a 2D array of floats and turn it into a GMTgrid or if input is a string assume it's a file name
	# In this later case try to figure if it's a grid or an image and act accordingly.

	see = ((val = find_in_kwargs(kw, [:show])[2]) === nothing) ? true : (val != 0)	# No explicit 'show' keyword means show=true

	function isplot3(kw)
		call_plot3 = false
		opt_p = find_in_kwargs(kw, [:p :view :perspective])[1]
		(isa(opt_p, String) && contains(opt_p, '/')) && (call_plot3 = true)
		((isa(opt_p, Tuple) || isa(opt_p, VMr)) && length(opt_p) > 1) && (call_plot3 = true)
		return call_plot3
	end

	is_image = false
	if (isa(arg1, String))		# If it's string it has to be a file name. Check extension to see if is an image
		ext = splitext(arg1)[2]
		if (ext == "" && arg1[1] != '@' && !isfile(arg1))
			G = mat2grid(arg1, x, y)
		else
			G = arg1
			ext = lowercase(ext)
			(ext == ".jpg" || ext == ".tif" || ext == ".tiff" || ext == ".png" || ext == ".bmp" || ext == ".gif") && (is_image = true)
			#snif_GI_set_CTRLlimits(arg1)			# Set CTRL.limits to be eventually used by J=:guess
		end
	elseif (isa(arg1, Array{UInt8}) || isa(arg1, Array{UInt16,3}))
		G = mat2img(arg1; kw...)
	elseif (isGMTdataset(arg1) || (isa(arg1, Matrix{<:Real}) && size(arg1,2) <= 4))
		ginfo = gmt("gmtinfo -C", arg1)
		CTRL.limits[1:4] = ginfo.data[1:4];		CTRL.limits[7:10] = ginfo.data[1:4]
		call_plot3 = ((isa(arg1, GMTdataset) && arg1.geom == Gdal.wkbLineStringZ) || (isa(arg1, Vector{<:GMTdataset}) && arg1[1].geom == Gdal.wkbLineStringZ)) ? true : false		# Should evolve into a fun that detects the several plot3d cases.
		!call_plot3 && (call_plot3 = isplot3(kw))
		return (call_plot3) ? plot3d(arg1; show=see, kw...) : plot(arg1; show=see, kw...)
	elseif (isa(arg1, GMTcpt))
		return (find_in_kwargs(kw, [:D :pos :position])[1] === nothing) ?
		        psscale(arg1; show=true, D="x0/0+w7+h", kw...) : psscale(arg1; show=true, kw...)
	elseif (isdataframe(arg1) || isODE(arg1))
		return isplot3(kw) ? plot3(arg1; show=see, kw...) :  plot(arg1; show=see, kw...)
	else
		G = mat2grid(arg1, x, y, reg=1)						# For displaying, pixel registration is more appropriate
	end

	isa(G, GItype) && snif_GI_set_CTRLlimits(G)				# Set CTRL.limits to be eventually used by J=:guess

	if (is_image)
		grdimage(G; show=see, kw...)
	else
		if (isa(G, String))		# Guess also if call grdview or grdimage 
			if (get(kw, :JZ, 0) != 0 || get(kw, :Jz, 0) != 0 || get(kw, :zscale, 0) != 0 || get(kw, :zsize, 0) != 0)
				(get(kw, :Q, "") == "" && get(kw, :surf, "") == "" && get(kw, :surftype, "") == "") && (kw = (kw..., Q="s"))
				grdview(G; show=see, kw...)			# String when fname is @xxxx
			else
				grdimage(G; show=see, kw...)
			end
		else
			imshow(G; kw...)					# Call the specialized method
		end
	end
end

function imshow(arg1::GMTgrid; kw...)
	# Here the default is to show, but if a 'show' was used let it rule
	d = KW(kw)
	see::Bool = (!haskey(d, :show)) ? true : (d[:show] != 0)	# No explicit 'show' keyword means show=true
	if ((cont_opts = find_in_dict(d, [:contour])[1]) !== nothing)
		new_see = see
		see = false			# because here we know that 'see' has to wait till last command
	end
	opt_p, = parse_common_opts(d, "", [:p :view :perspective], true)
	have_tilles::Bool = ((til = find_in_dict(d, [:T :no_interp :tiles])[1]) !== nothing)
	(!have_tilles && opt_p != "" && !contains(opt_p, '/')) && (flat = true)		# If only 'azimuth' and no 'elev'
	flat::Bool = (find_in_dict(d, [:flat])[1] !== nothing)	# If true, force the use of grdimage
	docube = is_in_kwargs(kw, [:facades :cubeplot])
	(flat && docube) && (flat = false)

	if (!docube && (flat || (opt_p == "" && !have_tilles)))
		(flat && opt_p != "") && (d[:p] = opt_p[4:end])		# Restore the meanwhile deleted -p option
		if ((n_levels = size(arg1, 3)) > 1)
			nc::Int = ((val = find_in_dict(d, [:col :cols :columns])[1]) !== nothing) ? val : 2	# Number of subplot columns
			nl = div(n_levels, nc)
			(rem(n_levels, nc) != 0) && (nl += 1)
			grid = "$(nl)x$(nc)"

			(arg1.geog > 0 && all(CTRL.limits .== 0)) && snif_GI_set_CTRLlimits(arg1)
			(arg1.geog > 0 && is_in_dict(d, [:J :proj :projection]) === nothing) && (d[:J] = "guess")
			opt_J = parse_J(d, "", "", true, false, false)[2]
			(startswith(opt_J, " -JX") && !contains(opt_J, '/')) && (opt_J *= "/0")	# We always want axis equal
  			w, h = plot_GI_size(arg1, opt_J)	# Compute the plot Width,Height given the arg1 limits and proj
			aspect = h / w
			_w = 15 / nc;	_h = _w * aspect

			tits::Vector{String} = String[]
			if ((val = find_in_dict(d, [:titles])[1]) === nothing)
				if     !isempty(arg1.names) tits = arg1.names
				elseif !isempty(arg1.v)     tits = string.(arg1.v)
				else                        tits = string.(collect(1:n_levels))
				end
			elseif (val !== nothing && val != false && val != :no)
				(!isa(val, Vector{String}) || (length(val) != n_levels)) ? @warn("Panel titles must be a string vector with size equal to number of layers in input cube.") : (tits = val)
			end
			rt = !isempty(tits) ? tits : nothing

			tit::Union{String, Nothing} = nothing
			if ((val = find_in_dict(d, [:title])[1]) === nothing)
				!isempty(arg1.title) && (tit = arg1.title)
			elseif (val !== nothing && val != false && val != :no)	# To allow title=:no or title=false
				tit = string(val)::String
			end

			# This is a (poor) pach for a GMT bug that screws when plotting CPTs on the sides.
			margin = "0"
			if ((val = find_in_dict(d, [:colorbar], false)[1]) !== nothing)
				tv = add_opt_module(Dict(:colorbar => val))
				t2 = scan_opt(tv[1], "-D")
				t2 = replace(t2, "JMR" => "JMC")
				!contains(t2, "+o") && (t2 *= "+o$(_w/2 + 0.3)/0")
				t3 = scan_opt(tv[1], "-B")
				d[:colorbar] = (D = t2, B = t3)
				margin = "0.6c/0"
			end

			row_axes = (rt !== nothing) ? (left=true, row_title=true) : (left=true, )
			subplot(grid=grid, dims=(panels=(_w, _h),), row_axes=row_axes, col_axes=(bott=true,), T=tit, margins = margin)
				(rt !== nothing) && (d[:par] = (MAP_TITLE_OFFSET="0p",); d[:title] = rt[1])
				grdimage("", mat2grid(arg1[:,:,1], arg1); d...)
				for k = 2:n_levels
					!isempty(tits) && (d[:title] = rt[k])
					CURRENT_CPT[1] = GMTcpt()	# Force creating a new CPT for next layer
					grdimage("", mat2grid(arg1[:,:,k], arg1); panel=:next, d...)
				end
			subplot(see ? :show : :end)
			R = nothing
		else
			R = grdimage("", arg1; show=see, d...)
		end
	else
		zsize = ((val = find_in_dict(d, [:JZ :Jz :zscale :zsize])[1]) !== nothing) ? val : 8
		srf = ((val = find_in_dict(d, [:Q :surf :surftype])[1]) !== nothing) ? val : "i100"
		done = false
		if (have_tilles)					# This forces some others
			srf = zsize = nothing			# These are mutually exclusive
			opt_p = " -p180/90"
		elseif ((val = find_in_dict(d, [:facades :cubeplot])[1]) !== nothing)	# Plot images on the cube walls
			cubeplot(val..., zsize=zsize, R=arg1, p=opt_p[4:end], back=true)
			R = grdview!(arg1; show=see, Q=srf, d...)
			done = true
		end
		(!done) && (R = grdview(arg1; show=see, p=opt_p[4:end], JZ=zsize, Q=srf, T=til, d...))
	end

	if (isa(cont_opts, Bool))				# Automatic contours
		R = grdcontour!(arg1; J="", show=new_see)
	elseif (isa(cont_opts, NamedTuple))		# Expect a (cont=..., annot=..., ...)
		R = grdcontour!(arg1; J="", show=new_see, cont_opts...)
	end
	return R
end

function imshow(arg1::GMTimage; kw...)
	# Here the default is to show, but if a 'show' was used let it rule
	see::Bool = (!haskey(kw, :show)) ? true : kw[:show]		# No explicit 'show' keyword means show=true
	if (isa(arg1.image, Array{UInt16}))
		I::GMTimage = mat2img(arg1; kw...)
		d = KW(kw)			# Needed because we can't delete from kwargs
		(haskey(kw, :stretch) || haskey(kw, :histo_bounds)) && delete!(d, [:histo_bounds, :stretch])
		grdimage("", I; show=see, d...)
	else
		grdimage("", arg1; show=see, kw...)
	end
end

# Simple method to show CPTs. (May grow)
# Ex: imshow(C, xlabel="Bla", ylabel="Blu"), or imshow(:gray)
imshow(arg1::Symbol; horizontal::Bool=false, kw...) = imshow(makecpt(arg1); horizontal=horizontal, kw...) 
function imshow(arg1::GMTcpt; horizontal::Bool=false, kw...)
	see::Bool = (!haskey(kw, :show)) ? true : kw[:show]		# No explicit 'show' keyword means show=true
	horizontal ? psscale(arg1; D="x8c/1c+w12c/0.5c+jTC+h", show=see, kw...) : psscale(arg1; J="X15/0", D="x8c/1c+w12c/0.5c+jBC", show=see, kw...)
end

function imshow(arg1::Gdal.AbstractDataset; kw...)
	(Gdal.OGRGetDriverByName(Gdal.shortname(getdriver(arg1))) != C_NULL) && return plot(gd2gmt(arg1), show=1)
	imshow(gd2gmt(arg1); kw...)
end

imshow(x::AbstractVector{Float64}, y::AbstractVector{Float64}, f::Function; kw...) = imshow(mat2grid(f, x, y); kw...)

function snif_GI_set_CTRLlimits(G_I)::Bool
	# Set CTRL.limits to be eventually used by J=:guess
	(G_I == "") && return false
	(isa(G_I, String) && (G_I[1] == '@' || startswith(G_I, "http"))) && return false	# Remotes are very dangerous to sniff in

	# Do not call grdinfo over grid/images already in memory
	range::Vector{Float64} = isa(G_I, String) ? vec(grdinfo(G_I, C=:n).data) : G_I.range[1:6]
	if ((isa(G_I, String) && range[2] != range[9] && range[4] != range[10]) ||
		(!isa(G_I, String) && range[2] != size(G_I, 2) && range[4] != size(G_I, 1)))
		CTRL.limits[1:4], CTRL.limits[7:10] = range[1:4], range[1:4]
		return true
	else
		CTRL.limits .= 0.0
	end
	return false
end

imshow(x::AbstractVector{Float64}, f::Function; kw...) = imshow(x, x, f::Function; kw...) 
imshow(f::Function, x::AbstractVector{Float64}; kw...) = imshow(x, x, f::Function; kw...) 
imshow(f::Function, x::AbstractVector{Float64}, y::AbstractVector{Float64}; kw...) = imshow(x, y, f::Function; kw...) 
imshow(x::AbstractVector{Float64}, y::AbstractVector{Float64}, f::String; kw...) = imshow(f::String, x, y; kw...) 
imshow(x::AbstractVector{Float64}, f::String; kw...) = imshow(f::String, x, x; kw...) 

const viz = imshow			# Alias
