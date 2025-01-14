@testset "NEWPROJS" begin

	println("	NEWPROJS")
	
	GMT.geodetic2enu(-81.998,42.002,1000,-82,42,200);

	try
	G = worldrectangular("@earth_relief_10m_g", pm=80);
	G = worldrectangular("@earth_relief_10m_g", pm=-100);
	G,cl = worldrectangular("@earth_relief_10m_g", latlim=90, coast=true);

	grid = worldrectgrid(G, annot_x=[-180,-150,0,150,180])
	plot([0 0])		# Just to have a PS for the next have where to append
	plotgrid!(G, grid)
	catch
	end

	cubeplot(mat2img(rand(UInt8,8,8,3)), p=(145,30), front=false, zsize=10, notop=true, back=true)
	cubeplot(mat2img(rand(UInt8,8,8,3)), mat2img(rand(UInt8,8,8,3)))

	cl = coastlinesproj(proj="fouc");
	grid = graticules(cl);
end
