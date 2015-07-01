using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Math;
using Toybox.Lang as Lang;
using Toybox.Application as App;

//************************************************************************
//  AWI dotface PLUS Version 0.9
//*
//*  Dokumentation      : nicht vorhanden siehe Anmerkungen im Code
//*  Programmname       : awidotView.mc
//*  Beschreibung       : Dieses Watchface zeigt mit einer großen (SUUNTO CORE ähnlichen) Schrift die Uhrzeit
//*                       Die täglichen Schritte sowie das Tagesziel werden als Zahlen sowie als ARC dargestellt
//*                       Der Batteriebalken wird farblich geändert je nach Ladezustand
//*                       Der Batteriprozentwert (%)-Zeichen ändert die farbe wenn ein Telefon verbunden ist (blau = bluetooth aktiv)
//*                       Das Datum wird angezeigt, Wochentag wird ausgeblendet wenn Sekundenzeiger bei "onLook" aktiviert wird
//*                       Wenn es ein "Specialday" ist (1.Mai, Halloween, usw) wird ein Stern nach dem Datum angezeigt. Dann gilt es das Tagesziel zu erreichen!
//*                       Die Farbe der Sekundenanzeige signalisiert ob manauf Grundlag eines (7am to 22pm) Tages sein Schritteziel erreicht
//*                       Anhand der Steps-Historie der letzten 7 Tage können diverse Pokale erreicht werden
//*                       Anhand des gestrigen tages (steps) können Specials erreicht werden (150%,200%, Specialtage, Weekendwarrior)
//*                                                
//*  Funktion           : Watchface, Fenix3
//*  Author             : A.Weis
//*  Datum              : 29/06/2015
//*                      
//*  Release        : Garmin SDK 1.1.2
//*======================================================================
//*----------------------------------------------------------------------
//* Änderungshistorie
//*     Datum    | von     | 
//* -----------  ----------  --------------------------------------------
//*  29.06.2015   AWI   initial erstellt
//*  01.07.2015   AWI   am / pm 24h mode support                        
//**
//************************************************************************

// Things to do
// 2. 25000 und 50000 und 100000 Schritte Ziel
// 3. Diverse aktionen nur noch einmal je Stunde
// 6. Version für square Watch bauen
// 10. CHAOS Coduing verbessern!



class awidotView extends Ui.WatchFace {



 var dict_event = { "216"   => true, 
                   "229"   => true, 
                   "2112"  => true,
                   "203"   => true,
                   "45"    => true,
                   "11"    => true,
                   "3110"  => true,    
                   "286"   => true,
                   "143"   => true,
                   "304"   => true,
                   "15"    => true,
                  "68"    => true,
                   "310"   => true 
              };
 var dict_eventy = { "226"   => "summer", 
                   "239"     => "autumn", 
                   "2212"    => "winter",
                   "213"     => "spring",
                   "55"      => "starwars",
                   "21"      => "newyear",
                   "111"     => "halloween",    
                   "296"     => "testday",
                   "153"     => "piday",
                   "15"      => "walpurgis",
                   "25"      => "firstmay",
                   "78"      => "hiroshima",
                   "410"     => "tdde" 
             };

   var font;    // Font for Hours & Minutes
   var fontbig; // Font for seconds
   var pic_dayone; // 1 day in a (short) row ;-) -- yesterday
   var pic_daythree; // 3 days i a row
   var pic_dayfive; // 5 days in a row
   var pic_dayseven; // 7 days in a row
   var pic_goal300;  // goal reached 300%
   var pic_goal200; // goal reached 200%
   var pic_goal150; // goal reached 150%
   var pic_daypig;  // displays a pig --> 0 goals reached within 7 days
   var pic_weekendwar; // weekendwarrior --> Sat & Sun goal reached with >= 200% 
   var pic_specialday; // picture for special days 
   var pic_am; // am or pm font as *.png 
   var pic_pm; // pm der was a error using only 1 variable by switching between 24 and 12h mode while watchface  
   
   var sec;
   var screenWidth;  
   var screenHeight;
   
