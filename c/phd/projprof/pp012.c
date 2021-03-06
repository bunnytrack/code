// Projection profiler, with vanishing points
// Measures: entropy, square sum, derivative square sum,
// variance
// Proportional mode optional

// Also finds vertical projection profile, and recovers
// fronto-parallel image

// The slowest part is due to the neccessary comparison
// of every +ve pixel position and every vanishing point
// to get the angle between them, to generate the
// projection profiles.

/* All my source code is freely distributable under the GNU public licence.
   I would be delighted to hear if have made use of this code.
   If you make money with this code, please give me some!
   If you find this code useful, or have any queries, please feel free to
   contact me: pclark@cs.bris.ac.uk / joeyclark@usa.net
   Paul "Joey" Clark, hacking for humanity, Feb 99
   www.cs.bris.ac.uk/~pclark / www.changetheworld.org.uk */

// #define USINGJFONT
// No printing of file input/output
// #define QUIET

// Fix PP resolution relative to input image
// or allow user to specify?
#define FIXPPRES

// Do we run in proportional mode or not?
// Proportional mode uses floats so is slower
// but produces smoother projection profiles by
// distributing accumulations evenly over accumulators
 #define PROPORTIONAL

// PPunit determines whether we should use floats for
// accumulator, and for accumulator's index
#ifdef PROPORTIONAL
  #define PPunit float
#else
  #define PPunit int
#endif

#include <joeylib.c>

int outcount=0;

int showbadx=-1;
int showbady=-1;

float (*measure)(Map1d<PPunit>);

float measureentropy(Map1d<PPunit> m) {
  return m.entropy();
}
float measurederiv(Map1d<PPunit> m) {
  return -m.totalderiv();
}
float measuresquare(Map1d<PPunit> m) {
  return -m.totalsquare();
}
float measurevariance(Map1d<PPunit> m) {
  return -m.variance();
}

// A vanishing point with its projection profile
// which will be accumulated using the add() function
class VP {
public:
  V2d pos;
  Map1d<PPunit> pp;
  float left,right; // relative to vector to centre
  V2d tocentre;
  float realleft; // absolute
  PPunit q;

  // Set up the window of angles over which the VP can
  // see the text region.
  // Set up optimization variables to make the add()
  // function efficient.
  VP(V2d p,int res,int width,V2d imgcen) {
    pos=p;
    tocentre=(imgcen-p).norm();
    pp=Map1d<PPunit>(res); // => pp.width==res
    left=V2d::angbetween(imgcen+width*tocentre.perp()-pos,tocentre);
    right=V2d::angbetween(imgcen-width*tocentre.perp()-pos,tocentre);
    if (right<left)
      right=right+2.0*pi;
    q=(float)res/(right-left);
    realleft=modtwopi(tocentre.angle()+left);
//    printf("VP %s l=%.2f r=%.2f\n",pos.toString(),left,right);
  }

  // Add to the projection profile a pixel at point v
  void add(V2d v) { // accepts a +- vector relative to centre of image, with mag<=width above
//    printf("%s %s\n",v.toString(),pos.toString());
    // Fastest method
    float ang=modtwopi((v-pos).angle()-realleft);
    PPunit i=ang*q;
    // Slower method
    /* float ang=V2d::angbetween(v-pos,tocentre);
    if (ang<left)
      ang=ang+2.0*pi;
    PPunit i=(ang-left)*q; */
    // Even slower method
    /* float ang=V2d::angbetween(v-pos,tocentre);
    PPunit i=modtwopi(ang-left)*(float)pp.width/(right-left); */
    #ifdef PROPORTIONAL
    if (i>=0 && i<pp.width-1)
        pp.incposprop(i);
    #else
    if (i>=0 && i<pp.width)
        pp.incpos(i);
    #endif
    else {
      outcount++;
//      printf("%s: %s (i%i) out of range %i (l%f,%f,r%f),%i\n",pos.toString(),v.toString(),l,pp.width,left,ang,right,q);
    }
  }

};

float tofloat(VP *v) {
  return 0.0;
}

class ProjectionProfiler {
public:
  int res,ppres;
  Map2d<VP *> vps;
  Map2d<bool> binimg;
  Pixel best;
  bool writepps,writebestpp,doinfo;
  List<float> gaps;
  V2d imgcen;
  int scale;
  RGBmp info;

