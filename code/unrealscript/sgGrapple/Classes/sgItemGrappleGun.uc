class sgItemGrappleGun extends sgaItem;

simulated function PostBeginPlay() {
	Super.PostBeginPlay();
	InventoryType = String(class'GrappleGun');
}

simulated function OnGive(Pawn Target, Inventory Inv) {
	GrappleGun(Inv).ProjectileSpeed = GrappleGun(Inv).ProjectileSpeed * (1.25*Grade/5);
}

defaultproperties {
	// InventoryType="kxGrapple.GrappleGun"
	// InventoryClass=class'kxGrapple.GrappleGun'
	BuildingName="Grapple Gun"
	BuildCost=1000
	UpgradeCost=30
	// Model=LodMesh'Botpack.Trans3loc'
	Model=LodMesh'UnrealShare.GrenadeM'
}