   var device_settings; //basics for bluetooth indicator
    // Variables for Arc
	var deg2rad = Math.PI/180;
	var CLOCKWISE = -1;
	var COUNTERCLOCKWISE = 1;
	
    var fast_updates = true; //  screenupdate "AT_LOOK_AT SCREEN"

    //! Load your resources here
    function onLayout(dc) {
        font = Ui.loadResource(Rez.Fonts.id_font_dot);
        fontbig = Ui.loadResource(Rez.Fonts.id_font_big);
   	    screenWidth = dc.getWidth();
	    screenHeight = dc.getHeight();
	  // Grundlage für Bluetooth connection
        device_settings = Sys.getDeviceSettings(); 
       
       // pictures to load
        pic_dayone     = Ui.loadResource(Rez.Drawables.id_dayone);
        pic_daythree   = Ui.loadResource(Rez.Drawables.id_daythree);     
        pic_dayfive    = Ui.loadResource(Rez.Drawables.id_dayfive);     
        pic_dayseven   = Ui.loadResource(Rez.Drawables.id_dayseven);     
        pic_daypig     = Ui.loadResource(Rez.Drawables.id_daypig);     
        pic_goal300    = Ui.loadResource(Rez.Drawables.id_goal300);  
        pic_goal200    = Ui.loadResource(Rez.Drawables.id_goal200);  
        pic_goal150    = Ui.loadResource(Rez.Drawables.id_goal150);  
        pic_weekendwar = Ui.loadResource(Rez.Drawables.id_pic_weekendwar);
        
        // am pm picture
        pic_am         = Ui.loadResource(Rez.Drawables.id_pic_am);
        pic_pm         = Ui.loadResource(Rez.Drawables.id_pic_pm); 
        
        // maybe the most inefficient way to load thr right "special-day"-picture.
        // sorry, my first try with dicts --> very shitty code
        // 1st may is checked on 2nd may 
        var wasspecial = wasSpecialDay(); 
        if ( wasspecial == dict_eventy["226"] ){  //summer
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_summer);
        } 
        else if (wasspecial == dict_eventy["2212"]){ //winter
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_winter);
        } 
        else if (wasspecial == dict_eventy["213"]){ //spring
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_spring);
        } 
        else if (wasspecial == dict_eventy["239"]){ // autumn
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_autumn);
        } 
        else if (wasspecial == dict_eventy["55"]){ // starwars may the 4th be with you
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_starwars);
        } 
        else if (wasspecial == dict_eventy["21"]){ // newyear
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_newyear);
        } 
        else if (wasspecial == dict_eventy["111"]){ // halloween
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_halloween);
        } 
        else if (wasspecial.toString() == dict_eventy["297"]){  // Testday
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_testday);
        } 
        else if (wasspecial == dict_eventy["153"]){ // piday
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_piday);
        } 
        else if (wasspecial == dict_eventy["15"]){ // walpurgis
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_walpurgis);
        } 
        else if (wasspecial == dict_eventy["25"]){ // first may
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_firstmay);
        } 
        else if (wasspecial == dict_eventy["78"]){ // hiroshima  
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_hiroshima);
        } 
        else if (wasspecial == dict_eventy["410"]){ // Tag der deutschen Einheit
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_tdde);
        }
        else {
            pic_specialday = Ui.loadResource(Rez.Drawables.id_pic_black); // if there is something wrong, just a black picture
        }
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
       // black is beautiful CLEAR the screen.
      dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
      dc.clear();  
       
 	  // draw Activity bar (Arc, Steps and StepsGoal) 
 	  drawActivity(dc);
 	  
 	  
 	    var clockTime = Sys.getClockTime();
        var hour, min, time;

        min  = clockTime.min;
        hour = clockTime.hour;
        if( !device_settings.is24Hour ) { // AM/PM anzeige
           if (hour == 0) {hour = 12;}
           if (hour >= 13) {
                hour = hour - 12;
                dc.drawBitmap(screenWidth/2 -19, 15, pic_pm); // show pm sign
                }
                else{
                dc.drawBitmap(screenWidth/2 -19, 15, pic_am); // show am sign
                }
            time  = Lang.format("$1$ : $2$",[hour.format("%2d"), min.format("%02d")]); 
        }
        else {
            time = Lang.format("$1$ : $2$",[hour.format("%02d"), min.format("%02d")]);
        }
 	  
 	    // #########################draw TIME ####################################		
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(screenWidth/2, 58 , font, time, Gfx.TEXT_JUSTIFY_CENTER );
        
        //get date & display
        var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var datum_print =   dateStrings.day.toString() + " " + dateStrings.month.toString();
        if ( isSpecialDay() ) {datum_print = datum_print + "*";} // if today = specialday print a "*" next do Month as indicator
        dc.drawText(screenWidth/2, 195, Gfx.FONT_XTINY, datum_print, Gfx.TEXT_JUSTIFY_CENTER);
        
        // Sekundenanzeigen im POWER Modus (wenn man die Hand dreht), sonst Wochentag
        if (fast_updates == true){
			var sec = clockTime.sec;
	    	// check if you are on a good way achieving your daily stepsGoal
			var seccolor = secprognose(); // get the right color
	        dc.setColor(seccolor, Gfx.COLOR_TRANSPARENT); 
	        dc.drawText(screenWidth /2, 140 , fontbig, sec.toString(), Gfx.TEXT_JUSTIFY_CENTER );
        }
        else { 
		 drawHis(dc);	 // show Trophys
		 drawSpecial(dc); // show Batches (specialdays, 200% batch a.s.o.)	
         dc.drawText(screenWidth /2, 170 , Gfx.FONT_MEDIUM, dateStrings.day_of_week, Gfx.TEXT_JUSTIFY_CENTER);     
        }
       
        // draw the battery bar
        drawBattery(dc);
        
       }