  ProjectionProfiler(int c,int p,Map2d<bool> b,bool wpps,bool wbpp,bool doi) {
    res=c;
    ppres=p;
    binimg=b;
    imgcen=V2d((float)binimg.width/2.0,(float)binimg.height/2.0);
    writepps=wpps;
    writebestpp=wbpp;
    doinfo=doi;
  }

  // From vps map to infinity circle
  V2d maptocircle(int i,int j) {
    return (V2d(i,j)-V2d((float)res/2.0,(float)res/2.0))/((float)res/2.0);
  }

  // From infinity circle to vps map
  Pixel mapfromcircle(V2d v) {
    return (float)res/2.0*(v+V2d(1.0,1.0))+V2d(.5,.5);
  }

  // Initialises a set of vanishing points for which
  // projection profiles will be calculated
  // VPs are distributed "evenly" across R^2
  void setup() {
    if (doinfo) {
      info=RGBmp(binimg.width,binimg.height,myRGB::black);
      for (int i=0;i<binimg.width;i++)
      for (int j=0;j<binimg.height;j++)
        if (binimg.getpos(i,j))
          info.setpos(i,j,myRGB::white);
    }
    scale=sqrt(mysquare(binimg.width)+mysquare(binimg.height))/2;
    #ifdef FIXPPRES
//      #ifdef PROPORTIONAL
        ppres=scale*2;
//      #else
//        ppres=scale;
//      #endif
    #endif
    int hw=binimg.width/2;
    int hh=binimg.height/2;
    vps=Map2d<VP *>(res,res);
    int vpcount=0;
    for (int i=0;i<res;i++)
    for (int j=0;j<res;j++) {
      V2d pos=maptocircle(i,j);
//      printf("Circle=%s\n",pos.toString());
      vps.setpos(i,j,NULL);
      // Must lie inside infinity circle
      if (pos.mag()<1.0) {
        // We offset the position of the VP slightly
        // so that the one at (0,0) is resolvable!
        V2d realpos=infcircletoplane(pos+V2d(0.0000001,0.0000001));
        // Must lie at some distance (PP boundary not accurate near or inside image)
        if (realpos.mag()>scale*1.5) {
          realpos=realpos+V2d(hw,hh);
//          printf("Plane=%s\n",realpos.toString());
          vps.setpos(i,j,new VP(realpos,ppres,scale,imgcen));
          vpcount++;
        }
      }
    }
    printf("Set up %i vanishing points with %i projection profiles\n",vpcount,vpcount);
  }

  // Accumulates projection profiles of the points
  // in the input image
  void calculate() {
    int w=binimg.width;
    int h=binimg.height;
    int vw=vps.width;
    int vh=vps.height;
    for (int i=0;i<w;i++) {
      if (i%17==0) // Learn your 17 times table as the
        printf("%i/%i\n",i,w); // program runs!
      for (int j=0;j<h;j++) {
        if (binimg.getpos(i,j)) {
          V2d pos=V2d(i,j);
          for (int a=0;a<vw;a++)
          for (int b=0;b<vh;b++) {
            VP *vp=vps.getpos(a,b);
            if (vp!=NULL)
              vp->add(pos);
          }
        }
      }
    }
  }

  // Finds the entropy of all the projection profiles
  // and puts them in a map
  Map2d<float> getppmap() {
    #define backgrounddummy -1234567.8e9
    Map2d<float> map=Map2d<float>(vps.width,vps.height,backgrounddummy);
    for (int i=0;i<vps.width;i++)
    for (int j=0;j<vps.height;j++)
      if (vps.getpos(i,j)!=NULL) {
        map.setpos(i,j,measure(vps.getpos(i,j)->pp));
//        map.setpos(i,j,-vps.getpos(i,j)->pp.totalsquare());
//        map.setpos(i,j,-vps.getpos(i,j)->pp.totalderiv());
//        map.setpos(i,j,vps.getpos(i,j)->pp.entropy());
      }
    map.searchreplace(backgrounddummy,map.largest());
    return map;
  }

