#define DRIVER_SEAT "Пилота"
#define GUNNER_SEAT "Стрелка"

#define NOMAD_DOWN 1
#define NOMAD_UP 2

#define COMSIG_MECHA_EQUIPMENT_CLICK "mecha_action_equipment_click"

/obj/mecha/combat/nomad
	desc = "A lightweight, security exosuit. Popular among private and corporate security."
	name = "Кочевник"
	icon = 'modular_ss220/event_invasion/icons/mecha.dmi'
	icon_state = "mech-down-0-0"
	initial_icon = "mech"
	step_in = 3
	opacity = 0
	dir_in = 1
	pixel_x = -16
	pixel_y = 32
	max_integrity = 5000
	deflect_chance = 5
	armor = list(melee = 50, bullet = 50, laser = 50, energy = 55, bomb = 50, rad = 50, fire = 100, acid = 75)
	max_temperature = 50000
	infra_luminosity = 6
	leg_overload_coeff = 2
	wreckage = /obj/structure/mecha_wreckage/gygax
	internal_damage_threshold = 35
	max_equip = 3
	maxsize = 2
	step_energy_drain = 3
	normal_step_energy_drain = 3
	starting_voice = /obj/item/mecha_modkit/voice/syndicate/nomad
	var/mob/living/carbon/gunner = null
	var/datum/action/innate/mecha/gunner_mech_eject/gunner_eject_action = new
	var/datum/action/innate/mecha/strafe/strafing_action = new
	var/datum/action/innate/mecha/change_stance/change_stance_action = new
	eject_action = new /datum/action/innate/mecha/mech_eject/nomad

	var/strafe = FALSE
	var/image/guns_overlay
	var/stance = NOMAD_DOWN

/obj/mecha/combat/nomad/Initialize()
	. = ..()

	appearance_flags |= PIXEL_SCALE
	transform = transform.Scale(2, 2)
	guns_overlay = image('modular_ss220/event_invasion/icons/mecha.dmi', "weapon_over")
	guns_overlay.appearance_flags |= PIXEL_SCALE
	guns_overlay.layer = layer - 0.1
	// guns_overlay.transform = guns_overlay.transform.Scale(2, 2)
	update_icon(UPDATE_ICON_STATE)
	set_nomad_overlays(NOMAD_DOWN)
	var/obj/item/mecha_parts/mecha_equipment/nomad_gun = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/carbine/nomad
	nomad_gun.attach(src)
	nomad_gun = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/heavy
	nomad_gun.attach(src)

/obj/mecha/combat/nomad/proc/set_nomad_overlays(state)
	cut_overlays()

	switch(state)
		if(NOMAD_DOWN)
			overlays += guns_overlay

/obj/mecha/combat/nomad/update_icon_state()
	. = ..()
	if(stance == NOMAD_UP)
		icon_state = "mech"
	else if(stance == NOMAD_DOWN)
		icon_state = "mech-down-[occupant ? 1 : 0]-[gunner ? 1 : 0]"


/obj/mecha/combat/nomad/MouseDrop_T(mob/M, mob/user)
	if(frozen)
		to_chat(user, "<span class='warning'>Do not enter Admin-Frozen mechs.</span>")
		return TRUE
	if(user.incapacitated())
		return
	if(user != M)
		return
	if(stance == NOMAD_UP)
		to_chat(user, "<span class='warning'>\"Кочевник\" в боевой стойке. Вы не можете войти в него</span>")
		return TRUE
	log_message("[user] tries to move in.")
	if(occupant && gunner)
		to_chat(user, "<span class='warning'>[src] уже занят!</span>")
		log_append_to_last("Permission denied.")
		return TRUE

	var/input = tgui_alert(user, "Вы хотите сесть на место?:", "Выбор места", list(DRIVER_SEAT, GUNNER_SEAT))
	switch (input)
		if(DRIVER_SEAT)
			if(occupant)
				to_chat(user, "<span class='warning'>[src] уже имеет пилота!</span>")
				log_append_to_last("Permission denied.")
				return TRUE
		if(GUNNER_SEAT)
			if(gunner)
				to_chat(user, "<span class='warning'>[src] уже имеет стрелка!</span>")
				log_append_to_last("Permission denied.")
				return TRUE
		else
			return TRUE
	var/passed
	if(dna)
		if(ishuman(user))
			if(user.dna.unique_enzymes == dna)
				passed = 1
	else if(operation_allowed(user))
		passed = 1
	if(!passed)
		to_chat(user, "<span class='warning'>Access denied.</span>")
		log_append_to_last("Permission denied.")
		return TRUE
	if(user.buckled)
		to_chat(user, "<span class='warning'>You are currently buckled and cannot move.</span>")
		log_append_to_last("Permission denied.")
		return TRUE
	if(user.has_buckled_mobs()) //mob attached to us
		to_chat(user, "<span class='warning'>You can't enter the exosuit with other creatures attached to you!</span>")
		return TRUE

	visible_message("<span class='notice'>[user] starts to climb into [src]")
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/mecha/combat/nomad, put_in_seat), user, input)
	return TRUE

