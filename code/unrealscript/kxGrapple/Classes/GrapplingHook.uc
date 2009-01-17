//================================================================================
// GrapplingHook.
//================================================================================
// vim: ts=2 sw=2 expandtab

// TODO: Folding.  Too often when falling it makes the line go into/thru a wall, nota round the edge.  When initially folding we need to check corner visibility and push out if needed using velocity and angle of bend.
//       Sometimes folding moves the corner into an unrealistic place.  It should really be as tight as possible.  Take a look at longitude/latitude.  Move corner in latitude (i actually mean distance down line which is longitude, but it's usually a verticalish axis which would be latitude on a globe), and move in - can we retain visibility but reduce length (make corner as close as possible to edge)?
// TODO: Rather than still allowing fine control of grapple after switching weapon, maybe instead make the grapple continue to move as it did before the weapon switch, i.e. lock its state.  Alternatively, allow user to set the winching state with commands "wind,hold,unwind" so they can make a bind for each.
// DONE: The line might get caught around a corner *before* the grapple has hit a target.  We have not dealt with this case at all.
//       Line now folds whilst hook is in flight.  I introduced TopLineSprite to help with this.
// TODO: When bots hook to Dynamic actor 1) their sprite and physics should go to flying or falling, atm i see the hanging guy walking
//       2) Bots or no bots, the line should reach to the back of the hook, not the centre of Thing.
//       3) Hook often does not update/move.  I think my hook is ok, but other pawns hooks are not.  Either physics is broken, or stuff is not getting replicated, or something.
// CONSIDER: Line mesh could go invisible when line is slack (since it's hard to model a slack rope, at least this indicates that the line is not acting).
// FIXED: The physics are now better, we are changing the velocity.  But sometimes this makes things go a bit crazy.  This is usually when the line length is small, and more often than not, when the pullTarget is a corner, not the grapple.  Their pull velocity will suddenly change when the line catches around a corner.  OK a lot of this was fixed by dampening pull when lineLength<4*MinRetract.  The rest is:
// TODO: Max rotation velocity, or max velocity.
// TODO: When bPrimaryWinch=False, AutoWinch occurs, but it doesn't make a sound!
// DONE: Release sound occurs even if line does not lengthen!
// TODO: People don't seem to like ABV.  Make it default to odd by default.
// TODO: Add optional AutoWinch - dumbass that is just !bPrimaryWinch!  Also ability to fire grapple without switching to it.
// TODO: I want LOW GrappleSpeed when pulling upwards, HIGH GrappleSpeed when pulling horizontally.  This will make it comparable to the Translocator.
// TODO: When winching out with new technique, server and client start to disagree.  Maybe this is because gravity is added to velocity when it shouldn't be?
// TODO: Maybe the winch should gain velocity, starting say at 900, and going to a max of 1800.
// TODO: To avoid being pulled through walls, when we hit a wall, bounce away from it (walljump) according to the normal, maybe a bit upwards if the normal is good, and extend the line a bit, in such a way as to aid the player to getting around the corner they are stuck on.
// TODO: When you release from grapple whilst underwater, i think the physics is set wrong, because i can't go up or down with jump and crouch like normal.  There are a few places we call SetPhysics().
// TESTING: Can we move stuff client-side to make the experience smoother?  E.g. we jerk when we stop a fast unwinching.  Also laggy players jerk a lot, and upward winching jerks given enough speed.  Maybe we just need to update/replicate the Player's Velocity, as well as setting their Location.
// TESTING: Current line release is nice and realistic, but not easy to use.  Make line release constant and medium-speed, so player can tweak his altitude neatly, maybe let it grow (aka power,velocity,sensitivity) a bit, but falling with gravity is too little at the start, and then quickly too much!
// TODO: 
// TESTING: allow player to say ABV as well as mutate it
// TODO: visible jerks when GrappleSpeed is set high (1400+)
// DONE: Fires on (click to) spawn, if GrappleGun is the player's default weapon.  "Fixed" by making it not the default weapon.
// TODO: makes amp sounds when used with amp
// DONE: sometimes trying to hook when we are right next to the walls fails - we need an audio indicator of that (sometimes we hear the ThrowSound twice)  I think we hear the return beep repeated also.
// TODO: Wall hit sound could be a bit better / should be clear + distinct from throw sound.
// DONE: Clicking with both fire buttons should return to previous weapon, as with Translocator.
// TODO: When I switch to this weapon I must wait a moment before I can primary fire, unlike the Translocator.
// DONE: jump to un-grapple (only when holding another weapon)
// DONE: jump to un-grapple sometimes fails because the tick didn't notice bPressedJump if the player only tapped jump quickly.
//       maybe the solution is to do like DoubleJumpBoots, and assign Jump keybind do invoke our jump handler.
//       Ok in the end we used Mutate GrappleJump.
// DONE: now that we have lineLength, we should make it a function of GrappleSpeed.
// TEST maybe fixed: you can get into very fast swings on the ceiling which never stop, presumably because we are always >MinRetract so the dampening never takes effect.
// DONE: it would be nice to have a second mesh - the line between us and the grapple
// DONE: sometimes doublejump intercepts bJumping and clears it, or at any rate we don't see it.
// DONE: if there is lag (on the server) the physics breaks and the player sometimes gets tugged up in the air unrealistically!  Maybe bLinePhysics can help with this...
// TODO: I have not yet put real physics into PullTowardDynamic.
// DONE: At time of writing, bLinePhysics=False appears to have become a bit broken!  Mmm actually I think that may have just been when default did not match server and I changed value mid-game.
// TODO: shieldbelt behind character (by 1 tick?  can this be fixed with velocity or ordering of processing?)
// FIXED: unwind drops back in steps.  now gravity does the unwinding
// UNDERSTOOD: bCrouchReleases makes a noise when bSwingPhysics=False, but does not act :P  If bPrimaryWinch is disabled, we still only get the noise is we primary fire :P (autowind but don't hear winding in unless i click!)
// TODO: Still the issue of primary fire while swinging but switched to another weapon.  Consider preventing winching but allowing it by some other mechanism.
//       The problem appears to be when the server setting is bPrimaryWinch=False but the class default setting is True (so the client does not think the sound needs to be played?).
// CONSIDER: Instead of bPrimaryWinch, bPrimaryFirePausesWinching or bWalkPausesWinching ?
// DONE: Line wrapping around corners magic.  Now GrapplingLines must be created if bLineFolding=True even if bShowLine=False.
// DONE: We should keep bBehindView preference client side.
// TODO: GrappleGun is always the first weapon when we spawn.  It should be enforcer.
// TODO: If we fire to respawn, sometimes we will immediately fire our grapple.
// CONSIDER: Instead of InstigatorRep, shouldn't we just use Master.Owner?  I wonder if the simulated SetMaster() fn guarantees the replication of the variable.
// DONE: GrappleSpeed is scaled down when used for bSwingPhysics, but this is reasonable since swinging can add a lot of speed on top of the winching.
// TODO: We have described one concept as "folding","wrapping" and "splitting" - pick one term and stick with it.
// TESTING: bCrouchReleases is nice now that it just reels out according to gravity.  But for extra realism we could set a max unreel speed.
// FINE: PullTowardDynamic - you can currently grapple onto team-mates :f
// BETTER: PullTowardDynamic - quite buggy, the hook stays suspended in the air, while the opponent warps around and the line points somewhere odd
// BETTER: line does not appear to come out of weapon in firstperson view.
// TODO: would be nice to have a "whipping" sound when the grapple first flies out
// TODO: Just go ahead and somehow fudge the physics so that players can make large upwards swings from the pivot using air control.
// DONE: Grapple will sometimes refuse to embed into corners.  This was fixed by returning to Physics=PHYS_Projectile.
// TODO: On PullTowardDynamic, sometimes the grapple is just left sitting in space, looks naff.  But is the problem the algorithm or replication?
// TEST: You can telefrag other players (incl. teammates?!) by swinging into them.  I think this was caused by SetLocation(), which I have now replaced with MoveSmooth()/Move().
// BUGS: winching out when on floor there should be no sound (cos lineLength does not increase!)
// BUGS: winching in when stuck, the sounds stops, but lineLength is decreasing!
// LATEST FUN BUGS: throw at a wall on face, then walk thru teleporer and use it - creates a lot of messy lines :P
// LATEST FUN BUGS: odd out the front of face, if i wrap the line around the outer wall, the lengths displayed do not add up!
// DONE: grapple should not hurt teammate
// CONSIDER: If we could do the maths correctly, we could do a trace and work out the ideal trajectory to the target point, forcing the correct ThrowAngle.  Then we could remove the anti-grav hax and have a nice soaring grapple.  :)
// DONE: Damage when grapple is pulled back.
// TODO: Allow maximum range on the grappling hook (aka maximum line length).
// DONE: Disabled winch when *also* crouching, so you can fire and swing, or fire and winch, or drop without firing!
// TODO: bJumpAlwaysRetracts - actually only after 1 second after grapple connected.  Before then player might be jumping thinking their grapple has not yet engaged.
// TODO: ABV switching does not work in NM_Standalone!