  // Finds the best horizontal vanishing point by finding the
  // PP with lowest variance (or whatever measure)
  V2d getvp() {
    Map2d<float> map=getppmap();
    float lowest=0.0;
    V2d vp;
    for (int j=0;j<vps.height;j++)
    for (int i=0;i<vps.width;i++)
      if (vps.getpos(i,j)!=NULL)
        if (map.getpos(i,j)<lowest) {
          lowest=map.getpos(i,j);
          printf("Lowest so far (%i,%i) with %f\n",i,j,lowest);
          best=Pixel(i,j);
          vp=vps.getpos(i,j)->pos;
          // Draw this "good" pp
          if (writepps) {
            Map2d<bool> acc=vps.getpos(i,j)->pp.draw();
            acc.writefile(Sformat("pp%02ix%02i.bmp",i,j));
          }
          if (showbadx==i && showbady==j) {
            Map2d<bool> acc=vps.getpos(i,j)->pp.draw();
            acc.writefile("badpp.bmp");
          }
        }
    printf("Best projection profile: %s\n",best.toString());
    /* Plot the final PP */
    if (writebestpp) {
      Map2d<bool> acc=vps.getpos(best)->pp.draw();
      acc.writefile("bestpp.bmp");
    }
    /* Enlarge the inf circle map */
    #define icscale 15.0
    Map2d<float> map2=*map.scaledby(icscale);
    /* Plot the VP point */
    V2d c=(V2d(best)+V2d(0.5,0.5))*icscale;
    float col=map.largest();
    map2.line(c-V2d(icscale,icscale),c+V2d(icscale,icscale),col);
    map2.line(c-V2d(icscale,-icscale),c+V2d(icscale,-icscale),col);
    if (showbadx>=0 && showbady>=0) {
      col=0;
      c=(V2d(showbadx,showbady)+V2d(0.5,0.5))*icscale;
      map2.line(c-V2d(icscale,icscale),c+V2d(icscale,icscale),col);
      map2.line(c-V2d(icscale,-icscale),c+V2d(icscale,-icscale),col);
    }  
    map2.writefile("ppmap.bmp");
    return vp;
  }

  // Draw a Real^2 picture of the distribution of
  // the vanishing points
  Map2d<float> drawvps() {
    Map2d<float> b=Map2d<float>(300,300,0.0);
//    float farthest=maxinfcir*1.1e2;
    float farthest=0.0;
    for (int i=0;i<vps.width;i++)
    for (int j=0;j<vps.height;j++)
      if (vps.getpos(i,j)!=NULL) {
        V2d v=vps.getpos(i,j)->pos;
        if (v.mod()>farthest)
          farthest=v.mod();
      }
    for (int i=0;i<vps.width;i++)
    for (int j=0;j<vps.height;j++)
      if (vps.getpos(i,j)!=NULL) {
        V2d v=vps.getpos(i,j)->pos;
        Pixel p=Pixel(b.width/2.0*((v.x-binimg.width/2)/farthest+1.0),
                      b.height/2.0*((v.y-binimg.height/2)/farthest+1.0));
        float rad=5.0*v.mod()/farthest;
        b.circle(p,rad,vps.getpos(i,j)->pp.entropy());
        if (best==Pixel(i,j))
          b.circle(p,7,-1.0);
      }
    return b;
  }

  // Find the gaps between the lines (return as a list
  // of angles relative to the HVP )

  // Could find cuttoff value as:
  //   lowest value with highest number of transitions
  //   when moving horizontally across PP at that height
  // This should stop before (say) 1/2 because it could
  // be thrown off by spiked at top.

  void getgapangles() {
    VP v=*vps.getpos(best);
    Map1d<PPunit> pp=v.pp;
    PPunit top=pp.largest();
    // 3. Like 2 but \ defined as >1/2 -> <1/2 and / likewise
    int lastpeak=-1;
    int nextpeak=-1;
    for (int i=0;i<pp.width-1;i++) {
      if ( (pp.getpos(i) > top/2) &&
           (pp.getpos(i+1) <= top/2) )
        lastpeak=i;
      if ( (lastpeak!=-1) &&
           (pp.getpos(i) <= top/2) &&
           (pp.getpos(i+1) > top/2) )
        nextpeak=i+1;
      if ( (lastpeak!=-1) &&
           (nextpeak!=-1) ) {
        float cen=(float)(lastpeak+nextpeak)/2.0;
        float f=v.realleft+cen/(float)pp.width*(v.right-v.left);
        gaps.add(f);
        pp.setpos((int)cen,top-10);
//        pp.setpos(lastpeak,top-20);
//        pp.setpos(nextpeak,top-20);
        lastpeak=-1;
        nextpeak=-1;
      }
    }
/*  // 2. Look for \ followed by / .  Use centre.
    int lastdown=-1;
    for (int i=0;i<pp.width-1;i++) {
      if ( pp.getpos(i) > pp.getpos(i+1) )
        lastdown=i;
      if ( pp.getpos(i+1) > pp.getpos(i)
           && lastdown!=-1 ) {
        int firstup=i+1;
        float cen=(float)(lastdown+firstup)/2.0;
        if ( pp.getpos(cen) < top/2 ) {
          float f=v.realleft+(cen)/(float)(pp.width)*(v.right-v.left);
          gaps.add(f);
//          printf("Gap %i: %f\n",gaps.len,f);
          pp.setpos((int)cen,top);
        }
        lastdown=-1;
      }
    }*/
      /* // 1. Find change in deriv
      // i<pp.width-2
      if ( pp.getpos(i+1) < top/2.0 &&
           pp.getpos(i+1)-pp.getpos(i) < 0 &&
           pp.getpos(i+2)-pp.getpos(i+1) > 0 ) {
        float f=v.realleft+(float)(i+1)/(float)(pp.width)*(v.right-v.left);
        gaps.add(f);
        printf("Gap %i: %f\n",gaps.len,f);
        pp.setpos(i+1,top);
      } */
    printf("Found %i gaps between lines\n",gaps.len);
    pp.draw().writefile("bestppgaps.bmp");
  }

