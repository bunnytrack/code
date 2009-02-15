/* WARNING! This file was auto-generated by jpp.  You probably want to be editing ./sgItemHealthKeg.uc.jpp instead. */


class sgItemDoubleJumpBoots extends sgaItem;

simulated function PostBeginPlay() {
 Super.PostBeginPlay();
 InventoryType = String(class'DoubleJumpBoots');
}

simulated function OnGive(Pawn Target, Inventory Inv) {
 DoubleJumpBoots(Inv).JumpHeight = DoubleJumpBoots(Inv).JumpHeight * (0.6 + 0.45*Grade/5);
}

defaultproperties {
 // InventoryType="kxDoubleJump.DoubleJumpBoots"
 // InventoryClass=class'kxDoubleJump.DoubleJumpBoots'
 BuildingName="DoubleJump Boots"
 BuildCost=600
 UpgradeCost=50
 Model=LodMesh'Botpack.jboot'
}