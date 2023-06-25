
/*

	All telecommunications interactions:

*/

/obj/machinery/telecomms
	var/temp = "" // output message
	var/tempfreq = FREQ_COMMON
	var/mob/living/operator

/obj/machinery/telecomms/attackby(obj/item/P, mob/user, params)
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]_o", initial(icon_state), P))
		update_icon()
		return
	// Using a multitool lets you access the receiver's interface
	else if(P.tool_behaviour == TOOL_MULTITOOL)
		attack_hand(user)

	else if(default_deconstruction_crowbar(P))
		return
	else
		return ..()

/obj/machinery/telecomms/analyzer_act(mob/living/user, obj/item/T)
	//Prevent the tricorder's air analysis when trying to configure tcomms
	if (istype(T, /obj/item/multitool/tricorder))
		return 
	else
		return ..()

/obj/machinery/telecomms/ui_interact(mob/user, datum/tgui/ui)
	operator = user
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Telecomms")
		ui.open()

/obj/machinery/telecomms/ui_data(mob/user)
	var/list/data = list()

	data += add_option()

	data["minfreq"] = MIN_FREE_FREQ
	data["maxfreq"] = MAX_FREE_FREQ
	data["frequency"] = tempfreq

	var/obj/item/multitool/heldmultitool = get_multitool(user)
	data["multitool"] = heldmultitool

	if(heldmultitool)
		data["multibuff"] = (obj_flags & EMAGGED) ? Gibberish("MULTITOOL BUFFER: NULL (NULL)",100) : heldmultitool.buffer

	data["toggled"] = toggled
	data["id"] = id
	data["displayName"] = display_name.get_unsafe_message()
	data["network"] = network
	data["prefab"] = autolinkers.len ? TRUE : FALSE
	data["emagged"] = (obj_flags & EMAGGED)

	var/list/linked = list()
	var/i = 0
	data["linked"] = list()
	for(var/obj/machinery/telecomms/machine in links)
		i++
		if(machine.hide && !hide)
			continue
		var/list/entry = list()
		entry["index"] = i
		entry["name"] = machine.display_name.get_unsafe_message()
		entry["id"] = machine.id
		linked += list(entry)
	data["linked"] = linked

	var/list/frequencies = list()
	data["frequencies"] = list()
	for(var/x in freq_listening)
		frequencies += list(x)
	data["frequencies"] = frequencies

	return data

/obj/machinery/telecomms/ui_act(action, params)
	. = ..()
	if(.)
		return

	//if(!issilicon(operator)) // Yogs -- deleted old multitool code in favour of actually trusting get_multitool's output
		//if(!istype(operator.get_active_held_item(), /obj/item/multitool))
			//return

	var/obj/item/multitool/heldmultitool = get_multitool(operator)

	switch(action)
		if("toggle")
			toggled = !toggled
			update_power()
			update_icon()
			log_game("[key_name(operator)] toggled [toggled ? "On" : "Off"] [src] at [AREACOORD(src)].")
			. = TRUE
		if("setname")
			if(params.get_boolean("value"))
				if(params.get_encoded_text("value") > 32)
					to_chat(operator, span_warning("Error: Machine hostname too long!"))
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
					return
				else
					display_name = params.get_unsanitised_message_container()
					log_game("[key_name(operator)] has changed the hostname for [src] at [AREACOORD(src)] to [display_name.get_sanitised_text()].")
					. = TRUE
		if("network")
			if(params["value"])
				if(length(params["value"]) > 15)
					to_chat(operator, span_warning("Error: Network name too long!"))
					playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
					return
				else
					for(var/obj/machinery/telecomms/T in links)
						T.links.Remove(src)
					network = params["value"]
					links = list()
					log_game("[key_name(operator)] has changed the network for [src] at [AREACOORD(src)] to [network].")
					. = TRUE
		if("tempfreq")
			if(params["value"])
				tempfreq = text2num(params["value"]) * 10
		if("freq")
			var/newfreq = tempfreq
			if(newfreq == FREQ_SYNDICATE)
				to_chat(operator, span_warning("Error: Interference preventing filtering frequency: \"[newfreq] GHz\""))
				playsound(src, 'sound/machines/buzz-sigh.ogg', 50, TRUE)
			else
				if(!(newfreq in freq_listening) && newfreq < 10000)
					freq_listening.Add(newfreq)
					log_game("[key_name(operator)] added frequency [newfreq] for [src] at [AREACOORD(src)].")
					. = TRUE
		if("delete")
			freq_listening.Remove(params["value"])
			log_game("[key_name(operator)] added removed frequency [params["value"]] for [src] at [AREACOORD(src)].")
			. = TRUE
		if("unlink")
			var/obj/machinery/telecomms/T = links[text2num(params["value"])]
			if(T)
				// Remove link entries from both T and src.
				if(T.links)
					T.links.Remove(src)
				links.Remove(T)
				log_game("[key_name(operator)] unlinked [src] and [T] at [AREACOORD(src)].")
				. = TRUE
		if("link")
			if(heldmultitool)
				var/obj/machinery/telecomms/T = heldmultitool.buffer
				if(istype(T) && T != src)
					if(!(src in T.links))
						T.links += src
					if(!(T in links))
						links += T
						log_game("[key_name(operator)] linked [src] for [T] at [AREACOORD(src)].")
						. = TRUE
		if("buffer") // Yogs start -- holotool support
			if(heldmultitool)
				heldmultitool.buffer = src
			. = TRUE
		if("flush")
			if(heldmultitool)
				heldmultitool.buffer = null // Yogs end
			. = TRUE

	add_act(action, params)
	. = TRUE

/obj/machinery/telecomms/proc/add_option()
	return

/obj/machinery/telecomms/bus/add_option()
	var/list/data = list()
	data["type"] = "bus"
	data["changefrequency"] = change_frequency
	return data

/obj/machinery/telecomms/relay/add_option()
	var/list/data = list()
	data["type"] = "relay"
	data["broadcasting"] = broadcasting
	data["receiving"] = receiving
	return data

/obj/machinery/telecomms/processor/add_option()
	var/list/data = list()
	data["type"] = "processor"
	data["compress"] = process_mode
	return data

/obj/machinery/telecomms/proc/add_act(action, params)

/obj/machinery/telecomms/relay/add_act(action, params)
	switch(action)
		if("broadcast")
			broadcasting = !broadcasting
			. = TRUE
		if("receive")
			receiving = !receiving
			. = TRUE

/obj/machinery/telecomms/bus/add_act(action, params)
	switch(action)
		if("change_freq")
			var/newfreq = text2num(params["value"]) * 10
			if(newfreq)
				if(newfreq < 10000)
					change_frequency = newfreq
					. = TRUE
				else
					change_frequency = 0

/obj/machinery/telecomms/processor/add_act(action, params)
	switch(action)
		if("compression")
			process_mode = !process_mode

// Returns a multitool from a user depending on their mobtype.

/obj/machinery/telecomms/proc/get_multitool(mob/user)

	var/obj/item/multitool/P = null
	// Let's double check
	if(!issilicon(user) && istype(user.get_active_held_item(), /obj/item/multitool))
		P = user.get_active_held_item()
	else if(isAI(user))
		var/mob/living/silicon/ai/U = user
		P = U.aiMulti
	else if(iscyborg(user) && in_range(user, src))
		if(istype(user.get_active_held_item(), /obj/item/multitool))
			P = user.get_active_held_item()
	return P

/obj/machinery/telecomms/proc/canAccess(mob/user)
	if(issilicon(user) || in_range(user, src))
		return TRUE
	return FALSE