  int whichline(V2d p) { // between 1 and gaps.len+1
    VP v=*vps.getpos(best);
    float ang=(p-v.pos).angle();
    for (int i=1;i<=gaps.len;i++)
      if (anglebetween(gaps.num(i),ang)<0)
        return i;
    return gaps.len+1;
  }

  V2d getvvp() {
    getgapangles();
    V2d hvp=vps.getpos(best)->pos;

    printf("Collecting split lines into regions...\n");
    // Find centroid of each line
    List<V2d> cens;
    List<int> cnt;
    List<Region> liner;
    List<Line2d> lines;
    // Set up
    for (int i=0;i<=gaps.len;i++) {
      cens.add(V2d(0,0));
      cnt.add(0);
      liner.add(Region(binimg.width,binimg.height));
    }
    // Collect pixels into centroids
    for (int i=0;i<binimg.width;i++)
    for (int j=0;j<binimg.height;j++) {
      if (binimg.getpos(i,j)) {
        int k=whichline(V2d(i,j));
//        printf("%i ",k);
        int n=cnt.num(k);
        V2d old=cens.num(k);
        V2d vn=(old*(float)n+V2d(i,j))/(float)(n+1);
        cens.setnum(k,vn);
        cnt.setnum(k,n+1);
        liner.num(k).add(Pixel(i,j));
        if (doinfo) {
          myRGB col = ( k%2 == 0
                ? myRGB::blue
                : myRGB::green ).dark();
          info.setpos(i,j,col);
        }
      }
    }

    printf("Correlating ends of lines...\n");
    // Make three correlators to generate lines for
    // the left, center and right
    // Correlate the centroids to find a line
    // up the middle
    Correlator2d leftc,cenc,rightc;
    for (int i=1;i<=cens.len;i++) {
      Line2d l=liner.num(i).endtoendvp(hvp);
      lines.add(l);
//      cens.setnum(i,(l.a+l.b)/2.0);
      leftc.add(l.a);
      rightc.add(l.b);
      cenc.add((l.a+l.b)/2.0);
    }
    float lefterr=leftc.error();
    float cenerr=cenc.error();
    float righterr=rightc.error();

    // Check for justified paragraph
    // return VVP;

    int LineSpacing=1;
    int LineWidth=2;
    Line2d baseline;
//    int correlator=LineSpacing;
    int correlator=LineWidth;
    if (cenerr<lefterr && cenerr<righterr) {
      baseline=cenc.line();
      printf("Strongest correlation along CENTRES of lines\n");
    } else {
      if (lefterr<righterr) {
        baseline=leftc.line();
        printf("Strongest correlation along LEFT of lines\n");
      } else {
        baseline=rightc.line();
        printf("Strongest correlation along RIGHT of lines\n");
      }
    }


    // Find centre
//    V2d ave=c.centroid();
//    printf("Angle up middle %f with centre %s\n",ang,ave.toString());
    V2d vvpdir=(baseline.b-baseline.a).norm();

    if (doinfo) {
      // Show centres correlation
      drawCorrelator2d(cenc).writefile("corcentre.bmp");
      drawCorrelator2d(leftc).writefile("corleft.bmp");
      drawCorrelator2d(rightc).writefile("corright.bmp");
      // Draw line through each gap
      Line2d upmiddle=baseline; // Line2d(ave-vvpdir*50.0,ave+vvpdir*50.0);
      for (int i=1;i<=gaps.len;i++) {
        Line2d fromside=Line2d(hvp,hvp+V2d::angle(gaps.num(i)));
        V2d hit=upmiddle.intersect(fromside);
        info.line(hvp,hit,myRGB::yellow);
      }
      // Draw central line
      V2d diff=vvpdir*max(binimg.width,binimg.height)/2.0;
      info.line(baseline.a-diff,baseline.a+diff,myRGB::white);
      // Plot correlation points
      for (int i=1;i<=cens.len;i++) {
        info.cross(leftc.points.num(i).x,leftc.points.num(i).y,5,myRGB::red);
        info.cross(cenc.points.num(i).x,cenc.points.num(i).y,5,myRGB::red);
        info.cross(rightc.points.num(i).x,rightc.points.num(i).y,5,myRGB::red);
      }
    }

    // Now correlate line spacings along the central line
    // First, project all centres onto this line
    List<float> cds;
    for (int i=1;i<=cens.len;i++) {
      Line2d l=Line2d(hvp,cens.num(i));
      V2d v=baseline.intersect(l);
      if (doinfo)
        info.cross(v,5,myRGB::cyan);
      float f=(v-baseline.a).dot(vvpdir);
      cds.add(f);
    }
    // Accumulate correlator
    Correlator2d cs;
    // Why not do line-spacing with gaps?
    // (seems equivalent so no worry)
    int cdsend=( correlator==LineSpacing
               ? cds.len-1
               : cds.len );
    for (int i=1;i<=cdsend;i++) {
      float a=cds.num(i);
      int weight=cnt.num(i);
      if (correlator==LineSpacing) {
        // x = average of two cds, y = dist between
        float b=cds.num(i+1);
        float pos=(a+b)/2.0;
        cs.add(V2d(pos,myabs(b-a)),weight);
      } else if (correlator==LineWidth) {
        // y = width of line
        float pos=a;
        cs.add(V2d(pos,lines.num(i).length),weight);
      } else {
        error("Non existent correlator");
      }
    }
    float vpd=cs.crossesy();
    V2d vvp=baseline.a+vvpdir*vpd;
    if (doinfo) {
      drawCorrelator2d(cs).writefile("spacings.bmp");
      V2d left=imgcen+(hvp-imgcen).norm()*(float)scale/3.0;
      V2d right=imgcen-(hvp-imgcen).norm()*(float)scale/3.0;
      info.line(left,vvp,myRGB::cyan);
      info.line(right,vvp,myRGB::cyan);
    }
    return vvp;
  }

};
 