class GrapplingHook extends Projectile Config(kxGrapple);

#exec AUDIO IMPORT FILE="Sounds\Pull.wav" NAME="Pull" // grindy windy one from ND
// #exec AUDIO IMPORT FILE="Sounds\SoftPull.wav" NAME="SoftPull" // softer one from ND (more robotic)
#exec AUDIO IMPORT FILE="Sounds\greset.wav" NAME="Slurp" // metallic slurp from ND
// #exec AUDIO IMPORT FILE="Sounds\End.wav" NAME="KrrChink" // kchink when grapple hits target
#exec AUDIO IMPORT FILE="Sounds\hit1g.wav" NAME="hit1g" // From UnrealI.GasBag

var() config float GrappleSpeed;
var() config float VerticalGrappleSpeed;
var() config float HitDamage;
var() config bool bDoAttachPawn;
var() config bool bLineOfSight;
var() config bool bLineFolding;
var() config bool bDropFlag;
var() config bool bSwingPhysics;
var() config bool bLinePhysics;
var() config bool bExtraPower;
var() config bool bCrouchReleases;
var() config bool bUnrealUnwind;
var() config float MinRetract;
var() config float ThrowAngle;
var() config bool bShowLine;
var() config sound HitSound,PullSound,ReleaseSound,RetractSound;
var() config Mesh LineMesh;
var() config Texture LineTexture;
var() config bool bLogging;
var() config float StuckSlowdown;

var GrappleGun Master;
var Vector pullDest;
var bool bAttachedToThing;
var Actor thing;
var bool bThingPawn;
var float lineLength;
// var ShockBeam LineSprite;
// var Effects LineSprite;
// var rocketmk2 LineSprite;
var GrapplingLine TopLineSprite,LineSprite; // TopLineSprite is new, I haven't written any replication rule for it.  Oh LineSprite wasn't replicated anyway!  I'm so glad I'm auto-stripping comments from compiled code.
var bool bDestroyed;
var Vector hNormal; // Never actually used, just a temporary variable for Trace().
var Pawn InstigatorRep; // Sometimes the Instigator is not replicated, so we use our own variable to propogate it to the client.
var bool isStuck;

var bool bPrimaryWinch; // This has now become a client option, read from GrappleGun.bFireToWinch.

replication {
  // I believe all config vars need to be replicated because I have set defaults which the client may see unless we transfer the server's values.  Unfortunately I don't think it's working.  OK if no default is set, then they get replicated just fine.  And this replication statement *is* needed!
  reliable if (Role == ROLE_Authority)
    GrappleSpeed,HitDamage,bDoAttachPawn,bLineOfSight,bLineFolding,bDropFlag,bSwingPhysics,bLinePhysics,bExtraPower,bCrouchReleases,bUnrealUnwind,MinRetract,ThrowAngle,bShowLine,HitSound,PullSound,ReleaseSound,RetractSound,LineMesh,LineTexture,bLogging;
  reliable if (Role == ROLE_Authority)
    pullDest,bDestroyed,lineLength,Thing,Master,InstigatorRep; // ,bThingPawn,hNormal;
  reliable if (Role == ROLE_Authority)
    bPrimaryWinch; // ,bThingPawn,hNormal;
  // reliable if (Role == ROLE_Authority)
    // LineSprite; // We don't want the client and server to have different LineSprites, or they will stop themselves!
  // reliable if (Role == ROLE_Authority)
    // InitLineSprite,DoLineOfSightChecks; // This was what was needed to get the variables replicated into the lines.
  // reliable if (Role == ROLE_Authority)
    // UpdateLineSprite; // needed to make it reliable since InitLineSprite was sometimes called from there?
}

function SetMaster (GrappleGun W) {
  Master = W;
  Instigator = Pawn(W.Owner);
  bPrimaryWinch = Master.bFireToWinch;
  // InitLineSprite();
}

function float RateSelf( out int bUseAltMode ) {
  return -1.0;
}

auto state Flying {

  simulated function BeginState () {
    local rotator outRot;
    // Set outgoing Velocity of the grapple, adjusting for ThrowAngle:
    outRot = Rotation;
    outRot.Pitch += ThrowAngle*8192/45;
    Velocity = vector(outRot) * Speed;
    if (ThrowAngle != 0) { // If no angle was given, we let it fly like a projectile.  Otherwise, hooks thrown at an angle will fall with 10% gravity due to compensation later.
      SetPhysics(PHYS_Falling);
    }
    pullDest = Location;
    // Let's point the mesh in the opposite direction:
    outRot.Yaw = Rotation.Yaw + 32768;
    outRot.Pitch = -Rotation.Pitch;
    SetRotation(outRot);
    // We want the client to know the Instigator, but it wasn't getting replicated, so we force it to be replicated via our own variable:
    if (Role == ROLE_Authority) {
      InstigatorRep = Instigator;
    }
    InitLineSprite();
    TopLineSprite = LineSprite;
  }

  simulated function Tick(float DeltaTime) {
    local rotator rot;
    local Vector lineDest;
    lineDest = Location + 11.0*DrawScale*Vector(Rotation);
    // pullDest = Location;
    if (LineSprite!=None && LineSprite.ParentLine!=None) {
      // pullDest has been set elsewhere.
    } else {
      pullDest = lineDest;
    }
    //// Now that we are folding during flight, we need to do this to the top LineSprite only.
    if (TopLineSprite != None)
      TopLineSprite.NearPivot = lineDest;
    // This method only works on LineSprite.  But it appears TopLineSprite updates anyway.  :)
    // UpdateLineSprite();

    // We only need one of the following, depending what Physics type we decide to use.
    // I will probably go with PHYS_Projectile since with PHYS_Falling the hook was refusing to stick in some corners.

    if (Physics == PHYS_Falling) {
      // Orient grapple according to trajectory:
      rot = Rotator(Velocity);
      rot.Yaw += 32768;
      rot.Pitch *= -1;
      SetRotation(rot);

      // Naughty, but I want it to only feel 10% gravity:
      Velocity -= Region.Zone.ZoneGravity*0.9*DeltaTime;
      // If anyone asks, just say that it's equipped with wings which allow it to glide.
      // Alternatively, we could set PHYS_Projectile as before or PHYS_Flying, and do all the gravity ourself.
    }

    if (Physics == PHYS_Projectile) {
      // Falling projectile? ^^
      Velocity += Region.Zone.ZoneGravity*0.2*DeltaTime;
      rot = Rotator(Velocity);
      rot.Yaw += 32768;
      rot.Pitch *= -1;
      SetRotation(rot);
    }

    DoLineOfSightChecks(); // TESTING/Experimental: Although the code was written for PullTowardDynamic, we would like to use it here if it works.  :)
    // OK it kinda breaks.

  }

  // Is this pickup handling?
  simulated function ProcessTouch (Actor Other, Vector HitLocation) {
    Log(Level.TimeSeconds$" "$Self$".ProcessTouch() I've never been here before");
    if ( Inventory(Other) != None ) {
      Inventory(Other).GiveTo(Instigator);
    }
    Instigator.AmbientSound = None;
    AmbientSound = None;
    Destroy();
    return;
  }

  simulated function HitWall (Vector HitNormal, Actor Wall) {
    pullDest = Location + 11.0*DrawScale*Vector(Rotation);
    // InitLineSprite();
    if (TopLineSprite != None)
      TopLineSprite.NearPivot = pullDest;
    hNormal = HitNormal;
    SetPhysics(PHYS_None);
    lineLength = VSize(Instigator.Location - pullDest);
    if (Wall.IsA('Pawn') || Wall.IsA('Mover')) {
      if (!bDoAttachPawn && !Wall.IsA('Mover')) {
        Destroy();
        return;
      }
      bAttachedToThing = True;
      thing = Wall;
      if (Wall.IsA('Pawn')) {
        bThingPawn = True;
      }
      GotoState('PullTowardDynamic');
    } else {
      Velocity = vect(0,0,0);
      GotoState('PullTowardStatic');
    }
    CheckFlagDrop();
    PlaySound(HitSound,SLOT_None,10.0);
    Master.PlaySound(HitSound,SLOT_None,10.0);
    if (GrappleSpeed>0 && !bPrimaryWinch) {
      Master.AmbientSound = PullSound;
      AmbientSound = PullSound;
    } else {
      Master.AmbientSound = None;
      AmbientSound = None;
    }
  }

}

