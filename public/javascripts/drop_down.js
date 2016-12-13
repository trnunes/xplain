/**
 * @author eduardo
 */
// Copyright 2006-2007 javascript-array.com

var timeout	= 500;
var closetimer	= 0;
var closetimermenu	= 0;
var ddmenuitem	= 0;
var opentimer = 0;
var menuitem =0;

// open hidden layer
function mopen(id)
{	
	// cancel close timer
	mcancelclosetime();

	// close old layer
	if(ddmenuitem) ddmenuitem.style.visibility = 'hidden';

	// get new layer and show it
	ddmenuitem = document.getElementById(id);
	ddmenuitem.style.visibility = 'visible';

}

function mopenmenu(id)
{	
	// cancel close timer
	mcancelclosetimemenu();

	// close old layer
	if(menuitem) menuitem.style.visibility = 'hidden';

	// get new layer and show it
	menuitem = document.getElementById(id);
	menuitem.style.visibility = 'visible';

}
// close showed layer
function mclose()
{	
	if(ddmenuitem) ddmenuitem.style.visibility = 'hidden';
}
function mclosemenu()
{

	if(menuitem) menuitem.style.visibility = 'hidden';
}

// go close timer
function mclosetime()
{
	closetimer = window.setTimeout(mclose, timeout);
}
function mclosetimemenu()
{
	closetimermenu = window.setTimeout(mclosemenu, timeout);
}
// go open timer
function mopentimemenu(id)
{
	opentimer = window.setTimeout( "mopenmenu(" + id + ")", timeout);
}

// cancel close timer
function mcancelclosetime()
{
	if(closetimer)
	{
		window.clearTimeout(closetimer);
		closetimer = null;
	}
}
function mcancelclosetimemenu()
{
	if(closetimermenu)
	{
		window.clearTimeout(closetimermenu);
		closetimermenu = null;
	}
}
//cancel open timer
function mcancelopentime()
{
	if(opentimer)
	{
		window.clearTimeout(opentimer);
		opentimer = null;
	}
}
// close layer when click-out
document.onclick = mclose; 
