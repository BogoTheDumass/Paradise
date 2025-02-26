/*
 *	Absorbs /obj/item/secstorage.
 *	Reimplements it only slightly to use existing storage functionality.
 *
 *	Contains:
 *		Secure Briefcase
 *		Wall Safe
 */

// -----------------------------
//         Generic Item
// -----------------------------
/obj/item/storage/secure
	name = "secstorage"
	var/icon_locking = "secureb"
	var/icon_sparking = "securespark"
	var/icon_opened = "secure0"
	var/locked = TRUE
	var/code = ""
	var/l_code = null
	var/l_set = FALSE
	var/l_setshort = FALSE
	var/l_hacking = FALSE
	var/open = FALSE
	w_class = WEIGHT_CLASS_NORMAL
	max_w_class = WEIGHT_CLASS_SMALL
	max_combined_w_class = 14

/obj/item/storage/secure/examine(mob/user)
	. = ..()
	if(in_range(user, src))
		. += "The service panel is [open ? "open" : "closed"]."

/obj/item/storage/secure/populate_contents()
	new /obj/item/paper(src)
	new /obj/item/pen(src)

/obj/item/storage/secure/attackby(obj/item/W as obj, mob/user as mob, params)
	if(locked)
		if((istype(W, /obj/item/melee/energy/blade)) && (!emagged))
			emag_act(user, W)

		if(istype(W, /obj/item/multitool) && open && !l_hacking)
			user.show_message("<span class='danger'>Now attempting to reset internal memory, please hold.</span>", 1)
			l_hacking = TRUE
			if(do_after(usr, 100 * W.toolspeed, target = src))
				if(prob(40))
					l_setshort = TRUE
					l_set = FALSE
					user.show_message("<span class='danger'>Internal memory reset. Please give it a few seconds to reinitialize.</span>", 1)
					sleep(80)
					l_setshort = FALSE
					l_hacking = FALSE
				else
					user.show_message("<span class='danger'>Unable to reset internal memory.</span>", 1)
					l_hacking = FALSE
			else
				l_hacking = FALSE
			return
		//At this point you have exhausted all the special things to do when locked
		// ... but it's still locked.
		return

	return ..()

/obj/item/storage/secure/screwdriver_act(mob/living/user, obj/item/I)
	if(do_after(user, 20 * I.toolspeed, target = src))
		open = !open
		user.visible_message("<span class='notice'>[user] [open ? "opens" : "closes"] the service panel on [src].</span>", "<span class='notice'>You [open ? "open" : "close"] the service panel.</span>")
	return TRUE

