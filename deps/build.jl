
errou = false

depfile = joinpath(dirname(@__FILE__), "deps.jl")

try						# First try to find an existing GMT installation (RECOMENDED WAY)
	(get(ENV, "FORCE_INSTALL_GMT", "") != "") && error("Forcing an automatic GMT install")
	out = readlines(`gmt --version`)[1]
	ver = ((ind = findfirst('_', out)) === nothing) ? VersionNumber(out) : VersionNumber(out[1:ind-1])
	(ver < v"6.1") && error("Need at least GMT6.1. The one you have ($ver) is not supported.")	# GOTO DOWNLOAD

	libgmt = haskey(ENV, "GMT_LIBRARY") ? ENV["GMT_LIBRARY"] : string(chop(read(`gmt --show-library`, String)))
	@static Sys.iswindows() ?
		(Sys.WORD_SIZE == 64 ? (libgdal = "gdal_w64.dll") : (libgdal = "gdal_w32.dll")) : (
			Sys.isapple() ? (libgdal = string(split(readlines(pipeline(`otool -L $(libgmt)`, `grep libgdal`))[1])[1])) : (
				Sys.isunix() ? (libgdal = string(split(readlines(pipeline(`ldd $(libgmt)`, `grep libgdal`))[1])[3])) :
				error("Don't know how to install this package in this OS.")
			)
		)
	@static Sys.iswindows() ?
		(Sys.WORD_SIZE == 64 ? (libproj = "proj_w64.dll") : (libproj = "proj_w32.dll")) : (
			Sys.isapple() ? (libproj = string(split(readlines(pipeline(`otool -L $(libgdal)`, `grep libproj`))[1])[1])) : (
				Sys.isunix() ? (libproj = string(split(readlines(pipeline(`ldd $(libgdal)`, `grep libproj`))[1])[3])) :
				error("Don't know how to use PROJ4 in this OS.")
			)
		)
	GMT_bindir = "C:\\programs\\gmt6\\bin"

catch err1;		println(err1)		# If not, install GMT
	try
		if Sys.iswindows()
			fn = download("http://fct-gmt.ualg.pt/gmt/data/wininstallers/gmt-win64.exe", "GMTinstaller.exe")
			run(`cmd /k GMTinstaller.exe /S`)
			rm(fn, force=true)
			GMT_bindir = "C:\\programs\\gmt6\\bin"
		else
			import Conda
			Conda.add_channel("conda-forge")
			Conda.add("gmt")
			GMT_bindir = joinpath(Conda.ROOTENV, "bin")
		end

		libgmt = abspath(chop(read(`$(joinpath("$(GMT_bindir)", "gmt")) --show-library`, String)))

		@static Sys.iswindows() ? libgdal = "gdal_w64.dll" : (
			Sys.isapple() ? (libgdal = joinpath(Conda.ROOTENV, "lib", string(split(readlines(pipeline(`otool -L $(libgmt)`, `grep libgdal`))[1])[1])[8:end]) )  : (
					Sys.isunix() ? (libgdal = string(split(readlines(pipeline(`ldd $(libgmt)`, `grep libgdal`))[1])[3])) :
					error("Don't know how to install this package in this OS.")
				)
			)

		@static Sys.iswindows() ? libproj = "proj_w64.dll" : (
			Sys.isapple() ? (libproj = joinpath(Conda.ROOTENV, "lib", string(split(readlines(pipeline(`otool -L $(libgdal)`, `grep libproj`))[1])[1])[8:end]) )  : (
					Sys.isunix() ? (libproj = string(split(readlines(pipeline(`ldd $(libgdal)`, `grep libproj`))[1])[3])) :
					error("Don't know how to use PROJ4 in this OS.")
				)
			)
	catch err2;		println(err2)
		erro = true
	end
end

if (!errou)
	userdir = [readlines(`$(joinpath("$(GMT_bindir)", "gmt")) --show-userdir`)[1]]

	# Save shared names in file so that GMT.jl can read them at pre-compile time
	open(depfile, "w") do f
		println(f, "_GMT_bindir = \"", escape_string(GMT_bindir), '"')
		println(f, "_libgmt  = \"", escape_string(libgmt), '"')
		println(f, "_libgdal = \"", escape_string(joinpath(GMT_bindir, libgdal)), '"')
		println(f, "_libproj = \"", escape_string(joinpath(GMT_bindir, libproj)), '"')
		println(f, "ver = " * ver)
		println(f, "userdir = " * userdir)
	end
end