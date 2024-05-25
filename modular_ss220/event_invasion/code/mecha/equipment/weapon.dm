/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/carbine/nomad

/obj/item/mecha_parts/mecha_equipment/weapon/ballistic/carbine/nomad/action(target, params)
	if(!action_checks(target))
		return

	var/obj/mecha/combat/nomad/parsed_chassis = chassis

	if(!parsed_chassis)
		return

	var/turf/curloc = get_turf(chassis)
	var/turf/targloc = get_turf(target)
	if(!targloc || !istype(targloc) || !curloc)
		return
	if(targloc == curloc)
		return

	set_ready_state(0)
	for(var/i=1 to get_shot_amount())
		var/obj/item/projectile/A = new projectile(curloc)
		A.firer = parsed_chassis.gunner
		A.firer_source_atom = src
		A.original = target
		A.current = curloc

		var/spread = 0
		if(variance)
			if(randomspread)
				spread = round((rand() - 0.5) * variance)
			else
				spread = round((i / projectiles_per_shot - 0.5) * variance)
		A.preparePixelProjectile(target, targloc, parsed_chassis.gunner, params, spread)

		chassis.use_power(energy_drain)
		projectiles--
		A.fire()
		playsound(chassis, fire_sound, 50, 1)

		sleep(max(0, projectile_delay))
	set_ready_state(0)
	log_message("Fired from [name], targeting [target].")
	add_attack_logs(parsed_chassis.gunner, target, "fired a [src]")
	do_after_cooldown()