simulated event Destroyed () {
  local int grapCnt;
  local GrapplingHook G;
  local GrapplingLine NextLine;
  if (bLogging) {
    foreach AllActors(class'GrapplingHook',G) {
      grapCnt++;
    }
    Log(Level.TimeSeconds$" "$Self$".Destroyed() destructing with "$grapCnt$" GrapplingHooks on the level.");
  }

  // If we were grappled to an Actor, and that actor is not (a pawn) on the same team, then cause damage as the grapple retracts!
  // TODO: Ideally only do this when the player retracts on purpose, not e.g. if it retracts because he died.  I.e. move this to AltFire detection.
  if ( Thing != None &&
    !(
      Level.Game.IsA('TeamGamePlus') && Pawn(Thing)!=None && bThingPawn
      && Pawn(Thing).PlayerReplicationInfo!=None && Instigator.PlayerReplicationInfo!=None
      && Pawn(Thing).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team
  ) ) {
    Thing.TakeDamage(2*HitDamage,Instigator,(Thing.Location+Location)/2,vect(0,0,0),'');
  }

  Master.GrapplingHook = None;
  AmbientSound = None;
  Master.AmbientSound = None;
  // if (Role==ROLE_Authority && LineSprite!=None) {
  if (bLogging && LineSprite==None) { Log(Level.TimeSeconds$" No LineSprite to cleanup in "$Self$".Destroyed()."); }
  while (LineSprite != None) {
    if (bLogging) { Log(Level.TimeSeconds$" "$Self$".Destroyed() destroying LineSprite chain: "$LineSprite); }
    NextLine = LineSprite.ParentLine;
    LineSprite.GrappleParent = None;
    LineSprite.LifeSpan = 1;
    LineSprite.Destroy();
    // LineSprite = None;
    // lol it's still there
    LineSprite = NextLine;
  }
  bDestroyed = True; // At one stage this marker was how we got child lines to self-destruct.
  // PlaySound(sound'UnrealI.hit1g',SLOT_Interface,10.0);
  // Master.PlaySound(sound'UnrealI.hit1g',SLOT_Interface,10.0);
  // PlaySound(sound'Botpack.Translocator.ReturnTarget',SLOT_Interface,1.0);
  // Master.PlaySound(sound'Botpack.Translocator.ReturnTarget',SLOT_Interface,1.0);
  PlaySound(RetractSound,SLOT_Interface,3.0,,,240);
  Master.PlaySound(RetractSound,SLOT_Interface,3.0,,,240);
  // Master.PlaySound(sound'FlyBuzz', SLOT_Interface, 2.5, False, 32, 16);
  if (Instigator!=None) {
    Instigator.SetPhysics(PHYS_Falling);
  }
  Super.Destroyed();
}

simulated function InitLineSprite() { // simulated needed?
  local float numPoints;
  if (bShowLine || bLineFolding) {
    // if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Running with Role="$Role$" Inst="$Instigator$" InstRep="$InstigatorRep); }
    if (Role != ROLE_Authority) { // spawns it on server only
    // if (Role == ROLE_Authority) { // don't spawn it on server but maybe on client
      if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Not spawning LineSprite at this end."); }
      return;
    }
    // if (Level.NetMode ==1)
      // return;
    /*
    LineSprite = Spawn(class'ShockBeam',,,Instigator.Location,rotator(pullDest-Instigator.Location));
    // LineSprite.bUnlit = False;
    // LineSprite.Style = STY_Normal;
    numPoints = VSize(pullDest-Instigator.Location)/135.0; if (numPoints<1) numPoints=1;
    numPoints = 16;
    LineSprite.MoveAmount = (pullDest-Instigator.Location)/numPoints;
    // LineSprite.MoveAmount = Vect(0,0,0);
    LineSprite.NumPuffs = numPoints-1;
    LineSprite.LifeSpan = 60;
    // LineSprite.NumPuffs = 0;
    // LineSprite.DrawScale = 0.30;
    */

    // LineSprite = Spawn(class'Effects',,,(Instigator.Location+pullDest)/2,rotator(pullDest-Instigator.Location));
    // LineSprite = Spawn(class'rocketmk2',,,(Instigator.Location+pullDest)/2,rotator(pullDest-Instigator.Location));
    if (InstigatorRep==None) {
      if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Warning! InstigatorRep="$InstigatorRep$" so NOT spawning LineSprite now!"); }
      return;
    }
    // Instigator = InstigatorRep; // For client
    if (LineSprite == None) {
      // LineSprite = Spawn(class'GrapplingLine',,,(InstigatorRep.Location+pullDest)/2,rotator(pullDest-InstigatorRep.Location));
      LineSprite = Spawn(class'GrapplingLine',,,,);
      if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Spawned "$LineSprite); }
    } else {
      if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Re-using old UNCLEANED LineSprite "$LineSprite$"!"); }
      LineSprite.DrawType = DT_Mesh;
      LineSprite.SetLocation((InstigatorRep.Location+pullDest)/2);
      LineSprite.SetRotation(rotator(pullDest-InstigatorRep.Location));
    }
    if (LineSprite == None) {
      if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() failed to spawn child GrapplingLine!"); }
      return;
    }
    // LineSprite.SetFromTo(InstigatorRep,Self);
    LineSprite.GrappleParent = Self;
    if (bLogging) { Log(Level.TimeSeconds$" "$Self$".InitLineSprite() Setting NearPivot of new LineSprite to "$pullDest); }
    LineSprite.NearPivot = pullDest; // Actually this may be too early, since the grapple itself is moving.  We set it again later.
    if (!bShowLine) {
      LineSprite.bStopped = True;
      LineSprite.DrawType = DT_None;
      // LineSprite.Disable('Tick'); // Ah no it needs to know when to destroy itself.  Anyway bStopped is set, so Tick() is not doing so much work.
    } else {
      // LineSprite.Mesh = 'botpack.shockbm';
      // LineSprite.Mesh = mesh'Botpack.bolt1';
      LineSprite.Mesh = LineMesh;
      LineSprite.Texture = LineTexture;
      //// Made it look a bit of jelly.  Consider trying again but non-translucent.
      // if (Level.bHighDetailMode) {
        // LineSprite.bMeshEnviroMap = True;
      // }
      // LineSprite.SetPhysics(PHYS_Rotating);
      // LineSprite.Style = STY_Translucent;
      // LineSprite.DrawType = DT_Mesh;
      // LineSprite.RemoteRole = ROLE_SimulatedProxy;
      // LineSprite.NetPriority = 2.6;
      // LineSprite.Texture = Texture'UMenu.Icons.Bg41';
      // LineSprite.LifeSpan = 60;
      // LineSprite.RemoteRole = ROLE_None;
      // LineSprite.bParticles = True;
      // LineSprite.SetPhysics(PHYS_Projectile);
      // LineSprite.SetPhysics(PHYS_Flying);
      // LineSprite.bNetTemporary = True;
      // LineSprite.bGameRelevant = True;
      // LineSprite.bReplicateInstigator = True;
    }
  }
}

