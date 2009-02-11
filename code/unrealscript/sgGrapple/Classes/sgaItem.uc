class sgaItem expands sgItem;

// sgItem.GiveItem() was not working for my new items, so I made this class and extend it.
// For flexibility, it uses String InventoryType rather than Class InventoryClass.

var String InventoryType;

simulated event Timer () {
	local Pawn Target;
	Super.Timer();
	if ( (SCount > 0) || (Role != 4) ) {
		return;
	}
	foreach RadiusActors(Class'Pawn',Target,48.0) {
		// Log(Self$" SCount="$SCount$" Role="$Role$" Owner="$Owner$" ~"$Target$"?");
		if ( ((Target == Owner) || (Owner == None) || Owner.bDeleteMe)
			&& Target.bIsPlayer && (Target.Health > 0)
			&& (Target.PlayerReplicationInfo != None)
			&& (Target.PlayerReplicationInfo.Team == Team)
			// && (GiveItem(Target) != None)
			&& SpawnAndGiveTo(Target)
		) {
			Destroy();
			return;
		}
	}
}

simulated function bool SpawnAndGiveTo(Pawn Target) {
	local Inventory inv;
	local class<Inventory> type;
	type = class<Inventory>(DynamicLoadObject(InventoryType,class'Class'));
	if (type == None) {
		// Target.ClientMessage("Can't load class "$InventoryType);
		Log(Self$".SpawnAndGiveTo("$Target.getHumanName()$") Can't load class "$InventoryType);
	}
	inv = Target.FindInventoryType(type);
	if (inv != None) {
		// Target.ClientMessage("You already have "$BuildingName);
		// Log(Self$" "$Target.getHumanName()$" already has "$BuildingName);
		return False; // works
	}
	inv = Spawn(type,Target);
	if (inv == None) {
		// Target.ClientMessage("Can't spawn "$type);
		Log(Self$".SpawnAndGiveTo() Failed to spawn "$type$" for "$Target.getHumanName());
		return False;
	}
	GiveInventory(Target,inv);
	if (inv.PickupSound != None) {
		// Make pickup sound this player:
		Target.PlaySound(inv.PickupSound,SLOT_Interface,5.0);
		// Make pickup sound for other players:
		AmbientSound = inv.PickupSound;
		PlaySound(inv.PickupSound,SLOT_Ambient,5.0);
	}
	OnGive(Target,inv);
	return True;
}

function GiveInventory(Pawn p, Inventory inv) {
	local Weapon w;

	inv.bHeldItem=True;
	inv.RespawnTime=0;

	w = Weapon(inv);
	if (w!=None) {

		// Handle Weapon:
		w.Instigator = P;
		w.BecomeItem();
		P.AddInventory(w);
		// w.GiveTo(p);
		w.GiveAmmo(P);
		// Not for the redeemer (or other 1 ammo weapons):
		if (Weapon(inv)!=None && Weapon(inv).AmmoType!=None && Weapon(inv).AmmoType.AmmoAmount>1) {
			// Increase ammo x 3
			Weapon(inv).AmmoType.AmmoAmount = Weapon(inv).AmmoType.AmmoAmount * 4; // Now 4 sixpacks instead of 3
		}
		w.SetSwitchPriority(P);
		w.WeaponSet(P);
		w.AmbientGlow = 0;

		// DeathMatchPlus does this to weapons:
		if ( p.IsA('PlayerPawn') )
			w.SetHand(PlayerPawn(p).Handedness);
		else
			w.GotoState('Idle');

	} else {

		// Handle other Inventory item:
		inv.GiveTo(p);
		inv.Activate();

	}
	// DONE: Check out what DeathMatchPlus, and Translocator/GrappleGun do to initialise weapons correctly.
	//       We may be missing something we should do for weapons.  In a game with bots I got: WarheadLauncher DM-Liandri.WarheadLauncher3 (F_>
}

simulated function OnGive(Pawn Target, Inventory Inv) {
	// Subclasses can override this if they want to adjust the Inv's properties after it has spawned.
	// e.g. This is where the level of Upgrade of the item can be applied.
}

