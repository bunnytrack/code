class FriendlyMale1 extends TMale1;

/*

#exec TEXTURE IMPORT NAME=ManNew FILE=TEXTURES\mannew.pcx GROUP="icons" MIPS=OFF FLAGS=2
#exec TEXTURE IMPORT NAME=ManNewBelt FILE=TEXTURES\mannewbelt.pcx GROUP="icons" MIPS=OFF

#exec TEXTURE IMPORT NAME=RobeBlue FILE=TEXTURES\blue002.bmp GROUP="FriendlySkins" LODSET=2
#exec TEXTURE IMPORT NAME=RobeRed FILE=TEXTURES\red002.bmp GROUP="FriendlySkins" LODSET=2


#exec MESH  MODELIMPORT MESH=wiz MODELFILE=models\wiz103.PSK LODSTYLE=10
#exec MESH  ORIGIN MESH=wiz X=0 Y=3 Z=0 YAW=0 PITCH=0 ROLL=64
#exec ANIM  IMPORT ANIM=wiz103Anims ANIMFILE=models\wiz103.PSA COMPRESS=1 MAXKEYS=999999
#exec MESHMAP   SCALE MESHMAP=wiz X=14.0 Y=14.0 Z=14.0
#exec MESH  DEFAULTANIM MESH=wiz ANIM=wiz103Anims

// Animation sequences. These can replace or override the implicit (exporter-defined) sequences.
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=WalkSm STARTFRAME=0 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=WalkSmFr STARTFRAME=0 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Walk STARTFRAME=0 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=WalkLg STARTFRAME=5 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=WalkLgFr STARTFRAME=5 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=RunLg STARTFRAME=10 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=RunSm STARTFRAME=15 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=RunLgFr STARTFRAME=10 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=RunSmFr STARTFRAME=15 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Run STARTFRAME=10 NUMFRAMES=5 RATE=5.0000 COMPRESS=1.00 GROUP=None
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=GunHit STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=AimDnLg STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=AimDnSm STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=AimUpLg STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=AimUpSm STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Taunt1 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Breath1 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Breath2 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Breath3 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=CockGun STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DuckWlkL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DuckWlkS STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=HeadHit STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=JumpLgFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=JumpSmFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=LandLgFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=LandSmFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=LeftHit STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Look STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=RightHit STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=StillFrRp STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=StillLgFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=StillSmFr STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=SwimLg STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=SwimSm STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=TreadLg STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=TreadSm STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Victory1 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Wave STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=TurnLg STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=TurnSm STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Breath1L STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Breath2L STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=CockGunL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=LookL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=WaveL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Chat1 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Chat2 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Thrust STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DodgeB STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DodgeF STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DodgeR STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=DodgeL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Fighter STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Flip STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead1 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead2 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead3 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead4 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead5 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead6 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead7 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead8 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead9 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead9B STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead10 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=Dead11 STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=BackRun STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=StrafeL STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 
#EXEC ANIM  SEQUENCE ANIM=wiz103Anims SEQ=StrafeR STARTFRAME=0 NUMFRAMES=1 RATE=5.0000 COMPRESS=1.00 GROUP=None 

// Digest and compress the animation data. Must come after the sequence declarations.
// 'VERBOSE' gives more debugging info in UCC.log 
#exec ANIM DIGEST ANIM=wiz103Anims  VERBOSE

#EXEC TEXTURE IMPORT NAME=wiz103Tex0  FILE=TEXTURES\wiz103.pcx  GROUP=Skins

#EXEC MESHMAP SETTEXTURE MESHMAP=wiz NUM=0 TEXTURE=wiz103Tex0

// Original material [0] is [initialShadingGroup1] SkinIndex: 0 Bitmap:   Path:  

#EXEC MESH WEAPONATTACH MESH=wiz BONE="RHand"
#EXEC MESH WEAPONPOSITION MESH=wiz YAW=0 PITCH=0 ROLL=64 X=0.0 Y=0.0 Z=0.0


#exec AUDIO IMPORT FILE="Sounds\ouch.wav" NAME="ouch" GROUP="FriendlyMaleSounds"

*/


// needed to override the standard head/body multiskin used
static function SetMultiSkin( actor SkinActor, string SkinName, string FaceName, byte TeamNum )
{
	
	super.SetMultiSkin(SkinActor,SkinName,FaceName,TeamNum);
	/*
	if (TeamNum==0)
		SkinActor.Skin = Texture'RobeRed';
	else 
	{
		SkinActor.Skin = Texture'RobeBlue';
//		log("Team is "$string(TeamNum));
	}
	*/
	
}

//ADDED BY AWS 5-24-01
function bool Gibbed( name damageType)
{
	return false; 	
}

function SpawnGibbedCarcass()
{
}

function Carcass SpawnCarcass()
{
	return none;
}
//END ADDED BY AWS 5-24-01

function EndSpree(PlayerReplicationInfo Killer, PlayerReplicationInfo Other)
{
	if ( (Killer == Other) || (Killer == None) )
		ReceiveLocalizedMessage( class'KillingSpreeMessageNew', 1, None, Other );
	else
		ReceiveLocalizedMessage( class'KillingSpreeMessageNew', 0, Other, Killer );
}