/obj/item/storage/secure/emag_act(user as mob, weapon as obj)
	if(!emagged)
		emagged = TRUE
		overlays += image('icons/obj/storage.dmi', icon_sparking)
		sleep(6)
		overlays = null
		overlays += image('icons/obj/storage.dmi', icon_locking)
		locked = FALSE
		if(istype(weapon, /obj/item/melee/energy/blade))
			do_sparks(5, 0, loc)
			playsound(loc, 'sound/weapons/blade1.ogg', 50, 1)
			playsound(loc, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
			to_chat(user, "You slice through the lock on [src].")
		else
			to_chat(user, "You short out the lock on [src].")
		return

/obj/item/storage/secure/AltClick(mob/user)
	if(!try_to_open())
		return FALSE
	return ..()

/obj/item/storage/secure/MouseDrop(over_object, src_location, over_location)
	if(!try_to_open())
		return FALSE
	return ..()

/obj/item/storage/secure/proc/try_to_open()
	if(locked)
		add_fingerprint(usr)
		to_chat(usr, "<span class='warning'>It's locked!</span>")
		return FALSE
	return TRUE

/obj/item/storage/secure/attack_self(mob/user as mob)
	user.set_machine(src)
	var/dat = text("<TT><B>[]</B><BR>\n\nLock Status: []", src, (locked ? "LOCKED" : "UNLOCKED"))
	var/message = "Code"
	if(!l_set && !emagged && !l_setshort)
		dat += text("<p>\n<b>5-DIGIT PASSCODE NOT SET.<br>ENTER NEW PASSCODE.</b>")
	if(emagged)
		dat += text("<p>\n<font color=red><b>LOCKING SYSTEM ERROR - 1701</b></font>")
	if(l_setshort)
		dat += text("<p>\n<font color=red><b>ALERT: MEMORY SYSTEM ERROR - 6040 201</b></font>")
	message = text("[]", code)
	if(!locked)
		message = "*****"
	dat += {"<HR>\n>[message]<BR>\n
		<A href='?src=[UID()];type=1'>1</A>-
		<A href='?src=[UID()];type=2'>2</A>-
		<A href='?src=[UID()];type=3'>3</A><BR>\n
		<A href='?src=[UID()];type=4'>4</A>-
		<A href='?src=[UID()];type=5'>5</A>-
		<A href='?src=[UID()];type=6'>6</A><BR>\n
		<A href='?src=[UID()];type=7'>7</A>-
		<A href='?src=[UID()];type=8'>8</A>-
		<A href='?src=[UID()];type=9'>9</A><BR>\n
		<A href='?src=[UID()];type=R'>R</A>-
		<A href='?src=[UID()];type=0'>0</A>-
		<A href='?src=[UID()];type=E'>E</A><BR>\n</TT>"}
	user << browse(dat, "window=caselock;size=300x280")

/obj/item/storage/secure/Topic(href, href_list)
	..()
	if(usr.incapacitated() || (get_dist(src, usr) > 1))
		return
	if(href_list["type"])
		if(href_list["type"] == "E")
			if(!l_set && length(code) == 5 && !l_setshort && code != "ERROR")
				l_code = code
				l_set = TRUE
			else if(code == l_code && !emagged && l_set)
				locked = FALSE
				overlays = null
				overlays += image('icons/obj/storage.dmi', icon_opened)
				code = null
			else
				code = "ERROR"
		else
			if(href_list["type"] == "R" && !emagged && !l_setshort)
				locked = TRUE
				overlays = null
				code = null
				if(usr.s_active == src)
					close(usr)
			else
				code += text("[]", href_list["type"])
				if(length(code) > 5)
					code = "ERROR"
		add_fingerprint(usr)
		for(var/mob/M in viewers(1, loc))
			if((M.client && M.machine == src))
				attack_self(M)
			return
	return

/obj/item/storage/secure/can_be_inserted(obj/item/W as obj, stop_messages = 0)
	if(!locked)
		return ..()
	if(!stop_messages)
		to_chat(usr, "<span class='notice'>[src] is locked!</span>")
	return 0

/obj/item/storage/secure/hear_talk(mob/living/M as mob, list/message_pieces)
	return

/obj/item/storage/secure/hear_message(mob/living/M as mob, msg)
	return

// -----------------------------
//        Secure Briefcase
// -----------------------------
/obj/item/storage/secure/briefcase
	name = "secure briefcase"
	desc = "A large briefcase with a digital locking system."
	icon = 'icons/obj/storage.dmi'
	icon_state = "secure"
	item_state = "sec-case"
	flags = CONDUCT
	hitsound = "swing_hit"
	use_sound = 'sound/effects/briefcase.ogg'
	force = 8
	throw_speed = 2
	throw_range = 4
	w_class = WEIGHT_CLASS_BULKY
	max_w_class = WEIGHT_CLASS_NORMAL
	max_combined_w_class = 21
	attack_verb = list("bashed", "battered", "bludgeoned", "thrashed", "whacked")

/obj/item/storage/secure/briefcase/attack_hand(mob/user as mob)
	if(loc == user && locked)
		to_chat(usr, "<span class='warning'>[src] is locked and cannot be opened!</span>")
	else if((loc == user) && !locked)
		playsound(loc, 'sound/effects/briefcase.ogg', 50, TRUE, -5)
		if(user.s_active)
			user.s_active.close(user) //Close and re-open
		show_to(user)
	else
		..()
		for(var/mob/M in range(1))
			if(M.s_active == src)
				close(M)
		orient2hud(user)
	add_fingerprint(user)
	return

//Syndie variant of Secure Briefcase. Contains space cash, slightly more robust.
/obj/item/storage/secure/briefcase/syndie
	force = 15

/obj/item/storage/secure/briefcase/syndie/populate_contents()
	..()
	for(var/I in 1 to 3)
		new /obj/item/stack/spacecash/c200(src)

// -----------------------------
//        Secure Safe
// -----------------------------

/obj/item/storage/secure/safe
	name = "secure safe"
	icon = 'icons/obj/storage.dmi'
	icon_state = "safe"
	icon_opened = "safe0"
	icon_locking = "safeb"
	icon_sparking = "safespark"
	force = 8
	w_class = WEIGHT_CLASS_HUGE
	max_w_class = 8
	anchored = TRUE
	density = FALSE
	cant_hold = list(/obj/item/storage/secure/briefcase)

/obj/item/storage/secure/safe/attack_hand(mob/user as mob)
	return attack_self(user)
