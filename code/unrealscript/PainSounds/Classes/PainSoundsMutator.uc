class PainSoundsMutator extends Mutator config(PainSounds);

// This basically produces HitSounds, but we call them PainSounds.  It can be useful if you don't have UTPure.
// It defaults to voice sounds, to emulate the NoDownloads ELMS sounds.  But you can set it to be more like Pure.
// Bots do normally make their own sounds when they take damage, but they make them at their location on the map.
// For PainSounds, we want to play a sound just to the player who caused the damage, so he knows he made a hit.
// Unfortunately, it seems PlaySound cannot play a sound to just one player when called from a mutator.

// PainSoundsMutator is directly imported into FairLMS.  That is where it was first used.

// TODO: Add some mutate commands to test: 1) the various noises, 2) make the sound appear to 1 player only, not others.
// DONE: Optional bTeamHitSounds *Ping/warning* sound when hitting teammates
// TODO: Should auto-disable when Pure is present.
// TODO: Using the default sounds is a bit confusing.  We don't really notice the new sounds!  Instead we should use custom pain sounds, and possibly a beep/warning for team damage.
// DONE: I cannot get the volume loud enough!  Maybe only client code can set volume of sounds? :o
// DONE: We can probably go back to using the String method for sounds in the config now it is working.  That format is easier for admins to edit.

var bool bHitSounds;
var bool bTeamHitSounds;

var config String MalePainSound[12];
var config String FemalePainSound[12];
var config String RobotPainSound[12];
// var config String NaliPainSound[12];
// var config String NaliCowPainSound[12];
// var config String OtherPainSound[12];
// ...
// var config Sound MalePainSnd[12];
// var config Sound FemalePainSnd[12];
var config bool bDev;

defaultproperties {
	bHitSounds=True
	bTeamHitSounds=False

	MalePainSound(0)="UnrealShare.Male.MJump1"
	MalePainSound(1)="UnrealShare.Male.MJump3"
	MalePainSound(2)="UnrealShare.Male.lland01"
	MalePainSound(3)="Botpack.Male.MLand3"
	MalePainSound(4)="UnrealShare.Male.MInjur1"
	MalePainSound(5)="UnrealShare.Male.MInjur2"
	MalePainSound(6)="UnrealShare.Male.MInjur3"
	MalePainSound(7)="UnrealShare.Male.MInjur4"
	MalePainSound(8)="UnrealShare.Male.MDeath1"
	MalePainSound(9)="UnrealShare.Male.MDeath3"
	MalePainSound(10)="UnrealShare.Male.MDeath4"
	// I found these others
	// no good MalePainSound(11)="Botpack.Male.NewGib"
	// no good MalePainSound(12)="Botpack.Male.TMJump3"
	//// MDeath4 - good painful a bit like ND

	FemalePainSound(0)="UnrealShare.Female.jump1fem"
	FemalePainSound(1)="UnrealShare.Female.lland1fem"
	FemalePainSound(2)="UnrealShare.Female.linjur1fem"
	FemalePainSound(3)="UnrealShare.Female.linjur2fem"
	FemalePainSound(4)="UnrealShare.Female.linjur3fem"
	FemalePainSound(5)="UnrealShare.Female.death1dfem"
	FemalePainSound(6)="UnrealShare.Female.death2afem"
	FemalePainSound(7)="UnrealShare.Female.death3cfem"
	FemalePainSound(8)="UnrealShare.Female.death4cfem"
	FemalePainSound(9)="UnrealShare.Female.hinjur4fem"
	//// linjur3fem - often used on ND

	RobotPainSound(0)="Botpack.Boss.bJump1"
	RobotPainSound(1)="Botpack.Boss.BInjur1"
	RobotPainSound(2)="Botpack.Boss.BInjur2"
	RobotPainSound(3)="Botpack.Boss.BInjur3"
	RobotPainSound(4)="Botpack.Boss.BInjur4"
	RobotPainSound(5)="Botpack.Boss.BDeath1"
	RobotPainSound(6)="Botpack.Boss.BDeath3"
	RobotPainSound(7)="Botpack.Boss.BDeath4"

	//// ND:
	// MalePainSound(0)="ExtendedLMS_addon.Sounds.Him"
	// FemalePainSound(0)="ExtendedLMS_addon.Sounds.Her"

	// bDev=False
}
// More sounds:
// Nalis: UnrealShare.Nali.injur[12]n

function PostBeginPlay() {
	Super.PostBeginPlay();
	Level.Game.RegisterDamageMutator(Self);
}