simulated function UpdateLineSprite() {
  local float numPoints;

  // This is here because occasionally the first InitLineSprite() was getting called with Instigator=None.  We try again now, in case that variable has been replicated.
  if (LineSprite==None && Role==ROLE_Authority)
    InitLineSprite();
  // Actually we aren't doing the client spawn anyway, we are just replicating the server's GrapplingLines.

  if (bShowLine) {
    // if (bLogging && FRand()<0.01) { Log(Level.TimeSeconds$" "$Self$".UpdateLineSprite() Running with Role="$Role$" pullDest="$pullDest); }
    // LineSprite.Reached = Instigator.Location;
    if (Role != ROLE_Authority) {
      return;
    }
    /*
    if (FRand()<0.05) {
      LineSprite.Destroy();
      InitLineSprite();
      // return;
    }
    */
    /*
    LineSprite.SetLocation(Instigator.Location);
    LineSprite.SetRotation(rotator(pullDest-Instigator.Location));
    // LineSprite.SetVelocity(new location - last location * smth unknown :P );
    numPoints = VSize(pullDest-Instigator.Location)/135.0; if (numPoints<1) numPoints=1;
    numPoints = 16;
    LineSprite.MoveAmount = (pullDest-Instigator.Location)/numPoints;
    // LineSprite.MoveAmount = Vect(0,0,0);
    LineSprite.NumPuffs = numPoints-1;
    // LineSprite.NumPuffs = 0;
    // LineSprite.DrawScale = 0.04*numPoints;
    */
    /*
    LineSprite.SetLocation((Instigator.Location+pullDest)/2);
    LineSprite.SetRotation(rotator(pullDest-Instigator.Location));
    LineSprite.DrawScale = VSize(Instigator.Location-pullDest) / 64.0;
    LineSprite.Velocity = Instigator.Velocity * 0.5;
    */
  }
}

function OnPull(float DeltaTime) {
  CheckFlagDrop();
  // If we have switched weapon away from grapple, then Jump will un-grapple us!
  // This one worked sometimes, but not all the time, so "Mutate GrappleJump" was introduced.
  // For tidiness, this is removed:
  /*
  if (PlayerPawn(Master.Owner)!=None && PlayerPawn(Master.Owner).bPressedJump && GrappleGun(PlayerPawn(Master.Owner).Weapon) == None) {
    Destroy();
  }
  */
}

function CheckFlagDrop() {
  if (bDropFlag && Instigator.PlayerReplicationInfo.HasFlag != None) {
    CTFFlag(Instigator.PlayerReplicationInfo.HasFlag).Drop(vect(0,0,0));
  }
}

function UnFoldLine() {
  local GrapplingLine LastLine;

  if (LineSprite==None)
    return;
  LastLine = LineSprite.ParentLine;
  if (LastLine==None)
    return;

  if (LastLine.ParentLine == None) {
    pullDest = Location;
  } else {
    pullDest = LastLine.ParentLine.Reached;
  }

  // Neither of these feel great, when you jump because you were stuck then SetLocation worked.
  // Realistic but TODO: currently line keeps getting longer when we swing under something then back out =/
  // lineLength = VSize(pullDest - LastLine.Reached) + lineLength;
  // Springy - line springs to current length automatically, and you keep all your swing.
  lineLength = VSize(Instigator.Location - pullDest);

  if (bLogging) { Log(Level.TimeSeconds$" "$Self$".UnFoldLine() Merging "$LineSprite$" into "$LastLine); }

  LineSprite.bStopped = True;
  LineSprite.DrawType = DT_None;
  LineSprite.SetPhysics(PHYS_None);
  // LineSprite.Disable('Tick');
  LineSprite.Destroy(); // Fail as expected :P

  LineSprite = LastLine;

  LastLine.bStopped = False;
  LastLine.SetPhysics(PHYS_Rotating);
  // LastLine.Enable('Tick');
  // LastLine.Reached = vect(0,0,0); // we could use it as a marker like bStopped
  // CONSIDER: If this revival of old GrapplingLine fails, we could just destroy it and spawn a fresh one.
}

/*simulated*/ function DoLineOfSightChecks() {
  local Actor A;
  local Vector NewPivot,NewPivotNear,visualPullDest;
  local Vector ShiftCorner;
  local GrapplingLine LastLine;

  // if (bLogging && LineSprite!=None && VSize(pullDest-LineSprite.NearPivot)>1.0) {
    // Log(Level.TimeSeconds$" "$Self$".DoLineOfSightChecks() Warning! pullDest "$pullDest$" != LS.NearPivot "$LineSprite.NearPivot$" !!");
  // }

  // if (bLogging && FRand()<0.01) { Log(Level.TimeSeconds$" "$Self$".DoLineOfSightChecks() Running with Role="$Role$" LineSprite="$LineSprite); }
  // OK good now got it running on the client too.

  // DONE: for ultra realism, keep a list of points our line has pulled around, and if we swing back to visibility to the previous point, relocate!
  // CONSIDER: a further harder part, is to have the line slip over the corner where it folds, as the player swings below.
  // BUG: we sometimes re-merge the line although we have slipped under a bridge, so it would not actually be possible due to topology.
  if ( bLineOfSight ) {
    if (bLineFolding) {

      // Check if we have swung back, and the line will become one again:
      if (LineSprite != None) {
        LastLine = LineSprite.ParentLine;
        if (LastLine != None
          // But don't merge if we are almost finished
          // && ( lineLength<-50 || lineLength>MinRetract )
        ) {
          // A = Trace(NewPivot,hNormal,LastLine.NearPivot,Instigator.Location,false);
          A = Trace(NewPivot,hNormal,LastLine.NearPivot,Instigator.Location,false);
          if (A == None || A==LastLine) { // A==Self never seems to happen / be needed but w/e
            // But we should also  be able to see LastLine.Reached.
            // TODO: This is better, but it still allows the line to ghost through some thin pipes.
            // A = Trace(NewPivot,hNormal,LastLine.Reached,Instigator.Location,false);
            // if (A == None || A==LastLine) { // This does not work too well :P
              // We can see the grapple again!
              // pullDest = LastLine.NearPivot; // No this must now become LastLine.LastLine.Reached or grapple Location otherwise!
              UnFoldLine();
              if (bLogging) Instigator.ClientMessage("Your grappling line has straightened new length "$lineLength);
            // }
          }
        }
      }

      // Check if the line has swung around a corner:
      // CONSIDER: problems when moving at high velocity - split is not outside the edge, but on one side or other of the corner.
      if (LineSprite!=None /*&& LineSprite.ParentLine!=None*/) {
        visualPullDest = LineSprite.NearPivot;
      } else {
        visualPullDest = pullDest;
      }

      A = Trace(NewPivotNear,hNormal,visualPullDest,Instigator.Location,false); // TODO: Not so nice for far end.  Far side hitpoint should really be our new pull target but near side should be check-line-of-sight target!  We can do that using pullDest and NewPivot.

      // TODO: swap the next two lines to get old behaviour, when lines against flat walls always show fine!
      A = Trace(NewPivot,hNormal,Instigator.Location,visualPullDest,false); // Nice for far end, causes subsequent near end line splitting to fail tho, cos there is a wall in the way!  (or maybe it splits every tick :f )
      // NewPivot = NewPivotNear;

      if (A != None && VSize(NewPivot-pullDest)>5) {
        // Self.DrawType = DT_None;
        // Self.SetLocation(NewPivot);
        // if (pullDest != LineSprite.NearPivot) {
          // BroadcastMessage("Warning! pullDest "$pullDest$" != NearPivot "$LineSprite.NearPivot$"");
        // }
        // BUG: for some reason, I am not hearing these sounds!  Now trying SLOT_Interface instead of SLOT_None.
        // PlaySound(HitSound,SLOT_Interface,10.0);
        // Master.PlaySound(HitSound,SLOT_Interface,10.0);
        // No joy.
        // Leave the old line part hanging, and create a new part:

        // We shift the corner out a bit.
        // ShiftCorner = -Normal(Instigator.Velocity)*8.0;
        ShiftCorner = -Instigator.Velocity*0.03; // DeltaTime;
        NewPivot += ShiftCorner;
        NewPivotNear += ShiftCorner;
        // TODO: Keep shifting this corner until it sits outside the solid world (traces hit nothing).

        if (LineSprite != None) {
          // LineSprite.NearPivot = pullDest;
          LineSprite.Reached = NewPivot;
          LineSprite.ReachedRender = NewPivotNear;
          LineSprite.bStopped = True;
          LineSprite.SetPhysics(PHYS_None);
          LineSprite.Velocity = vect(0,0,0);
          LastLine = LineSprite;
          LineSprite = None;
          pullDest = NewPivot;
          InitLineSprite();

          if (LineSprite == None) {
            // Oh no! Sometimes we do get "failed to spawn child GrapplingLine!", often when the wall is quite close, and the child line will not spawn because it is inside the wall?
            // This may happen less now that I've set GrapplingLine.bCollideWorld=False and Physics=PHYS_Projectile.
            // Re-enable the line we just failed to split:
            LineSprite = LastLine;
            if (LineSprite.ParentLine!=None)
              pullDest = LineSprite.ParentLine.Reached;
            else
              pullDest = Location;
            LineSprite.bStopped = False;
            LineSprite.SetPhysics(PHYS_Rotating);
            if (bLogging && Role==ROLE_Authority) { Log(Level.TimeSeconds$" "$Self$".DoLineOfSightChecks() FAILED to spawn GrapplingLine to split "$LastLine); }
            if (bLogging) Instigator.ClientMessage("Failed split!");
          } else {
            LineSprite.ParentLine = LastLine;
            LineSprite.Depth = LastLine.Depth+1;
            LineSprite.NearPivot = NewPivotNear;
            if (bLogging && Role==ROLE_Authority) { Log(Level.TimeSeconds$" "$Self$".DoLineOfSightChecks() Split "$LastLine$" to "$LineSprite); }
            lineLength = VSize(Instigator.Location - pullDest);
            if (bLogging) Instigator.ClientMessage("Your grappling line was caught on a corner new length "$lineLength);
          }

          if (LineSprite.Depth>10) {
            // Too many sub-lines created, this player is gonna break something.  Let's just break his line instead.
            Destroy();
          }

        }
        // return; // Don't return, we gotta render this new style!
      }

      TryToSlip();

    } else {
      if (!Instigator.LineOfSightTo(self)) {
        Destroy();
      }
    }
  }

}