// calculate die activity steps & Goal, call the green arc
function drawActivity(dc) {
  var activity = ActivityMonitor.getInfo();
  var stepsGoal = activity.stepGoal;
  var stepsLive = activity.steps;
  var activproz; 
  activproz = ( ( ( 100 * activity.steps.toFloat() ) / activity.stepGoal ) / 100 ) * 180;
  if ( activproz > 180 ) { activproz = 180;}	
  
  dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);       
  //                x             y              radius    dicke    angel   offin  color                                direction
 drawArc(dc, screenWidth/2, screenHeight/2, screenHeight/2-5, 7, activproz.toNumber(), -90, [Gfx.COLOR_DK_GREEN, Gfx.COLOR_BLACK], CLOCKWISE); // grüner balken drüberlegen
  
  // Show steps and stepsGoal als numbers
  dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
  dc.drawText(3, 114 , Gfx.FONT_XTINY,stepsLive.toString() , Gfx.TEXT_JUSTIFY_LEFT);
  dc.drawText(215, 114 , Gfx.FONT_XTINY, stepsGoal.toString() , Gfx.TEXT_JUSTIFY_RIGHT );   
    
}

//is today a special day
function isSpecialDay(){  
  var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
  var event = dateStrings.day.toString() + dateStrings.month.toString();
  if (dict_event[event]){
    return true;
  } else {
    return false;
  }      
}
//was yesterday a special day?
function wasSpecialDay(){
  var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
  var event = dateStrings.day.toString() + dateStrings.month.toString();
  var actproz;
   
  if (dict_eventy[event] != null ){ // just take a look to the other dict. Its easier to declare 2 dicts than to calc "yesterday" dict_event[]!
      var acthis = ActivityMonitor.getHistory();
    	 if (acthis.size() > 0){
		      actproz = 100 * ( acthis[0].steps.toFloat() / acthis[0].stepGoal );
		      if ( actproz >= 100 )   { // ziel gestern erreicht
	            return dict_eventy[event];	        
		      }
		      else{   
		         return false;
		      }  
		 }
		 else {
		   return false;
		 }  
   } 
   else {
    return false;
  }      
}   	 

  // read 7 day history and get Trophys