void main(int argc,String *argv) {
  
  ArgParser a=ArgParser(argc,argv);
  int cirres=a.intafter("-res","resolution of infinity circle",30);
  int ppres=-1;
  #ifndef FIXPPRES
    ppres=a.intafter("-ppres","resolution of each projection profile",200);
  #endif
  bool recoverquad=!a.argexists("-norecover","don't recover frontal view");
  bool writepps=a.argexists("-writepps","write the potential PPs");
  bool writebestpp=!a.argexists("-dontwritebestpp","don't write the best PP");
  bool doinfo=!a.argexists("-noinfo","don't draw info image");
//  a.comment("Info image options:");
  a.comment("PP measure of correctness: (default = derivative)");
  measure=&measurederiv;
  if (a.argexists("-deriv","use derivative measure"))
    measure=&measurederiv;
  if (a.argexists("-square","use square measure"))
    measure=&measuresquare;
  if (a.argexists("-entropy","use entropy measure"))
    measure=&measureentropy;
  if (a.argexists("-variance","use variance measure"))
    measure=&measurevariance;
//  bool invert=a.argexists("-inv","invert input image to look for line spaces");
  showbadx=a.intafter("-badx","x pos of bad PP to show",-1);
  showbady=a.intafter("-bady","y pos of bad PP to show",-1);
  String bname=a.getarg("binary image");
  String oname=a.argor("original image","*none*");
  a.done();

  Map2d<bool> binimg=*Map2d<bool>::readfile(bname)->threshold(0.5);
  RGBmp origimage;
  if (!Seq(oname,"*none*"))
    origimage=*(RGBmp::readfile(oname));

  /* Inverting is naff because it takes too long, due to
     have to project of all black pixels
     Need to be more cunning!
    if (invert)
    binimg.invert();*/

  ProjectionProfiler pp=ProjectionProfiler(cirres,ppres,binimg,writepps,writebestpp,doinfo);
  pp.setup();
  pp.calculate();
  V2d vp=pp.getvp();

  V2d vvp=pp.getvvp();

  if (recoverquad) {
    VP vp=*pp.vps.getpos(pp.best);
    V2d hvp=vp.pos;

    // Find top,bottom,left,right angles
    int penlarge=20;
    float henlarge=(float)penlarge/hvp.mag();
    float venlarge=(float)penlarge/vvp.mag();
    float ha=vp.realleft+(vp.right-vp.left)*(float)vp.pp.firstnonzero()/(float)vp.pp.width-henlarge;
    float hb=vp.realleft+(vp.right-vp.left)*(float)vp.pp.lastnonzero()/(float)vp.pp.width+henlarge;
    if (hvp.x<0) // Ensure top and bottom correct
      swap(&ha,&hb);
    float va=(pp.imgcen-vvp).angle();
    float vb=va;
    for (int i=0;i<binimg.width;i++)
    for (int j=0;j<binimg.height;j++)
      if (binimg.getpos(i,j)) {
        V2d v=V2d(i,j);
        float ang=(v-vvp).angle();
        float da=mymod(ang-va,-pi,+pi);
        if (da<0)
          va=ang;
        float db=mymod(ang-vb,-pi,+pi);
        if (db>0)
          vb=ang;
      }
    va=va-venlarge;
    vb=vb+venlarge;
    if (vvp.y>0) // Ensure left and right correct
      swap(&va,&vb);
    float bigtmp=max(vvp.mag(),hvp.mag())*1.5;
    Line2d top=Line2d(hvp,hvp+bigtmp*V2d::angle(ha));
    Line2d bottom=Line2d(hvp,hvp+bigtmp*V2d::angle(hb));
    Line2d left=Line2d(vvp,vvp+bigtmp*V2d::angle(va));
    Line2d right=Line2d(vvp,vvp+bigtmp*V2d::angle(vb));
    if (doinfo) {
      pp.info.line(top,myRGB::magenta.dark());
      pp.info.line(bottom,myRGB::magenta.dark());
      pp.info.line(left,myRGB::magenta.dark());
      pp.info.line(right,myRGB::magenta.dark());
    }
  if (doinfo) {
    pp.info.writefile("info.bmp");
    pp.drawvps().writefile("pps.bmp");
  }
    V2d tl=top.intersect(left);
    V2d tr=top.intersect(right);
    V2d bl=bottom.intersect(left);
    V2d br=bottom.intersect(right);
/*    printf("TL: %s\n",tl.toString());
    printf("TR: %s\n",tr.toString());
    printf("BR: %s\n",br.toString());
    printf("BL: %s\n",bl.toString());*/
    if (doinfo) {
      pp.info.line(tl,tr,myRGB::grey);
      pp.info.line(bl,br,myRGB::grey);
      pp.info.line(tl,bl,myRGB::grey);
      pp.info.line(tr,br,myRGB::grey);
    }

    // Recover quadrilateral
/*    // New method using angles
    float aspect=(tl.dist(bl)+tr.dist(br))/(tl.dist(tr)+bl.dist(br));
    RGBmp n=RGBmp(600,600*aspect);
    for (int i=0;i<n.width;i++)
    for (int j=0;j<n.height;j++) {
      float xang=va+(vb-va)*(float)i/(float)n.width;
      float yang=ha+(hb-ha)*(float)j/(float)n.height;
      Line2d xline=Line2d(hvp,hvp+bigtmp*V2d::angle(yang));
      Line2d yline=Line2d(vvp,vvp+bigtmp*V2d::angle(xang));
      V2d hit=xline.intersect(yline);
      n.setpos(i,j,origimage.getinter(hit.x,hit.y));
    } */
/*    // Linear
    RGBmp n=*origimage.recoverquad(tl,tr,br,bl,600); */
    // 3D estimate (best so far)
    List<V2d> qs;
    qs.add(tl); qs.add(tr); qs.add(br); qs.add(bl);
    RGBmp n=*origimage.recoverquad(&qs,1,600);
    n.writefile("recover.bmp");

  }


//  if (outcount>0)
    printf("%i pixels fell outside their window.\n");

}