function TryToSlip() {
  // TODO: sometimes gets caught inside solid bits with daft results when outcome could have been straightforward
  // TODO: when we do slip, this usually involves the player falling lower, even though overall lineLength has not increased, it appears to.  This should be prevented!
  //       I don't know what is causing this.  But UnFoldLine() at least recalculates lineLength from current positions.
  local GrapplingLine LastLine;
  local Vector perp,inward,newMiddle;
  local int side;
  if (LineSprite == None || LineSprite.ParentLine == None)
    return;
  LastLine = LineSprite.ParentLine;
  // We have 2 lines going from Instigator.Location to LineSprite.NearPivot/Pivot to ParentLine.NearPivot.
  // If we can rotate the triangle left or right, and then pull the centre point inwards, without breaking visibility, we should!
  perp = Normal( (LastLine.NearPivot - LineSprite.NearPivot) Cross (Instigator.Location - LineSprite.NearPivot) );
  // NO: this inward causes the point to move up/down the line, if the triangle is not symmetrical.
  // inward = Normal( (Instigator.Location + LastLine.NearPivot)/2 - LineSprite.NearPivot );
  /*
  inward = Normal( (Instigator.Location - LastLine.NearPivot) Cross perp ); // This gets the right direction 90% of the time.  :P
  */
  inward = (Instigator.Location - LineSprite.NearPivot);
  inward = inward - (inward Dot Normal(Instigator.Location-LastLine.NearPivot))*Normal(Instigator.Location-LastLine.NearPivot);
  inward = Normal(inward);
  // TODO: This favours one side over the over.
  for (side=-1;side<=1;side+=2) {
    newMiddle = LineSprite.NearPivot + side*perp*4.0;
    newMiddle += inward * 2.0;
    // Now move it inward
    // Check: can we see from oldmiddle to new middle, and from both ends to it?
    if (CanTrace(LineSprite.NearPivot,newMiddle) && CanTrace(Instigator.Location,newMiddle) && CanTrace(newMiddle,LastLine.NearPivot)) {
      LineSprite.NearPivot = newMiddle;
      LastLine.Reached = newMiddle;
      LastLine.ReachedRender = newMiddle;
      pullDest = newMiddle; // Seems to be needed if the hook is in flight during fold, but not otherwise.
    }
    // We continue to do the other side.  If that side works too, we will have moved inwards, which is good!
  }
}

function bool CanTrace(Vector start, Vector end) {
  local Actor A;
  local Vector HitPos,HitNormal;
  A = Trace(HitPos,HitNormal,end,start,false);
  return (A==None);
}