function drawHis(dc){

  var activity = ActivityMonitor.getInfo();
  var acthis = ActivityMonitor.getHistory();
  var bruch = false;
  var j = 0; // count goals achieved in a row
  var k = 0; // count goal achieved in total within 7 days (for 0-goal pig)
  var i = 0; // Counter
  
  // LOOP at history
 for( i = 0; i < acthis.size(); i ++)
  {
	  if ( (acthis[i].steps.toFloat() / acthis[i].stepGoal) >= 1 )	  {
	   if (!bruch) { j++;} 
	   k++; // 	
	  } else {  
	  bruch = true; // found a non achieved daily goal. so break
	  }	
  }
  
  // Draw trophy
  if (j == 7) {  dc.drawBitmap(27, 133, pic_dayseven);}
  else if (j >= 5) { dc.drawBitmap(27, 133, pic_dayfive);}
  else if (j >= 3) { dc.drawBitmap(27, 133, pic_daythree);}
  else if (j >= 1) { dc.drawBitmap(27, 133, pic_dayone);}
  
  if (k == 0) { // not even 1 goal achieved --> show the little pig as icon!
    dc.drawBitmap(27, 133, pic_daypig);
  }
}

  // read yesterday and display special batches
function drawSpecial(dc){
 
  var activity = ActivityMonitor.getInfo();
  var acthis = ActivityMonitor.getHistory();
  var actproz;
  var i;
  var dateStrings = Time.Gregorian.info( Time.now(), Time.FORMAT_SHORT);
  var check = true;
 

//special Day batch is more important than every other batch (without 300% batch)
	if (wasSpecialDay() != null ){
	    dc.drawBitmap(131, 133, pic_specialday);
	    check = false; // batch set
	}
	 
// Weekendwarrior
// don#t check weekendwarior batch on Sat & Sunday 
// to achieve the batch, sa & sun must be achieved with 200%
	if ( (dateStrings.day_of_week != 1 ) && (dateStrings.day_of_week!= 7) && (check) ){
	  if ( acthis.size() == 7 ){ // only if the history is completely filled
	   actproz = 100 * ( acthis[dateStrings.day_of_week.toNumber() - 2].steps.toFloat() / acthis[dateStrings.day_of_week.toNumber() - 2].stepGoal );
	   if ( actproz >= 200 ){ // sunday achieved
		actproz = 100 * ( acthis[dateStrings.day_of_week.toNumber() - 1].steps.toFloat() / acthis[dateStrings.day_of_week.toNumber() - 1].stepGoal );
	  	 if ( actproz >= 200 ){ // saturday achieved 
			 dc.drawBitmap(131, 133, pic_weekendwar); // show weekendwarrior!
			 check = false;
		 }
	   }
	 }    
}



 
 // Es sollen nur das erste Ziel ausgewertet werden, falls es gestern aber nicht gibt gab es einen Fehler.
// daher schleife
 if ( acthis.size() > 0 )
  {
  	  actproz = 100 * ( acthis[0].steps.toFloat() / acthis[0].stepGoal );
	  if ( actproz >= 300 )	  { // we warrior gesetzt, aber drüber legen!
		{ dc.drawBitmap(131, 133, pic_goal300);}
	  }
	  else  if ( actproz >= 200 && (check) )	  {
		{ dc.drawBitmap(146, 148, pic_goal200);}
	  }
	   else if ( actproz >= 150 && (check) )	  {
		{ dc.drawBitmap(146, 148, pic_goal150);}
	  }	  
  }
}


// let's check if you are on a good way to achieve your daily goal
function secprognose() { 
  var activity = ActivityMonitor.getInfo();
  var stepsGoal = activity.stepGoal;
  var stepsLive = activity.steps;
  var aktivstunden = 13;
  var clockTime = Sys.getClockTime();
  var hour = clockTime.hour;
  var min  = clockTime.min;
  
  //Sys.println(activproz);
  var color;
   // just color the second indicator between 7 and 22 o'clock	
   if ( ( hour >= 7 ) && ( hour <= 22 )  ) { 
	    var hourdelta = hour - 6; // hours since 7 am
	    var activist =  stepsLive.toFloat();  
	    var activsoll = stepsGoal.toFloat() / 15;
	    var activproz = 100 * ( ( activist ) / ( activsoll * hourdelta) ) ;
	      
 	    // color the thing!
        if (activproz >= 100) {
            color = Gfx.COLOR_GREEN;  }
        else if (activproz >= 90) {
            color = Gfx.COLOR_DK_GREEN;  }
        else if (activproz > 75) {
            color = Gfx.COLOR_YELLOW;  }
        else if (activproz > 50) {
            color = Gfx.COLOR_ORANGE;  }
        else if (activproz > 25) { 
            color = Gfx.COLOR_RED;  }
        else {
            color = Gfx.COLOR_DK_RED;  }
   }
   else { // else use dark gray (between 0-6:59 and 23 o'clock- 0 U
    color = Gfx.COLOR_DK_GRAY;
   }      
  return color;
}   
	   
