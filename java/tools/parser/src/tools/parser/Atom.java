package tools.parser;
/* This source code is freely distributable under the GNU public licence.
	I would be delighted to hear if have made use of this code.
	If you make money with this code, please give me some!
	If you find this code useful, or have any queries, please feel free to
	contact me: pclark@cs.bris.ac.uk / joeyclark@usa.net
	Paul "Joey" Clark, hacking for humanity, Feb 99
	www.cs.bris.ac.uk/~pclark / www.changetheworld.org.uk */

import jlib.Profile;

import java.lang.*;
import java.util.*;

import java.awt.TextArea; // debug
import java.awt.Frame; // debug
import java.awt.FlowLayout; // debug
import java.awt.event.ActionListener; // debug
import java.awt.event.ActionEvent; // debug
import java.awt.Button; // debug

import org.neuralyte.Logger;
import org.neuralyte.common.ArrayUtils;
import org.neuralyte.common.StringUtils;

import jlib.Files;
import jlib.JString;
import jlib.strings.*;

import tools.parser.*;

public class Atom implements Type {
	public static int depth=0;
	String type;
	Atom(String t) {
		type=t;
	}
	public static String strip(SomeString s) {
		return strip(s.toString());
	}
	public static String strip(String s) {
		int max=20;
		if (s.length()>max)
			s=JString.left(s,max)+"..."+(s.length()-max);
		s=JString.replace(s,"\n","\\n");
		return s;
	}
	public Match match(SomeString s) {
		Profile.start("Atom.match: Elsewhere");
		RuleSet rs=Grammar.getrulesetforatom(type);
		if (Parser.Debugging) {
			Logger.log("Entered atom "+type+" with "+rs.rules.size()+" rules...");
		}
		for (int i=0;i<rs.rules.size();i++) {
			Profile.start("Atom.match: Outside loop");
			Vector rules=(Vector)rs.rules.get(i);
			if (rules.size()==0) {
				System.err.println("rulesetforatom("+type+") number "+i+" is empty!");
				System.exit(1);
			}
			
			// This is often not enough info when a match is failing. The grammar
			// writer is more interested in the stack of trial matches we recently
			// tried.
			int lastchar = s.length() < 40 ? s.length() : 40;
			Parser.lastMatchAttempt = "Trying to match "+rules+" against: "+StringUtils.escapeSpecialChars(s.substring(0, lastchar))+"..";
			if (Parser.Debugging) {
				Logger.log(Parser.lastMatchAttempt);
			}
			Vector ms=new Vector();
			SomeString left=s;
			boolean failure=false;
			for (int j=0;j<rules.size() && !failure;j++) {
				Profile.start("Atom.match: Inside loop");
				Type t=(Type)rules.get(j);
				Profile.start("Atom.match: inner inner");
				// Profile.start(t.getClass().getName()+".match()"); // heavy
				Match m=t.match(left);
				// Profile.stop(t.getClass().getName()+".match()"); // heavy
				Profile.stop("Atom.match: inner inner");
				if (m==null)
					failure=true;
				else {
					ms.add(m);
					//          System.out.println("  Original: "+strip(left));
					left=m.left;
					//          System.out.println("       New: "+strip(left));
				}
				Profile.stop("Atom.match: Inside loop");
			}
			depth--;
			if (!failure) {
				if (Parser.Debugging) {
					Logger.log("Succeeded: "+rules);
				}
				Match m=new Match(this,s.subString(0,s.length()-left.length()),ms,left);
				depth--;
				Profile.stop("Atom.match: Outside loop");
				Profile.stop("Atom.match: Elsewhere");
				return m;
			} else {
				// Logger.log("Failed.");
			}
			Profile.stop("Atom.match: Outside loop");
		}
		depth--;
		Profile.stop("Atom.match: Elsewhere");
		return null;
	}
	public String toString() {
		return type;
	}
	public boolean replacementfor(Type o) {
		if (o instanceof Atom) {
			Atom a=(Atom)o;
			if (type.equals(a.type))
				return true;
		}
		return false;
	}
}
