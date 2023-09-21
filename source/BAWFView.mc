/*============================================================================
  Battery-saving Analog Watch Face
  Copyright (c)2018-2023 Kevin Boone
  Released under the terms of the GNU Public Licence, v3.0
============================================================================*/
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;

/** Main class for the battery-saving watch face. */
class BAWFView extends WatchUi.WatchFace
  {
  var dndIcon;
  var offscreenBuffer;
  var screenCenterPoint;
  var width;
  var height;
  var halfWidth;
  var halfHeight;
  var twoPi = Math.PI * 2.0;
  var bgColour;
  var fgColour;

  function initialize() 
    {
    WatchFace.initialize();
    }

  /* Note that there are two setColours functions, for white on black
     and black on white. Exactly one must be included, using settings
     in the .jungle file */
 
  (:bow) function setColours ()
      {
      fgColour = Graphics.COLOR_BLACK;
      bgColour = Graphics.COLOR_WHITE;
      }

  (:wob) function setColours ()
      {
      fgColour = Graphics.COLOR_WHITE;
      bgColour = Graphics.COLOR_BLACK;
      }

  function onLayout (dc) 
    {
    if (System.getDeviceSettings() has :doNotDisturb) 
      {
      dndIcon = WatchUi.loadResource(Rez.Drawables.DoNotDisturbIcon);
      } 
    else 
      {
      dndIcon = null;
      }

   setColours();

    /* If we can use an off-screen buffer to build the screen display,
       then do. If not, draw direct to the screen. */

    /* Buffered bitmap support has changed completely in recent 
       (Venu-era) devices. This change is poorly documented, and some of
       the sample applications from the Garmin SDK fail on these devices :/
       Sigh. So we have to create the offscreen buffer in various different
       ways. */
    if (Toybox.Graphics has :createBufferedBitmap) /* Test this first */ 
      {
      offscreenBuffer = Graphics.createBufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight()});
      offscreenBuffer = offscreenBuffer.get(); // Ugh. Nasty workaround. 
      }
    else if (Toybox.Graphics has :BufferedBitmap)  
      {
      /* Post-Venu, invoking this constructor fails, even though it seems
         to exist. Nice one, Garmin :/ */
      offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight()});
      } 
    else 
      {
      offscreenBuffer = null;
      }

    screenCenterPoint = [dc.getWidth() / 2, dc.getHeight() / 2];
    }


  function onUpdate (dc) 
    {
    var clockTime = System.getClockTime();

    var targetDc = null;
    if (null != offscreenBuffer) 
      {
      dc.clearClip ();
      targetDc = offscreenBuffer.getDc();
      } 
    else 
      {
      targetDc = dc;
      }

    width = targetDc.getWidth();
    height = targetDc.getHeight();
    halfWidth = width / 2;
    halfHeight = height / 2;

    // Clear screen
    targetDc.setColor (bgColour, fgColour); 
    targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

    // Draw do-not-disturb icon, if necessary
    if (null != dndIcon && System.getDeviceSettings().doNotDisturb) 
      {
      targetDc.drawBitmap( width * 0.75, halfHeight - 15, dndIcon);
      }

    // Draw the watch face
    drawDateString (targetDc);
    drawHands (targetDc, clockTime);
    drawCentre (targetDc);
    drawNumerals (targetDc);
    drawDataString (targetDc);

    // If we're working with an off-screen buffer, transfer the
    // buffer to the string. If not, there's nothing else to do --
    // screen has already been drawn
    if (null != offscreenBuffer) 
      {
      dc.drawBitmap (0, 0, offscreenBuffer);
      }
    }


  /** Draw the little arbor in the centre of the face that the "hands"
      attach to. */
  function drawCentre (dc)
    {
    dc.setColor (Graphics.COLOR_LT_GRAY, bgColour);
    dc.fillCircle (halfWidth, halfHeight, 7);
    dc.setColor (fgColour, bgColour);
    dc.drawCircle (halfWidth, halfHeight, 7);
    }


  /** Draw the numerals aroud the face. */
  function drawNumerals (dc)
    {
    dc.setColor (fgColour, Graphics.COLOR_TRANSPARENT);
    
    var wExtent = width / 2.3; 
    var hExtent = height / 2.3; 

    for (var i = 1; i <= 12; i++)
      {
      var angle = twoPi * i / 12.0; 
      var x = halfWidth + Math.sin (angle) * wExtent; 
      var y = halfHeight - Math.cos (angle) * hExtent; 
      dc.drawText (x, y, Graphics.FONT_TINY, i, 
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER); 
      }
    }


  /** Draw whatever information goes in the bottom of the watch face
      -- currently battey level */
  function drawDataString (dc)
    { 
    var x = halfWidth;
    var y = 3 * height / 4 - 4;

    var dataString = 
      (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";

    dc.setColor(fgColour, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, Graphics.FONT_TINY, dataString, 
        Graphics.TEXT_JUSTIFY_CENTER);
    }


  function drawHands (dc, clockTime)
    {
    dc.setColor (fgColour, bgColour);
    dc.setPenWidth (2);
    var w = dc.getWidth();
    var h = dc.getHeight();

    var hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
    hourHandAngle = hourHandAngle / (12 * 60.0);
    hourHandAngle = hourHandAngle * twoPi;

    var points = (generateHandCoordinates (screenCenterPoint, 
        hourHandAngle, 70, 20, 10, w, h));
    drawPolygon (dc, points);
    points = (generateHandCoordinates (screenCenterPoint, 
        hourHandAngle, 30, 20, 10, w, h));
    dc.fillPolygon (points);

    var minuteHandAngle = (clockTime.min / 60.0) * twoPi;
    points = generateHandCoordinates (screenCenterPoint, 
        minuteHandAngle, 92, 10, 8, w, h);
    drawPolygon (dc, points);
    points = generateHandCoordinates (screenCenterPoint, 
        minuteHandAngle, 30, 10, 8, w, h);
    dc.fillPolygon (points);
    }


  function drawDateString (dc) 
    {
    var x = halfWidth; 
    var y = height / 4;
    var info = Gregorian.info (Time.now(), Time.FORMAT_LONG);
    var dateStr = Lang.format ("$1$ $2$", [info.day_of_week.substring (0, 3), 
      info.day]);

    dc.setColor (fgColour, Graphics.COLOR_TRANSPARENT);
    dc.drawText (x, y, Graphics.FONT_TINY, dateStr, 
      Graphics.TEXT_JUSTIFY_CENTER);
    }


  /* Why the ConnectIQ API not seem to have such a basic drawing
     function ?? */
  function drawPolygon (dc, points)
    {
    dc.drawLine (points[0][0], points[0][1], points[1][0], points[1][1]);
    dc.drawLine (points[1][0], points[1][1], points[2][0], points[2][1]);
    dc.drawLine (points[2][0], points[2][1], points[3][0], points[3][1]);
    dc.drawLine (points[3][0], points[3][1], points[0][0], points[0][1]);
    }


  /** Work out the vertices of a watch hand of specified length
      and thickness. */
  function generateHandCoordinates (centerPoint, angle, handLength, 
      tailLength, width, dc_width, dc_height) 
    {
    // Ugh. The nasty scaling here is because I originally calculated
    //   specific pixel scaling based on a fixed screen size. Rather
    //   than redo all that, when I moved to supporting multiple screen
    //   sizes, I just rescaled everthing.
    handLength = handLength * dc_width / 240;
    tailLength = tailLength * dc_width / 240;
    width = width * dc_width / 240;
    var coords = [[-(width / 2), tailLength], [-(width / 2), -handLength], 
        [width / 2, -handLength], [width / 2, tailLength]];
    var result = new [4];
    var cos = Math.cos(angle);
    var sin = Math.sin(angle);

    for (var i = 0; i < 4; i += 1) 
      {
      var x = (coords[i][0] * cos) - (coords[i][1] * sin) + 0.5;
      var y = (coords[i][0] * sin) + (coords[i][1] * cos) + 0.5;

      result[i] = [centerPoint[0] + x, centerPoint[1] + y];
      }

    return result;
    }


  /** Not used. Definitely not used if we want to minimize 
      power consumption :) */
  function onPartialUpdate (dc) 
    {
    // Not implemented 
    }



  function onEnterSleep() 
    {
    WatchUi.requestUpdate();
    }


  function onExitSleep() 
    {
    }
  }

/** Not used in this application. */
class BAWFDelegate extends WatchUi.WatchFaceDelegate 
  {
  function onPowerBudgetExceeded (powerInfo) 
    {
    // Not implemented -- should never happen
    }
  }