function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation, out Vector Momentum, name DamageType) {
	local int attempt,i;
	local String sndStr;
	local Sound snd;
	local float volume,radius,pitch;
	Super.MutatorTakeDamage(ActualDamage,Victim,InstigatedBy,HitLocation,Momentum,DamageType);
	if (bHitSounds && Victim!=None && PlayerPawn(InstigatedBy)!=None
		&& (bTeamHitSounds || TeamGamePlus(Level.Game)==None || GetTeam(Victim)!=GetTeam(InstigatedBy))
	) {
		// && ActualDamage>0  - sometimes ActualDamage is 0 although he did take damage!  We can only get accurate damage in the gametype =/
		for (attempt=0;attempt<25;attempt++) {
			// i = Int(16*FRand()); // %16;
			// i = Int(10*FRand()*ActualDamage/100)%16;
			// i = Int((4+6*FRand())*ActualDamage/100)%16;
			// i = Int( 16 * FRand() * FClamp(0.2 + ActualDamage/150,0,1) )%16;
			// i = 10*FRand() + 6*FClamp(ActualDamage/200,0,1);
			// i = 4*FRand() + (6+6*FRand())*FClamp(ActualDamage/200,0,1);
			// if (i>=16) i=16*FRand(); // shouldn't ever happen
			i = 4*FRand() + (6+2*FRand())*FClamp(ActualDamage/200,0,1);
			if (i>=12) i=12*FRand(); // shouldn't ever happen
			if (InStr(Caps(Victim.VoiceType),"FEMALE") > -1) {
				sndStr = FemalePainSound[i];
			} else if (InStr(Caps(Victim.VoiceType),"MALE") > -1) {
				sndStr = MalePainSound[i];
			} else {
				sndStr = RobotPainSound[i];
			}
			if (sndStr != "") {
				snd = Sound(DynamicLoadObject(sndStr,class'Sound'));
			// if (true) {
				// } else {
					// snd = MalePainSnd[i];
				// }
				if (snd != None) {
					if (bDev) {
						Log("PainSoundsMutator Successfully loaded sound \""$sndStr$"\" -> "$snd$".");
					}
					// volume = FClamp(2.0+3.0*ActualDamage/100,2.0,5.0);
					volume = 240.0;
					radius = 900.0;
					pitch = 64+128*FRand();
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interface,volume);
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interface,volume,True,radius,pitch);

					//// The only way I found of making it louder was to play on four slots at once.
					//// But since that caused many people to crash, now we only play on 1 slot.
					PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_None,volume,False,radius,pitch);
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Misc,volume,False,radius,pitch);
					if (ActualDamage > 100)
						// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interact,volume,False,radius,pitch);
					/*
					//// Some player were crashing, I think due to sound overload.
					//// I hope removing these was a fix for that bug!
					PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Pain,volume,False,radius,pitch);
					if (ActualDamage > 50)
						PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interact,volume,False,radius,pitch);
					// Windows players were crashing, so I removed two of the slots.  Let's see if this fixes it.
					if (ActualDamage > 100)
						PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Talk,volume,False,radius,pitch);
					if (ActualDamage > 150)
						PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interface,volume,False,radius,pitch);
					*/
					//// I fear this one creates noise in the map:
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Ambient,volume,False,radius,pitch);

					// We could also create some sounds at the Victim's location.
					// This would be loud for the killer if the target is close.
					// But the Victim is probably making his own sound anyway.  :P
					/*
					PlayerPawn(InstigatedBy).SoundVolume = PlayerPawn(InstigatedBy).SoundVolume * 4;
					PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Interface,volume,False,radius,pitch);
					PlayerPawn(InstigatedBy).SoundVolume = PlayerPawn(InstigatedBy).SoundVolume / 4;
					*/
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Talk,volume,False,radius,pitch);
					// PlayerPawn(InstigatedBy).PlaySound(snd,SLOT_Talk,2.0);
					// maybe source sound at hurt player, but make radius wide
					if (bDev) {
						InstigatedBy.ClientMessage("[PainSounds] Playing: "$snd);
					}
					break;
				} else {
					if (bDev) {
						InstigatedBy.ClientMessage("[PainSounds] FAILED to load sound \""$sndStr$"\".");
						Log("[PainSounds] FAILED to load sound \""$sndStr$"\".");
					}
				}
			}
		}
	}
}

function int GetTeam(Actor a) {
 local String s;
 if (Pawn(a)!=None && Pawn(a).PlayerReplicationInfo!=None)
  return Pawn(a).PlayerReplicationInfo.Team;
 s = a.GetPropertyText("Team");
 if (s != "")
  return Int(s);
 return -1;
}