/obj/mecha/combat/nomad/proc/put_in_seat(mob/user, seat)
	if(do_after(user, mech_enter_time, target = src))
		if(obj_integrity <= 0)
			to_chat(user, "<span class='warning'>You cannot get in the [name], it has been destroyed!</span>")
		else if(occupant && seat == DRIVER_SEAT)
			to_chat(user, "<span class='danger'>[occupant] was faster! Try better next time, loser.</span>")
		else if(gunner && seat == GUNNER_SEAT)
			to_chat(user, "<span class='danger'>[gunner] was faster! Try better next time, loser.</span>")
		else if(user.buckled)
			to_chat(user, "<span class='warning'>You can't enter the exosuit while buckled.</span>")
		else if(user.has_buckled_mobs())
			to_chat(user, "<span class='warning'>You can't enter the exosuit with other creatures attached to you!</span>")
		else
			moved_inside_seat(user, seat)
	else
		to_chat(user, "<span class='warning'>You stop entering the exosuit!</span>")

/obj/mecha/combat/nomad/GrantActions(mob/living/user, human_occupant = 0)
	internals_action.Grant(user, src)
	lights_action.Grant(user, src)

	if (user == occupant)
		GrantDriverActions(user)
	else if (user == gunner)
		GrantGunnerActions(user)

/obj/mecha/combat/nomad/proc/GrantDriverActions(mob/living/user)
	eject_action.Grant(user, src)
	stats_action.Grant(user, src)
	strafing_action.Grant(user, src)
	change_stance_action.Grant(user, src)
	if(locate(/obj/item/mecha_parts/mecha_equipment/thrusters) in equipment)
		add_thrusters()

/obj/mecha/combat/nomad/proc/GrantGunnerActions(mob/living/user)
	gunner_eject_action.Grant(user, src)

/obj/mecha/combat/nomad/proc/RemoveGunnerActions(mob/living/user)
	gunner_eject_action.Remove(user)

/obj/mecha/combat/nomad/proc/RemoveDriverActions(mob/living/user)
	eject_action.Remove(user)
	stats_action.Remove(user)
	strafing_action.Remove(user)
	thrusters_action.Remove(user)

/obj/mecha/combat/nomad/RemoveActions(mob/living/user, human_occupant = 0)
	internals_action.Remove(user)
	lights_action.Remove(user)

	if (user == occupant)
		RemoveDriverActions(user)
		occupant.client.RemoveViewMod("mecha-auto-zoom")
	if (user == gunner)
		RemoveGunnerActions(user)
		gunner.client.RemoveViewMod("mecha-auto-zoom")

/obj/mecha/combat/nomad/domove(direction)
	if(can_move >= world.time)
		return FALSE
	if(!Process_Spacemove(direction))
		return FALSE
	if(!has_charge(step_energy_drain))
		return FALSE
	if(stance == NOMAD_DOWN)
		if(world.time - last_message > 20)
			occupant_message("<span class='danger'>Вы не можете двигаться, \"Кочевник\" сидит.</span>")
			last_message = world.time
		return FALSE
	if(defence_mode)
		if(world.time - last_message > 20)
			occupant_message("<span class='danger'>Unable to move while in defence mode.</span>")
			last_message = world.time
		return FALSE
	if(zoom_mode)
		if(world.time - last_message > 20)
			occupant_message("<span class='danger'>Unable to move while in zoom mode.</span>")
			last_message = world.time
		return FALSE

	if(thrusters_active && has_gravity(src))
		thrusters_active = FALSE
		to_chat(occupant, "<span class='notice'>Thrusters automatically disabled.</span>")
		step_in = initial(step_in)
	var/move_result = 0
	var/move_type = 0
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		move_result = mechsteprand()
		move_type = MECHAMOVE_RAND
	else if(src.dir!=direction && !strafe)
		move_result = mechturn(direction)
		move_type = MECHAMOVE_TURN
	else
		move_result = mechstep(direction)
		move_type = MECHAMOVE_STEP

	if(move_result && move_type)
		aftermove(move_type)
		can_move = world.time + step_in
		return TRUE
	return FALSE

