/datum/quicksand_stage
	/// Duration of this stage
	var/duration = 1 SECONDS
	/// Chance in percent of mob resisting this stage and move back to previous stage
	var/resist_chance = 50
	/// Chance in percent to fail critically and progress to next stage
	var/critical_failure_chance = 50
	/// Message that victim recieves when stage is applied
	var/on_apply_message = "Generic message"
	/// Message that victim recieves when stage is removed
	var/on_successful_resist_message = "Generic message"
	/// Status effect that will be applied in `apply` proc. Null if no status effect should be applied
	var/datum/status_effect/on_apply_status_effect = null

/**
 * Suction stage must be applied to mob this way. Calls `on_apply`.
 */
/datum/quicksand_stage/proc/apply(mob/living/apply_to)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(on_apply_status_effect)
		apply_to.apply_status_effect(on_apply_status_effect)

	on_apply(apply_to)
	to_chat(apply_to, span_danger(on_apply_message))

/**
 * Suction stage must be removed from mob this way. Calls `on_remove`.
 */
/datum/quicksand_stage/proc/remove(mob/living/remove_from, )
	SHOULD_NOT_OVERRIDE(TRUE)

	if(on_apply_status_effect)
		remove_from.remove_status_effect(on_apply_status_effect)

	on_remove(remove_from)
	to_chat(remove_from, span_green(on_successful_resist_message))

/**
 * Override if need to do something specific, when this stage is applied to mob.
 */
/datum/quicksand_stage/proc/on_apply(mob/living/applied_to)
	return

/**
 * Override if need to do something specific, when this stage is removed from mob.
 */
/datum/quicksand_stage/proc/on_remove(mob/living/removed_from)
	return