state() PullTowardStatic {

  simulated function BeginState () {
    if (!bSwingPhysics) {
      Instigator.Velocity = Normal(pullDest - Instigator.Location) * GrappleSpeed;
    }
    Instigator.SetPhysics(PHYS_Falling);
  }

  simulated function Tick (float DeltaTime) {

    if (Instigator==None || Master==None) {
      if (Role == ROLE_Authority) {
        if (bLogging && FRand()<0.1) { Log(Level.TimeSeconds$" "$Self$".PullTowardStatic.Tick() Server can't do motion because Instigator="$Instigator$" or Master="$Master$" btw InstigatorRep="$InstigatorRep); }
      } else {
        // We are client side.  Don't make a fuss.
        if (bLogging && FRand()<0.1) { Log(Level.TimeSeconds$" "$Self$".PullTowardStatic.Tick() Client can't do motion because Instigator="$Instigator$" or Master="$Master$" btw InstigatorRep="$InstigatorRep); }
      }
      return; // Proceeding will just throw Accessed Nones.
      // CONSIDER: If this logs that we have InstigatorRep but not Instigator, then we should use former!
    }

    OnPull(DeltaTime);

    DoPhysics(DeltaTime);

    // if (!isStuck)
      DoLineOfSightChecks();

    UpdateLineSprite();

  }

  simulated function DoPhysics(float DeltaTime) { // Returns False if pawn is stuck.
    local float currentLength,outwardPull,linePull,power;
    local float previousSpeed;
    local Vector Inward;
    local float WindInSpeed;
    local float currentOutVel,targetInVel;
    local bool doInwardPull; // aka CancelOutwardPull
    local bool bSingleLine; // bSingleLine actually means, "Is this the final line that attaches to the hook, or is it a secondary line bent around a corner?".
                            // We often use it to decide whether the short lineLength really is relevant, as opposed to being short only to the next bend.
                            // But really in those cases we should use totalLineLength.

    // isStuck = False;

    currentLength = VSize(Instigator.Location - pullDest);

    if ( currentLength <= MinRetract ) {
        AmbientSound = None;
        Master.AmbientSound = None;
    }

    // This is used to decide whether to stop at MinRetract.
    // If we are below a fold, we should continue to winch towards pullDest even below MinRetract.
    bSingleLine = !(LineSprite!=None && LineSprite.ParentLine!=None);

    if (!bSwingPhysics) {

      //// Original grapple physics
      if ( currentLength <= MinRetract && bSingleLine ) {
        // When we reach destination, we just stop
        Instigator.SetPhysics(PHYS_None);
        Instigator.AddVelocity(Instigator.Velocity * -1);
      } else {
        // No gravity or swinging
        Instigator.Velocity = Normal(pullDest - Instigator.Location) * GrappleSpeed;
      }

    }

    //// Swing physics

    // Dampening when we reach the top:
    if (currentLength <= 3*MinRetract) {
      Instigator.Velocity = Instigator.Velocity*0.997;
    } else {
      // Instigator.Velocity = Instigator.Velocity*0.999;
    }

    // if (/*currentLength > 4*MinRetract &&*/ Instigator.Velocity.Z<0) {
      // Instigator.Velocity.Z *= 0.99;
    // }

    Inward = Normal(pullDest-Instigator.Location);

    doInwardPull = True;

    //// We want the line to retract 600um/second if we are going straight up, or 2600 if we are going horizontally.
    // if (Inward.Z>0) {
      WindInSpeed = VerticalGrappleSpeed*Abs(Inward.Z) + GrappleSpeed*(1.0-Abs(Inward.Z)); // This should not really be a linear relationship
    // } else {
      // WindInSpeed = GrappleSpeed;
    // }

    //// Testing replication of this option:
    // if (bLogging && FRand()<0.01) { Log(Level.TimeSeconds$" "$Self$".PullTowardStatic.Tick() bLinePhysics="$bLinePhysics); }

    // Deal with grapple pull:
    if (bLinePhysics) {

      //// We know the length of the line!

      currentOutVel = -Instigator.Velocity Dot Inward;

      // Really we should have and change states for line movement: 'Swinging' 'Winching' and 'Releasing'
      if (bCrouchReleases && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bDuck!=0 && (PlayerPawn(Instigator).bFire==0 || !bPrimaryWinch)) {
        if (currentLength>lineLength) {
          Master.AmbientSound = ReleaseSound;
          AmbientSound = ReleaseSound;
        } else {
          Master.AmbientSound = None;
          AmbientSound = None;
        }
        doInwardPull = False;
        if (bUnrealUnwind) {
          //// Release the line at constant medium speed.  This is easy to control (linear with time pressed, as opposed to exponential with gravity).
          //// Nah this sucked - disabled.
          //// We could still go for a medium model - starting with gravity but max wind out speed.  Or a slowdown on release.
          // lineLength = lineLength + 600*DeltaTime;
          lineLength = currentLength;
          //// No we don't want to push the player out with the line.
          // TryMoveTo(Instigator,pullDest - lineLength*Inward);
          //// We let them fall with gravity.
          // But we max their velocity to that of the line, if they have reached beyond its limit.
          // (CONSIDER: We should really max it to something slightly smaller, to restabilise.)
          if (currentLength>lineLength) {
            if (currentOutVel>600)
              Instigator.AddVelocity(Inward*currentOutVel - Inward*600);
          }
          doInwardPull = False;
        } else {
          // Let player fall with gravity, line unwinds to match.
          // This is harder to control, but can be commando-like, to go really fast down the side of Face, then stop!
          lineLength = currentLength;
          // lineLength = lineLength + 2 * 0.3 * WindInSpeed*DeltaTime;
          // Force correct length:
          // Instigator.SetLocation( pullDest + lineLength*-Inward );
          // Instigator.SetLocation( pullDest + Instigator.HeadRegion.Zone.ZoneGravity * DeltaTime * Vect(0,0,1) );
          // Undo the "keep the same length" from earlier:
          // Don't wind out faster than 1400.
          // if (VSize(Instigator.Velocity) > 1400) {
            // Instigator.Velocity = 1400 * Normal(Instigator.Velocity);
          // }
          if (currentOutVel>1200)
            Instigator.AddVelocity(Inward*currentOutVel - Inward*1200);
          doInwardPull = False;
          // TODO: This should really affect you only in the direction of the line; we could turn lineLength back on!
          //       Also the code is duplicated below, should be refactored.
          // This version, relative to grappling hook, was supposed to be clever, but caused trouble. :P
          // if (VSize(Instigator.Velocity - Velocity) > 1400) {
          // Instigator.Velocity = 1400 * Normal(Instigator.Velocity - Velocity) + Velocity;
          // }
        }
      } else if (
        (lineLength<=MinRetract && bSingleLine)
        || (bPrimaryWinch && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bFire==0) // Fire to winch
        || (!bPrimaryWinch && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bFire!=0) // Fire to pause winching
        || (bPrimaryWinch && bCrouchReleases && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bFire!=0 && PlayerPawn(Instigator).bDuck!=0)
      ) { // TODO: right now this applies even if weapon is switched, and we primary fire with that :f
        Master.AmbientSound = None;
        AmbientSound = None;
        if (lineLength>MinRetract && currentOutVel>0) { // && currentLength>lineLength
          previousSpeed = VSize(Instigator.Velocity);
          Instigator.AddVelocity(currentOutVel*Inward);
          // We have just stolen some of the player's momentum.
          // He might have saved that up, or just generated it from air control.
          // We should give it back to him.  Well, some of it.
          // // Instigator.AddVelocity(0.4*currentOutVel*Normal(Instigator.Velocity)); // BAD
          // Instigator.Velocity = previousSpeed * Normal(Instigator.Velocity);
          // TODO: Some of the other cases may want this too.
          // Bah I don't believe it's correct.  The line can only act along its axis.  Velocity lost on the outward axis is just lost!
        }
      } else {
        // OK so we are winching.
        // 0.3 is my estimate conversion from acceleration to velocity
        targetInVel = 0.3 * WindInSpeed;
        if (isStuck) {
          targetInVel = targetInVel * StuckSlowdown;
        }
        if (bSingleLine && lineLength<MinRetract*4.0) { // If they are close the the top, we reduce the pull a bit.
          // lineLength is somewhere between MinRetract and MinRetract*2.0
          targetInVel = targetInVel * (lineLength-MinRetract)/(3.0*MinRetract);
        }
        if (!bSingleLine && lineLength<MinRetract*4.0) { // Only happens when !bSingleLine
          // This tones down the extreme new pull when your line catches around a corner.
          targetInVel = targetInVel * (0.1+0.9*lineLength/MinRetract/4.0);
        }
        lineLength = lineLength - targetInVel*DeltaTime;
        if (lineLength < 0)
          lineLength = 0;
        if (lineLength>=currentLength) { // It could be that the line was slack, and we have only reeled it in, not pulling ourself.
          doInwardPull = False;
        } else {
          if (-currentOutVel<targetInVel) {
            Instigator.AddVelocity(currentOutVel*Inward + targetInVel*Inward);
          }
        }
        Master.AmbientSound = PullSound;
        AmbientSound = PullSound;
        if (bSingleLine && lineLength<MinRetract*1.1) {
          Master.AmbientSound = None;
          AmbientSound = None;
        }
      }
      if (lineLength<MinRetract && bSingleLine) lineLength=MinRetract;
      if (currentLength > lineLength) {
        /// Player is further from pullDest than he should be, as if the line had elongated!  This is not allowed!
        /// We force the player to the correct distance.

        // Instigator.SetLocation( pullDest + lineLength*-Inward );
        //// Can cause random telefrags.  When we get stuck, ev_ntually pulls us through the wall!
        //// This was good, it "guaranteed" getting un-stuck.

        // Instigator.MoveSmooth( (pullDest + lineLength*-Inward) - Instigator.Location );  // 
        //// Can cause crater against wall when stuck!

        // Instigator.Move( (pullDest + lineLength*-Inward) - Instigator.Location );
        //// When stuck we just sit static.

        TryMoveTo(Instigator,pullDest - lineLength*Inward);

        /*
        // We should have no outward velocity.  If we do, it will be cancelled out by the force of the line, in the Inward direction.
        // if (currentOutVel>0) {
          // Instigator.Velocity = Instigator.Velocity + currentOutVel*Inward;
        // }
        */

        /*
        //// This was another naff attempt at using velocity instead of actually setting the lineLength.
        //// I was trying it again, because I wanted to set some sort of inward velocity, so that laggy clients would still see a smooth movement.
        // We have pulled them inwards by (currentLength-lineLength) in DeltaTime.
        // Let us set the inward component of our velocity to match that, if it is less.
        targetInVel = (currentLength-lineLength)/DeltaTime;
        if (targetInVel>WindInSpeed) // Cap it at something large, so we don't bounce too much, even if we have fallen really fast below the lineLength.
          targetInVel = WindInSpeed;
        if (-currentOutVel < targetInVel) {
          Instigator.Velocity = Instigator.Velocity + Inward*currentOutVel*0.5 + Inward*targetInVel*0.5;
          if (bLogging) { Instigator.ClientMessage(">> "$Int(targetInVel)); }
        }
        */

        // doInwardPull = False; // Velocity done above in each case.  NOT! THIS IS BAD!

        //// Add random velocity when stuck.

        // If we are stuck, the line keeps getting shorter.
        // Often this is not a problem because as soon as we become unstuck, the line unfolds and lineLength is updated from the new pull dest.
        // But in case that doesn't happen, let's keep lineLength under control:
        // if (lineLength < currentLength - 250)
          // lineLength = currentLength - 250;
        // TODO CONSIDER: Maybe this should be removed if we go back to the SetLocation() method.

      } else if (currentLength < lineLength /*&& currentLength>=MinRetract*/) {
        // Line is shorter than it should be.
        // Undo the inward pull effect:
        doInwardPull = False;
        // Alternatively, shorten the line to the new length!
        // lineLength = currentLength;
      }

   } else {

      //// Try to deal with swing without knowing the line length.
      //// We assume the line length is whatever distance we are from the hook.

      if ( (bPrimaryWinch && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bFire==0) ||
           (bPrimaryWinch && bCrouchReleases && PlayerPawn(Instigator)!=None &&
            PlayerPawn(Instigator).bFire!=0 && PlayerPawn(Instigator).bDuck!=0)
      ) {
        power = 0.0;
        Master.AmbientSound = None;
        AmbientSound = None;
      } else {
        power = 1.0;
        if (bExtraPower) {
          power += 1.0 + 1.5 * FMin(1.0, currentLength / 1024.0 );
        }
        Master.AmbientSound = PullSound;
        AmbientSound = PullSound;
      }
      if (bCrouchReleases) {
        if (PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bDuck!=0 && PlayerPawn(Instigator).bFire==0) {
           // We make no pull with the line at all, gravity affects us and we get our new line length.
           power = 0.0;
           if (bUnrealUnwind) {
             // Push out:
             power = -0.4;
           }
           // Instigator.AddVelocity( Instigator.HeadRegion.Zone.ZoneGravity * DeltaTime * -Inward );
           // Instigator.AddVelocity( Instigator.HeadRegion.Zone.ZoneGravity * DeltaTime * Vect(0,0,-1) );
           doInwardPull = False;
           // power = -1.0;
           Master.AmbientSound = ReleaseSound;
           AmbientSound = ReleaseSound;
           // Don't wind out faster than 1400.
           if (VSize(Instigator.Velocity) > 1400) {
             Instigator.Velocity = 1400 * Normal(Instigator.Velocity);
           }
        }
      }
      if (currentLength <= MinRetract && bSingleLine) {
        power = 0.0;
        Master.AmbientSound = None;
        AmbientSound = None;
        doInwardPull = False;
      }
      if (isStuck && power>0)
        power = power*StuckSlowdown;
      linePull = power*WindInSpeed*1.5; // I don't know what changed, but 600 was almost too weak to pull me up!

      // Instigator.Velocity = Instigator.Velocity + linePull*Inward*DeltaTime;
      Instigator.AddVelocity(linePull*Inward*DeltaTime);

    }

    if (doInwardPull) {
      // Deal with any outward velocity (against the line):
      outwardPull = Instigator.Velocity Dot Normal(Instigator.Location-pullDest); // Isn't that Inward?
      if (outwardPull<0 || (currentLength <= MinRetract && bSingleLine)) outwardPull=0;
      // if (outwardPull<1.0) outwardPull=1.0*outwardPull*outwardPull; // Smooth the last inch
      // This makes the line weak and stretchy:
      // Instigator.Velocity = Instigator.Velocity + Inward*DeltaTime;
      // This completely cancels outward momentum - the line length should not increase!
      // Instigator.AddVelocity( 2.0 * outwardPull * Inward ); // equilibrium (line stretches very very slowly)
      // Cancel the outward velocity - it never really should have happened.
      // Also changes global velocity by pulling it towards the line, not only countering gravity.
      Instigator.AddVelocity( 1.0 * outwardPull * Inward ); // keep the line the same length.  The 0.1 prev.nts slow sinking
      // Instigator.Velocity = Instigator.Velocity + 1.0*outwardPull*Inward; // keep the line the same length.  The 0.1 prev.nts slow sinking
      // Instigator.Velocity = Instigator.Velocity + 1.0*outwardPull*Normal(Instigator.Velocity); // Turn the lost momentum into forward momentum!  Stupid dangerous non-Newtonian nonsense!
      // DONE: I am adding this here, then in a few places below, removing it if I decide it wasn't wanted.
      //       Would be better to pass along a boolean which decides at the end whether or not to apply this.
      //       This might allow us to actually walk and jump normally if our line has gone slack.
    }

    // TODO: We may have reduced the line length.  If we are below a fold, and have now reduced it below 0, equations will stop working, so we
    // need to do something.  Probably best to just un-catch the line from the corner and move up to swinging on the higher pivot.
    // But when lineLength is calculated from currentLength (distance from player to pivot), we will hardly get a chance to catch this, especially if the player cannot quite reach the pivot.
    // if (lineLength<0 && !bSingleLine) {
    /*
    if (lineLength<50 && !bSingleLine) {
      UnFoldLine();
      if (bLogging) Instigator.ClientMessage("Your grappling line was ARTIFICIALLY straightened!");
    }
    */

  }

  simulated function ProcessTouch (Actor Other, Vector HitLocation) {
    Instigator.AmbientSound = None;
    AmbientSound = None;
    Destroy();
  }

}