/obj/mecha/combat/nomad/mechstep(direction)
	var/current_dir = src.dir
	. = step(src, direction)
	if(strafe)
		src.dir = current_dir
	if(!.)
		if(phasing && get_charge() >= phasing_energy_drain)
			if(can_move < world.time)
				. = FALSE // We lie to mech code and say we didn't get to move, because we want to handle power usage + cooldown ourself
				flick("[initial_icon]-phase", src)
				forceMove(get_step(src, direction))
				use_power(phasing_energy_drain)
				playsound(src, stepsound, 40, 1)
				can_move = world.time + (step_in * 3)
	else if(stepsound)
		playsound(src, stepsound, 40, 1)

/obj/mecha/combat/nomad/proc/moved_inside_seat(mob/living/carbon/human/H as mob, seat)
	if(!(H && H.client && (H in range(2))))
		return FALSE
	switch (seat)
		if(DRIVER_SEAT)
			occupant = H
		if(GUNNER_SEAT)
			gunner = H
	GrantActions(H)
	H.stop_pulling()
	H.forceMove(src)
	add_fingerprint(H)
	forceMove(loc)
	log_append_to_last("[H] moved in as pilot.")
	dir = dir_in
	H.client.AddViewMod("mecha-auto-zoom", 12)
	playsound(src, 'sound/machines/windowdoor.ogg', 50, 1)
	if(!activated)
		SEND_SOUND(occupant, sound(longactivationsound, volume = 50))
		activated = TRUE
	else if(!hasInternalDamage())
		SEND_SOUND(occupant, sound(nominalsound, volume = 50))
	if(state)
		H.throw_alert("locked", /atom/movable/screen/alert/mech_maintenance)
	if(connected_port)
		H.throw_alert("mechaport_d", /atom/movable/screen/alert/mech_port_disconnect)
	update_icon(UPDATE_ICON_STATE)
	return TRUE

/obj/mecha/combat/nomad/click_action(atom/target, mob/user, params)
	if((!occupant && !gunner) || (occupant != user && gunner != user))
		return
	if(user.incapacitated())
		return
	if(phasing)
		occupant_message("<span class='warning'>Unable to interact with objects while phasing.</span>")
		return
	if(state)
		occupant_message("<span class='warning'>Maintenance protocols in effect.</span>")
		return
	if(!get_charge())
		return
	if(src == target)
		return

	var/dir_to_target = get_dir(src, target)
	if(dir_to_target && !(dir_to_target & dir))//wrong direction
		return

	if(hasInternalDamage(MECHA_INT_CONTROL_LOST))
		target = safepick(view(3,target))
		if(!target)
			return

	var/mob/living/L = user
	if(!target.Adjacent(src))
		if(selected && selected.is_ranged() && gunner == user)
			if(HAS_TRAIT(L, TRAIT_PACIFISM) && selected.harmful)
				to_chat(L, "<span class='warning'>You don't want to harm other living beings!</span>")
				return
			if(user.mind?.martial_art?.no_guns)
				to_chat(L, "<span class='warning'>[L.mind.martial_art.no_guns_message]</span>")
				return
			if(SEND_SIGNAL(src, COMSIG_MECHA_EQUIPMENT_CLICK, L, target))
				return
			selected.action(target, params)
	else if(selected && selected.is_melee() && occupant == user)
		if(isliving(target) && selected.harmful && HAS_TRAIT(L, TRAIT_PACIFISM))
			to_chat(user, "<span class='warning'>You don't want to harm other living beings!</span>")
			return
		if(SEND_SIGNAL(src, COMSIG_MECHA_EQUIPMENT_CLICK, L, target))
			return
		selected.action(target, params)
	else
		if(internal_damage & MECHA_INT_CONTROL_LOST)
			target = safepick(oview(1, src))
		if(!melee_can_hit || !isatom(target))
			return
		target.mech_melee_attack(src)
		melee_can_hit = 0
		spawn(melee_cooldown)
			melee_can_hit = 1