// Draw the battery bar	   
function drawBattery(dc) {
        var batt = Sys.getSystemStats().battery;
        batt = batt.toNumber();
      
        dc.setColor( Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(59, 118, 100, 5, 5);
        if (batt >= 75) {
            dc.setColor( Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);  }
        else if (batt > 50) {
            dc.setColor( Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT); }
        else if (batt > 40) {
            dc.setColor( Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT); }
        else if (batt > 25) {
            dc.setColor( Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT); }
        else if (batt > 15) { 
            dc.setColor( Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);    }
        else {
            dc.setColor( Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
         }
        dc.fillRoundedRectangle(59, 118, 100 - ( 100 - batt), 5, 5);
        
      
        var batttxt = batt.toString();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, 121 , Gfx.FONT_XTINY, batttxt , Gfx.TEXT_JUSTIFY_CENTER ); 
        if( device_settings.phoneConnected == true){ // bluetooth connected?
          dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);}
        else {
          dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        } 
        dc.drawText(dc.getWidth()/2 + ( dc.getTextWidthInPixels(batttxt, Gfx.FONT_XTINY) ), 121 , Gfx.FONT_XTINY, "%" , Gfx.TEXT_JUSTIFY_CENTER ); 
        
        
}

// Draw the ARC--> Thanks to garmin Forum!
//dc = drawingcontext from the onUpdate(dc)
//x,y = centerpoint of circle from which to make the arc
//radius = how big
//thickness = how thick of an arc to draw
//angle = 0 (nothing) to 360 (Full circle) in degrees. If you have/use radians, you can swap to radians and remove the deg2rad conversion factor inside, but I'm a degree kind of guy :)
//offsetIn = -180 to 180 in degrees. 0 will start arc from top of screen. Depends on chosen drawing direction, -90 & CLOCKWISE starts arc at 9o'clock, 90 & CLOCKWISE starts at 3o'clock position, 180 and either direction starts from 6o'clock
//colors = array containing [arc color, background fill color(usually black), [border color]] -border color is optional, leave out for no border
//direction = either CLOCKWISE or COUNTERCLOCKWISE and determines which direction the arc will grow in
function drawArc(dc, x, y, radius, thickness, angle, offsetIn, colors, direction){
    var color = colors[0];
	var bg = colors[1];
	var curAngle;
    	if(angle > 0){
    		dc.setColor(color,color);
    		dc.fillCircle(x,y,radius);
            
            dc.setColor(bg,bg);      
    		dc.fillCircle(x,y,radius-thickness);

    		if(angle < 360){
			var pts = new [33];
			pts[0] = [x,y];

			angle = 360-angle;
			var radiusClip = radius + 2;
			var offset = 90*direction+offsetIn;

			for(var i=1,dec=angle/30f; i <= 31; angle-=dec){
				curAngle = direction*(angle-offset)*deg2rad;
				pts[i] = [x+radiusClip*Math.cos(curAngle), y+radiusClip*Math.sin(curAngle)];
				i++;
			}
			pts[32] = [x,y];
			dc.setColor(bg,bg);
			dc.fillPolygon(pts);
    		}
    	}else{
    		dc.setColor(bg,bg);
    		dc.fillCircle(x,y,radius);
    	}
        if(colors.size() == 3){
    		var border = colors[2];
    		dc.setColor(border, Gfx.COLOR_TRANSPARENT);
    		dc.drawCircle(x, y, radius);
    		dc.drawCircle(x, y, radius-thickness);
    	}
    }    


    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {  
		fast_updates = true;
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        fast_updates = false;
        Ui.requestUpdate();
      }

}