// TESTING:
// What we really need to do is to get the triangle that is Player - NearPivot - NextPivot
// and move NearPivot *out* a bit.

// TODO: should this be pre-empted / simulated on the client?
function TryMoveTo(Actor a, Vector targetLoc) { // Removed simulated I don't know what it means when there is a Rand() involved.
  local float offness;
  local Vector NextPivot;
  // if (a.MoveSmooth(targetLoc - a.Location)) // Sucks, warpish and ugly when stuck!  Also danger of leaving a crater.  :P
  if (a.Move(targetLoc - a.Location)) {
    isStuck = False;
    return;
  }

  // Player is stuck!

  // Attempted solutions to getting un-stuck:

  // TODO BEST: refuse to winch (allow unwinch=slack), stop velocity, cause tiny damage~vel
  // TODO: temporarily expand player's collision radius and height to push him outward until his line can unfold.

  // Best solution so far (better than staying stuck?):
  // if (lineLength<MinRetract) // We are close to winding up to the next line part.  Assumption (bad?): we only get stuck at these corners.  Yes bad assumption - sometimes the line merges through line-of-sight but we are still stuck.
  if (bLogging && PlayerPawn(a)!=None && FRand()<0.1) { PlayerPawn(a).ClientMessage("You are stuck trying "$Int(VSize(targetLoc-a.Location))); }
  // if (FRand()<0.2) // don't always do it (mid-air collisions won't guarantee telefrag :P )  Mmm not good sometimes caused large jumps due to waiting.
    // if (bLogging && FRand()<0.1) { BroadcastMessage(a.getHumanName()$" is doing dangerous movement "$Int(VSize(targetLoc-a.Location))); }
    // a.SetLocation(targetLoc);
    // ATM turning this off does all kinds of nasty things, just swing around Face a bit to see.  Until they are fixed, we need this on for production.
    // if (bLogging && FRand()<0.1) { BroadcastMessage(a.getHumanName()$" is AVOIDING doing dangerous movement "$Int(VSize(targetLoc-a.Location))); }
  // TODO: If we are still getting mid-air telefrags, then do a trace on this movement (starting from targetLoc?), and only force it if there is a wall in the way, not a person.
  // TODO: Play sound!
  // The problem is - if we are stuck trying to pull through a wall, I actually want to do the SetLocation() asap.
  // But if we are stuck trying to move through another player, I'm happy to stop moving and wait for him to move out of the way.

  // Neither of the following attempts to un-stick the player made things better.
  /*
  offness = VSize(targetLoc - a.Location);

  if (LineSprite!=None && LineSprite.ParentLine!=None
    // Will not attempt push if angles are close
    && (Normal(LineSprite.ParentLine.NearPivot - pullDest) Dot Normal(pullDest - a.Location) < 0.8)
  ) {
    // Push out the pivot a bit:
    // BUG: sometimes this is pushing it IN and that is bad!
    //       That happens when it merges and then re-breaks at <MinRetract.
    NextPivot = LineSprite.ParentLine.NearPivot;
    // pullDest += Normal( (pullDest-a.Location) + (pullDest - NextPivot) ) * 5.0;
    pullDest += ( Normal(pullDest-a.Location) + Normal(pullDest-NextPivot) ) * 5.0; // more square
    LineSprite.NearPivot = pullDest; // May update sprite!
    PlayerPawn(a).ClientMessage("Moved pivot by "$ VSize(LineSprite.ParentLine.Reached-pullDest) $" lineLength="$lineLength);
    LineSprite.ParentLine.Reached = pullDest; // May update sprite!
  } else if (offness > 10.0 && FRand()<0.25) {
    // Bounce the player around a bit:
    // Cap the velocity we will add
    if (offness > 200)
      offness = 200;
    offness *= 2;
    a.Velocity += 1.0 * offness * Normal(VRand());
    PlayerPawn(a).ClientMessage("You are stuck "$ offness $" ("$ VSize(targetLoc - a.Location) $") lineLength="$lineLength);
    // TODO: play sound
  }
  */

  isStuck = True;
}