/obj/mecha/combat/nomad/relaymove(mob/user, direction)
	if(!direction || frozen)
		return
	if(user != occupant) //While not "realistic", this piece is player friendly.
		if(world.time - last_message > 20)
			to_chat(user, "<span class='notice'>Вы не сидите на месте пилота меха \"[src]\".</span>")
			last_message = world.time
		return FALSE
	if(connected_port)
		if(world.time - last_message > 20)
			occupant_message("<span class='warning'>Unable to move while connected to the air system port!</span>")
			last_message = world.time
		return FALSE
	if(state)
		occupant_message("<span class='danger'>Maintenance protocols in effect.</span>")
		return
	return domove(direction)

/obj/mecha/combat/nomad/Destroy()
	gunner = null
	. = ..()


/datum/action/innate/mecha/change_stance
	name = "Сменить стойку меха"
	button_icon_state = "mech_eject"

/datum/action/innate/mecha/change_stance/Activate()
	if(!owner)
		return

	var/obj/mecha/combat/nomad/parsed_chassis = chassis

	if(!parsed_chassis || parsed_chassis.occupant != owner)
		return
	if(parsed_chassis.strafe)
		to_chat(owner, "<span class='warning'>Вы не можете поменять стойку пока \"Кочевник\" стрейфит.</span>")
		return

	parsed_chassis.dir = SOUTH
	if(parsed_chassis.stance == NOMAD_UP)
		flick("mech-act-down", parsed_chassis)
		parsed_chassis.set_nomad_overlays(NOMAD_DOWN)
		sleep(3 SECONDS)
		parsed_chassis.stance = NOMAD_DOWN
		parsed_chassis.update_icon(UPDATE_ICON_STATE)
	else if(parsed_chassis.stance == NOMAD_DOWN)
		flick("mech-act-up", parsed_chassis)
		sleep(3 SECONDS)
		parsed_chassis.stance = NOMAD_UP
		parsed_chassis.update_icon(UPDATE_ICON_STATE)
		parsed_chassis.set_nomad_overlays(NOMAD_UP)


/datum/action/innate/mecha/mech_eject/nomad/Activate()
	if(!owner)
		return

	var/obj/mecha/combat/nomad/parsed_chassis = chassis

	if(!parsed_chassis || parsed_chassis.occupant != owner)
		return

	if(parsed_chassis.stance == NOMAD_UP)
		to_chat(owner, "<span class='warning'>Вы не можете выйти из \"Кочевника\" пока он в боевой стойке.</span>")
		return

	chassis.go_out()
	parsed_chassis.update_icon(UPDATE_ICON_STATE)

/datum/action/innate/mecha/gunner_mech_eject
	name = "Выйти из меха"
	button_icon_state = "mech_eject"

/datum/action/innate/mecha/gunner_mech_eject/Activate()
	if(!owner)
		return

	var/obj/mecha/combat/nomad/parsed_chassis = chassis

	if(!parsed_chassis || parsed_chassis.gunner != owner)
		return

	if(parsed_chassis.stance == NOMAD_UP)
		to_chat(owner, "<span class='warning'>Вы не можете выйти из \"Кочевника\" пока он в боевой стойке.</span>")
		return

	parsed_chassis.RemoveActions(owner)
	parsed_chassis.gunner = null
	flick("")
	owner.forceMove(get_turf(parsed_chassis))
	parsed_chassis.update_icon(UPDATE_ICON_STATE)

	to_chat(owner, "<span class='notice'>Вы вылезли из меха \"[src]\".</span>")

/datum/action/innate/mecha/strafe
	name = "Переключить режим стрейфа"
	button_icon_state = "strafe"

/datum/action/innate/mecha/strafe/Activate()
	if(!owner || !chassis || chassis.occupant != owner)
		return

	var/obj/mecha/combat/nomad/parsed_chassis = chassis

	if(!parsed_chassis)
		return

	parsed_chassis.strafe = !parsed_chassis.strafe

	chassis.occupant_message("Стрейф [parsed_chassis.strafe ? "активирован" : "деактивирован"].")
	chassis.log_message("Стрейф [parsed_chassis.strafe ? "активирован" : "деактивирован"].")

#undef DRIVER_SEAT
#undef GUNNER_SEAT
#undef COMSIG_MECHA_EQUIPMENT_CLICK

