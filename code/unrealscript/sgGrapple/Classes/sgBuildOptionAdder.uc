/* WARNING! This file was auto-generated by jpp.  You probably want to be editing ./sgBuildOptionAdder.uc.jpp instead. */


class sgBuildOptionAdder expands Inventory;

// TODO: Despite the checks appearing to work, on second spawn we see too many build options!  And the ForceGun won't build properly.

/*
// The admin settings were just not getting replicated to clients!
// Until we sort out a better config:
var config bool bAddGrappleGun;
var config bool bAddDoubleJumpBoots;
var config bool bAddForceGun; // oh ffs serveradmin can set this but value isn't replicated :P

// defaultproperties {
	// bAddGrappleGun=True
	// bAddDoubleJumpBoots=True
	// bAddForceGun=False
// }

replication {
	reliable if (Role == ROLE_Authority)
		bAddGrappleGun,bAddDoubleJumpBoots,bAddForceGun;
}
*/





// Example config:
// ExtraItems(1)=ExtraItem(Name="A Bucket",Mesh="BucketMesh",InventoryType="Botpack.Bucket",BuildCost=250,UpgradeCost=50)
// Although this would allow us to add ANY item, it does not give us fine control over what happens when the item is upgraded!
// Mmmm unfortunately the current system requires that a separate sgItem class exists for each item.

var bool bDoneHere; // To prevent us running more than once per client/server -
                    // we check and change the default value of this variable.
// TODO TEST: Does it get reset between mapswitches?!  Maybe it doesn't matter,
// if the default sgCategoryItems we are adjusting also aren't reset. :)

simulated function PostBeginPlay() {
 Log(Self$" - calling AddExtraBuildOptions()");
 AddExtraBuildOptions();
 Super.PostBeginPlay();
}

simulated function AddExtraBuildOptions() {
 // TODO: This should run once per client per runtime, and once per server per runtime!
 //// TODO: Remove Invisibility.  It sucks for sgCTF and sgAS.
 //// TODO: Remove Jetpack from sgAS, and from sgCTF until we can force flagdrop when jetting.
 // if ( ! sgCategoryTeleport.class.default.Selections[4] == class'sgItemGrappleGun' ) {
 // InsertInCategory(class'sgCategoryTeleport',class'sgItemGrappleGun',4);
 // }
 if (default.bDoneHere) {
  Log("sgBuildOptionAdder.AddExtraBuildOptions() Already done here.");
  return;
 }
 default.bDoneHere = True;
 if (True)
  InsertInCategory(class'sgCategoryItems',class'sgItemDoubleJumpBoots',2);
 // InsertInCategory(class'sgCategoryItems',class'sgItemGhost',3);
 if (True)
  InsertInCategory(class'sgCategoryItems',class'sgItemForceGun',5);
 // InsertInCategory(class'sgCategoryItems',class'sgItemSpawner',6); // not an item, just a building!  it doesn't display properly in constructor menu ... maybe if we set its defaults?  it doesn't work anyway :P
 if (True)
  InsertInCategory(class'sgCategoryTeleport',class'sgItemGrappleGun',4);
 // InsertInCategory(class'sgCategoryExplosives',class'sgItemVoiceBox',5); // Was in 2e but not 2g.
}

simulated function InsertInCategory(class<sgBuildCategory> categoryClass, class<sgBuilding> BuildClass, int pos) {
 local int i;
 if (categoryClass.default.Selections[pos] == BuildClass)
  return; // It's already there where we wanted to put it - do nothing.
 for (i=categoryClass.default.NumSelections;i>pos;i--) {
  categoryClass.default.Selections[i] = categoryClass.default.Selections[i-1];
 }
 categoryClass.default.Selections[pos] = BuildClass;
 // Fixes bug where empty selections appear at the end.
 // Probably due to NumSelections being replicated but Selections[] array not.
 if (categoryClass.default.Selections[categoryClass.default.NumSelections] != None)
  categoryClass.default.NumSelections++;
 Log("sgBuildOptionAdder.InsertInCategory() Added "$BuildClass$" to "$categoryClass$" at position "$pos$", expanding total to "$categoryClass.default.NumSelections);
}
