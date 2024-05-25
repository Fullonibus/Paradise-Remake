SUBSYSTEM_DEF(parallax)
	name = "Parallax"
	wait = 2
	flags = SS_POST_FIRE_TIMING | SS_BACKGROUND | SS_NO_INIT
	priority = FIRE_PRIORITY_PARALLAX
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	offline_implications = "Space parallax will no longer move around. No immediate action is needed."
	cpu_display = SS_CPUDISPLAY_HIGH
	var/list/currentrun
	// Планета за кадром на ЦК левеле, достать когда нужно координатами 150,150 в MCtabs-parallax
	var/planet_x_offset = 300
	var/planet_y_offset = 300
	var/random_layer
	var/random_parallax_color


//These are cached per client so needs to be done asap so people joining at roundstart do not miss these.
//Выключение бэкграунда астероидов для ивента//
/datum/controller/subsystem/parallax/PreInit()
	. = ..()
	/*
	if(prob(70)) //70% chance to pick a special extra layer
		random_layer = pick(/atom/movable/screen/parallax_layer/random/space_gas, /atom/movable/screen/parallax_layer/random/asteroids)
		random_parallax_color = pick(COLOR_TEAL, COLOR_GREEN, COLOR_SILVER, COLOR_YELLOW, COLOR_CYAN, COLOR_ORANGE, COLOR_PURPLE) //Special color for random_layer1. Has to be done here so everyone sees the same color.
	*/
	planet_y_offset = rand(300, 300)
	planet_x_offset = rand(300, 300)


/datum/controller/subsystem/parallax/fire(resumed = 0)
	if(!resumed)
		src.currentrun = GLOB.clients.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	while(length(currentrun))
		var/client/C = currentrun[length(currentrun)]
		currentrun.len--
		if(!C || !C.eye)
			if(MC_TICK_CHECK)
				return
			continue
		var/atom/movable/A = C.eye
		if(!istype(A))
			continue
		for(A; isatom(A.loc) && !isturf(A.loc); A = A.loc);

		if(A != C.movingmob)
			if(C.movingmob != null && C.movingmob.client_mobs_in_contents)
				C.movingmob.client_mobs_in_contents -= C.mob
				UNSETEMPTY(C.movingmob.client_mobs_in_contents)
			LAZYINITLIST(A.client_mobs_in_contents)
			A.client_mobs_in_contents += C.mob
			C.movingmob = A
		if(MC_TICK_CHECK)
			return
	currentrun = null