state() PullTowardDynamic {
  // ignores  Tick;

  // CONSIDER TODO: I did not bother implementing bPrimaryWinch and bCrouchReleases for PullTowardDynamic.

  simulated function BeginState () {
    SetPhysics(PHYS_Flying);
    Velocity = vect(0,0,0);
    Instigator.SetPhysics(PHYS_Flying);
  }

  simulated function Tick(float DeltaTime) {
    local Rotator rot;

    if (Thing==None)
      Self.Destroy();

    pullDest = Thing.Location;
    //// TODO: This is the wrong thing to do - only the top line moves with the Thing, but we may have a LineSprite below that one.
    ////       What we should really do is keep a copy of the tail LineSprite as well as the head.  If Thing moves, it will pull or release the lines, moving the player.
    if (LineSprite != None)
      LineSprite.NearPivot = Thing.Location; // TODO: This ain't gonna work - folding linesprite on Dynamic target is gonna be messy!

    if (Instigator==None || Master==None) {
      if (Role == ROLE_Authority) {
        if (bLogging) { Log(Level.TimeSeconds$" "$Self$".PullTowardDynamic.Tick() Server can't do motion because Instigator="$Instigator$" or Master="$Master$" btw InstigatorRep="$InstigatorRep); }
      } else {
        // We are client side.  Don't make a fuss.
        if (bLogging && FRand()<0.1) { Log(Level.TimeSeconds$" "$Self$".PullTowardDynamic.Tick() Client can't do motion because Instigator="$Instigator$" or Master="$Master$" btw InstigatorRep="$InstigatorRep); }
      }
      return; // Proceeding will just throw Accessed Nones.
      // CONSIDER: If this logs that we have InstigatorRep but not Instigator, then we should use former!
    }

    // Cause HitDamage, if not friendly:
    if ( FRand()<DeltaTime*2 // Avg twice a second
      && !(Level.Game.IsA('TeamGamePlus')
           && bThingPawn
           && Pawn(Thing).PlayerReplicationInfo!=None && Instigator.PlayerReplicationInfo!=None
           && Pawn(Thing).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team)
    ) {

      //               Avg half HitDamage
      Thing.TakeDamage(0.25*HitDamage+0.5*FRand()*HitDamage,Instigator,(Thing.Location+Location)/2,vect(0,0,0),'');

      // Allow victim to shake the hook off:
      if (VSize(Thing.Velocity) > 0.9*VSize(Instigator.Velocity) && FRand()<0.5) {
        // Thing managed to shake the hook off (special move = moving faster than opponent when check comes around)
        Self.Destroy();
        // TODO: play sound
        // Grappler's Velocity was previously either Thing.Velocity or WindInSpeed, but now it's given more freedom.
        return;
      }

    }

    // Check for problems.
    if (VSize(Thing.Location-Location)>200.0) {
      // Somehow the Thing got far from our grapple.
      // Maybe it took a teleporter, or respawned.  We should ungrapple.
      // (Our previous pullDest may have be pointing right at the teleporter Thing took.)
      if (bLogging) Instigator.ClientMessage("Your target "$Thing.getHumanName()$" got too far away - maybe it took a teleporter.");
      Destroy(); // TODO: Does not work!
    }
    // Update Grapple's movement:
    // TODO: Everyone can see the Grapple.  Therefore this should be done on the server, not the client!
    if (VSize(Thing.Location-Location)>10.0) {
      // Self.SetLocation( Location*0.5 + Thing.Location*0.5);
      Self.Move( (Location*0.5 + Thing.Location*0.5) - Location );
      // TryMoveTo(Self, Location*0.5 + Thing.Location*0.5 );
      Self.Velocity = Thing.Velocity;
      // TODO: gonna be jerky - better to use FChop?
      // Turn the hook as we follow:
      // rot = rotator(Normal(Thing.Location-Location));
      rot = rotator(Normal(Thing.Location-Instigator.Location));
      rot.Yaw = rot.Yaw + 32768;
      rot.Pitch = -rot.Pitch;
      SetRotation(rot);
    }

    // We could dampen Thing's movement.  He is carrying the mass of Instigator now!

    if (bCrouchReleases && PlayerPawn(Instigator)!=None && PlayerPawn(Instigator).bDuck!=0 && PlayerPawn(Instigator).bFire==0) {
      // Player is pressing release.  Do not affect his velocity with the line.
      Master.AmbientSound = ReleaseSound;
      AmbientSound = ReleaseSound;
      // TODO!
      // Remove outward velocity of player in direction of line.  Set that outward velocity to 600 or something.
      // ...

    } else {

       // Update Grappler's velocity:
       if (VSize(Self.Location - Instigator.Location) > MinRetract) {
         if (isStuck)
           Instigator.Velocity = Normal(Self.Location - Instigator.Location) * 0.3 * StuckSlowdown*GrappleSpeed;
         else
           Instigator.Velocity = Normal(Self.Location - Instigator.Location) * 0.3 * GrappleSpeed;
         Master.AmbientSound = PullSound;
         AmbientSound = PullSound;
       } else {
         // Instigator.Velocity = Thing.Velocity;  // Let our player free for a moment!
         //// Maybe better not to have sound flickering on and off
         Master.AmbientSound = None;
         AmbientSound = None;
       }

   }

    OnPull(DeltaTime);
    UpdateLineSprite();

  }

  simulated function ProcessTouch (Actor Other, Vector HitLocation) {
    Instigator.AmbientSound = None;
    AmbientSound = None;
    Destroy();
  }

}

defaultproperties {
    MyDamageType=eviscerated
    LifeSpan=60.00
    // bUnlit=True
    bUnlit=False
    bBlockActors=True
    bBlockPlayers=True
    DrawScale=1.25
    CollisionRadius=0.1
    CollisionHeight=0.2
    bNetTemporary=False
    NetPriority=2.6
    RemoteRole=ROLE_SimulatedProxy
    bMeshEnviroMap=True
    Texture=Texture'UMenu.Icons.Bg41'
    Mesh=Mesh'UnrealShare.GrenadeM'
    Physics=PHYS_Projectile // Makes it land properly in corners, hit walls well.  Sometimes we set it to PHYS_Falling.
    ThrowAngle=0
    // Physics=PHYS_Falling
    // ThrowAngle=15
    // ThrowAngle=1
    //// With PHYS_Falling I had trouble getting the hook to attach to some of the corners in Bleak

    //// I quite like this medium/some-slowness speed:
    // Speed=3000.00
    // MaxSpeed=3000.00
    //// This is more like ND's speed.
    Speed=3500.00
    MaxSpeed=3500.00
    // GrappleSpeed=900 // 600 is quite fast for old Expert100, but quite sober for GrapplingHook.  1600 is swift, and a little faster than walking
    // 900 is elegant vertical but too slow horizontally - useless compared to Translocator.  We need ~2800 horizontal, to compare to Translocator, and therefore vertical should also be higher, otherwise we will be discouraging swinging!
    // GrappleSpeed=0
    HitDamage=20.00 // Not very strong, but you can switch weapon and hit them with something else too!
    bDoAttachPawn=True

    // kX:
    GrappleSpeed=2550
    VerticalGrappleSpeed=900
    bSwingPhysics=True
    bLinePhysics=True // This deals with grapple pull in terms of line length.
    bLineOfSight=True
    bLineFolding=True
    MinRetract=125

    // NOTE: You cannot use /* */ to comment these out!

    // ND:
    // GrappleSpeed=610
    // VerticalGrappleSpeed=300
    // bSwingPhysics=False
    // bLinePhysics=False
    // bLineOfSight=True  // This safety check is needed to detach the hook if we lose line-of-sight to our destination grapple.
    // bLineFolding=False // This works BADLY if the swing and line physics are off.
    // MinRetract=50

    bShowLine=True
    // bPrimaryWinch=False // Grapple only winds in while player is holding primary fire.  When I changed the config on the server from default True to config False, everything seemed to replicate to the client except sounds! // In other words, if you set it to true in the defaultproperties, then false on the server, it won't all work.
    // bPrimaryWinch=True // TODO Warning: This may pr_vent it from being changed on the server (or being replicated to the client if it is).
    bCrouchReleases=True // Grapple line unwinds while player is crouching
    bUnrealUnwind=False // Less realistic but friendly to use line release.  TODO: Unfinished for PullTowardDynamic.
    bDropFlag=True
    bExtraPower=False
    // HitSound=sound'UnrealI.GasBag.hit1g'
    // HitSound=sound'KrrChink'
    HitSound=sound'hit1g'
    // PullSound=sound'SoftPull'
    PullSound=sound'Pull'
    ReleaseSound=sound'ObjectPush'
    RetractSound=sound'Slurp'
    // LineMesh=mesh'botpack.shockbm'
    // LineMesh=mesh'botpack.plasmaM'
    LineMesh=Mesh'Botpack.bolt1'
    // LineMesh=mesh'Botpack.TracerM'
    LineTexture=Texture'UMenu.Icons.Bg41'
    // LineTexture=Texture'Botpack.ammocount'
    // bLogging=False // FIXED: Since GrapplingLine accesses this as a default, sometimes this setting is more relevant than the server setting.  OK now we have one config var per class.
    // Hey would we have got the config default if we hadn't set a default here? :o
    StuckSlowdown=0.5
}

// It's true what he said.  If the defaultproperties has bLinePhysics=True, even if the server sets it to False and tries to replicate it, the client will see bLinePhysics=True.
