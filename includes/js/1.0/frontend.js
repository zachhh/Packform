/**************************************************
 * frontend.js version 1.0
 *
 * This is BETA and is subject to change
 *
 * It expects JSON as the response
 *
 * This is for use with Packform.pm v1.00 or higher
 *
 **************************************************/

var jqXHR = null;

//var reserved = ['opts', 'type', 'name', 'val', 'value', 'prefix', 'handler',
//		'global', 'pluginattrs', 'suffix', 'itemsuffix', 'labelloc'];

var defaultsuffix = "";

var editorconfs = {};

// process the (parsed) json using jQuery to handle the dirty work since 
// writing javascript to deal with the DOM is painful if you want it to work
// in both IE and anything W3C compliant.
function process_response(data) {
	
	/***************** ERROR CHECKING ******************/
	// debugging stuff
	if (defined(data.dbg)) { $('div#pfui-details').html(data.dbg); $('div#pfui-details').show(); }
	// handle errors
	if (defined(data.err)) { 
		$('div.pfui-errormsg').html('<p class="pfui-errormsg">'+data.err+'</p>');
		return;
	}
	else { $('div.pfui-errormsg').empty(); }
	// mark up existing data by giving input errors.
	if (defined(data.inputerrs)) {
		for (var j = 0; j < data.inputerrs.length; j++) {
			var n = data.inputerrs[j].name;
			var v = data.inputerrs[j].value;
			set_input_postfix(n,v);
		}
		set_handlers();
		// no further processing since there was an error.
		return;
	}
	
	/*********** BUILD IT FROM THE GROUND UP ***********/
	
	if (defined(data.stickytop)) { $('#pfui-persistent-top').html(data.stickytop); }
	if (defined(data.stickybottom)) { $('#pfui-persistent-bottom').html(data.stickybottom); }
	
	// set title
	if (defined(data.title)) { $('h1#pfui-sandbox-title').html(data.title); }
	// set help message
	if (defined(data.help)) { $('div#pfui-details').html(data.help); }
	// remove things from the page if asked
        if (defined(data.xalltargets)) { remove_all_targets(); }
	else if (defined(data.xtargets)) { remove_targets(data.xtargets); }
	if (defined(data.xallinputs)) { remove_all_inputs($('form#packform')); }
	if (defined(data.xinputs)) { remove_inputs($('form#packform'),data.xinputs); }
	if (defined(data.xallpars)) { $('form#packform').find('.pfui-p-input').remove(); }
	if (defined(data.xallbuttons)) { remove_buttons($('div#accordion')); }
	if (defined(data.xdups)) {
		for (var j = 0; j < data.inputs.length; j++ ) {
			remove_dups($('form#packform'),data.inputs[j].name);
		}
	}
	
	if (defined(data.inputs) && data.inputs.length && !defined(data.target)) {
		$('.pfui-errormsg').html('No target for response.');
		return;
	}
	if (!defined(data.target)) { return; }
	
	// variables needed along the way
	var div = null;
	var create = false;
	
	if (defined(data.defsuffix)) { defaultsuffix = data.defsuffix; }
	
	// if there is a target already, use it
	if ($('div#'+data.target).length) {
		div = $('div#'+data.target);
		
		// remove from target if requested
		if (defined(data.xallbuttonstarget)) { remove_buttons(div); }
		if (defined(data.xallparstarget)) { div.find('.pfui-p-input').remove(); }
		if (defined(data.xallinputstarget)) { remove_all_inputs(div); }
		else if (defined(data.xinptarget)) { remove_inputs(div,data.xinptarget); }
		if (defined(data.xdupstarget)) {
			for (var j = 0; j < data.inputs.length; j++ ) {
				remove_dups(div,data.inputs[j].name);
			}
		}
	}
	// otherwise we have to create it
	else {
		create = true;
		div = $('<div>').attr({'id': data.target});
		// add the ARIA attributes
		div.attr('aria-live','polite');
		div.attr('aria-relevant','text');
	}
	// populate this data in a span tag
	var s = $('<span>');
	// if there is a message, add it in a span
	if (defined(data.message)) {
		var msg = $('<span class="pfui-message">');
		msg.html(data.message);
		msg.append('<br />');
		s.append(msg);
	}
	
	// add the inputs to the span
	// the number of inputs added is not used, but may be in the future.
	var ninp = add_inputs(data.inputs,s,div);
	
	// add ARIA attributes to the span
	s.attr('aria-atomic','true');
	s.attr('aria-live','polite');
	
	// put the span in the div
	div.append(s);
	// if we are creating this add it to the accordion
	if (create) { build_block(div,data.alt); }
	else if (defined(data.heading)) { div.prev('h3').html(data.heading); }
	else if (defined(data.alt)) { div.prev('h3').html(data.alt); }
	// reset the accordion
	$('div#accordion').accordion( "destroy" );
	$('div#accordion').accordion( {heightStyle: "content", icons: false, collapsible: true, tabs: 'h3', active: -1 });
	
	// convert handler attributes to actual handlers
	set_handlers();
	
	set_datepickers(data.inputs);
	
	set_prefix_width(div);
	
	// bind wysiwyg AFTER all the dom manipulation, or else everything gets trashed.
	$('[wysiwyg]').each(function() {
		$(this).tinymce( editorconfs[$(this).attr('id')] );
	});
}

function add_inputs(objs,elt,div) {
	if (!defined(objs)) { return 0; }
	var len = objs.length;
	var added = 0;
	
	for (var j = 0; j < len; j++) { // process each object.
		var obj = objs[j];
		if (!defined(obj['type'])) { continue; }
		var typ = obj['type'].toLowerCase();
		if (typ == 'text') { added += add_text_input(obj,elt); }
		else if (typ == 'textarea' || typ == 'textbox') { added += add_textarea(obj,elt); }
		else if (typ == 'select') { added += add_select(obj,elt); }
		else if (typ == 'radio') { added += add_radio(obj,elt); }
		else if (typ == 'button' || typ == 'submit') { add_button(obj,elt); }
		else if (typ == 'hidden') { add_hidden(obj,elt); }
		else if (typ == 'checkbox') { added += add_checkbox(obj,elt); }
		else if (typ == 'password') { added += add_password(obj,elt); }
		else if (typ == 'paragraph') { added += add_paragraph(obj,elt); }
		else if (typ == 'date') { added += add_date(obj,elt); }
		else if (typ == 'wysiwyg') { added += add_wysiwyg(obj,elt); }
		else if (typ == 'modal') { added += add_modal(obj,elt); }
	}
	return added;
}

function set_prefix_width(div) {
	var w = 0;
	// if we somehow get here while the object is not visible, do not set the width back to zero.
	if (! $(div).is(':visible') ) { return; }
	div.find('.pfui-prefix span').each( function() {// find max width
		if ($(this).width() > w) { w = $(this).width(); }
	});
	w = w + 5; 					// set 5 pixels extra for padding
	div.find('.pfui-prefix').css('width', w+'px'); 	// set all of their widths
}

function set_datepickers(objs) {
	var len = objs.length;
	for (var j = 0; j < len; j++) {
		var obj = objs[j];
		if (obj.type && obj.type.toLowerCase() == 'date' && defined(obj.name) &&
		    obj.name != null && obj.name != '' ) {
			$('input#'+obj.name).datepicker(obj.pluginattrs);
		}
	}
}

//function attrs_as_object(ob) {
//	var args = {};
//	for (var key in ob) { args[key] = ob[key]; }
//	for (var j=0; j < reserved.length; j++) { delete args[reserved[j]]; }
//	return args;
//}

function set_input_postfix(name,txt) {
	if (! (name && txt) ) { return; }
	// build postfix
	var pf = ' <span class="pfui-postfix-err">&nbsp;'+txt+'</span>';
	//pf.append(txt);
	// get the offending element and tack on the span after it.
	$('form#packform').find('input, select, textarea, .pfui-radio-wrapper').filter('[type!=radio][name='+name+']').after(pf);
}

function remove_targets(targets) {
	if (! targets.length ) { return; }
	
	// kill accordion since we're modifying it
	$('div#accordion').accordion( "destroy" );
	// remove the targets
	for (var j = 0; j < targets.length; j++) {
		var id = targets[j];
		$('div#accordion').find('div#'+id).each(function() {
			$(this).prev('h3').remove();
			$(this).remove();
		});
	}
	// redefine accordion, but don't specify what to show.
	$('div#accordion').accordion( {heightStyle: "content", icons: false, collapsible: true, tabs: 'h3' });
}

function remove_all_targets() {
    $('div#accordion').accordion( "destroy" );
    $('div#accordion').html('');
    $('div#accordion').accordion( {heightStyle: "content", icons: false, collapsible: true, tabs: 'h3' });
}

function remove_inputs(div,inputs) {
	for (var j = 0; j < inputs.length; j++) {
		div.find('[name="'+inputs[j]+'"]').each( function() { remove_input(this); });
	}
}

function remove_all_inputs(from) {
	from.find('input, select, textarea, .pfui-radio-wrapper, .pfui-p-input').each(
		function() { remove_input(this); }
	);
	//from.find('.pfui-p-input').each(function() { remove_input(this); });
}

function remove_buttons(div) {
	div.find('[type="submit"],[type="button"]').each(function() { remove_input(this); });
}

// remove an input along with it's prompt
function remove_input(elt) {
	cleanup_prefix(elt); // remove prefix
	clean_tailing(elt);  // remove tailing BR or whatever
	var par = $(elt).parent(); // remember parent
	$(elt).remove(); // remove element
	// get rid of leading BR tags from the element.
	var fc = null;
	while ( (fc = $(par).find(':first-child').get(0)) && fc.tagName == 'BR' ) { $(fc).remove(); }
}

// build a new accordion pane
function build_block(div,alt) {
	var str = "";
	if (defined(alt) && alt != '') { str = alt; }
	var h3 = $('<h3>');
	h3.html(str);
	// add the tags
	$('div#accordion').append(h3);
	$('div#accordion').append(div);
}

function cleanup_prefix(elt) {
	// do not clean up a prefix for a hidden element.
	if ($(elt).attr('type') == 'hidden') { return; }
	// get rid of leading info
	var prv = $(elt).prev();
	while (prv.is('.pfui-prefix,.pfui-radio-label')) { prv.remove(); prv = $(elt).prev(); }
}

// Remove BR or whatever is the spacer after the element
function clean_tailing(elt) {
	if ($(elt).attr('type') == 'hidden') { return; }
	var nxt = $(elt).next();
	while ( nxt.is('.pfui-post-input,.pfui-radio-suff,script')) { nxt.remove(); nxt = $(elt).next(); }
}

function remove_dups(div,name) {
	if (! defined(name) || name == null || name == '') { return; }
	div.find( '[name="'+name+'"]' ).each(function() { remove_input(this); });
}

function set_val(data,obj) {
	if (defined(data.val)) { obj.val(data.val); }
	else if (defined(data.value)) { obj.val(data.value); }
	else { obj.val(""); } // needed for IE
}

function set_attrs(data,obj) {
	if (! defined(data.attrs)) { return; }
	var attrs = data.attrs;
	for (var key in attrs) { obj.attr(key,attrs[key]); }
}

function add_text_input(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var inp = $('<input type="text" name="'+ob.name+'" id="text-'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.handler)) {
		inp.keyup(function(evt) { if (evt.keyCode == 13) { change_handler(this); } });
	}
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_paragraph(ob,elt) {
	if (!defined(ob.value)) { return 0; }
	var inp = $('<p>');
	inp.addClass('pfui-p-input');
	inp.append(ob.value);
	if (defined(ob.name) && ob.name != null && ob.name != '') { inp.attr('name',ob.name); }
	if (defined(ob.handler)) { inp.click(function() { change_handler(this); }); }
	set_attrs(ob,inp);
	elt.append(inp);
	return 1;
}

// adds a modal popup.
function add_modal(ob,elt) {
	if (!defined(ob.value)) { return 0; }
	var inp = $('<div>');
	inp.addClass('pfui-modal');
	if (defined(ob.name)) {	inp.attr("name",ob.name); }
	inp.append(ob.value);
	// set default options
	var modalopts = { modal: true, position: { my: "center", at: "center", of: window } };
	if (defined(ob.pluginattrs)) {
		for (var key in ob.pluginattrs) { modalopts[key] = ob.pluginattrs[key]; }
	}
	// have to add this handler here before the DOM gets modified, or else the
	// event is not captured.
	inp.on( "dialogclose", function(evt,ui) { $(this).dialog('destroy').remove(); });
	elt.append(inp);
	inp.dialog(modalopts);
	return 1;
}

function add_password(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var inp = $('<input type="password" name="'+ob.name+'" id="password-'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.handler)) {
		inp.keyup(function(evt) { if (evt.keyCode == 13) { change_handler(this); } });
	}
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_textarea(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var inp = $('<textarea name="'+ob.name+'" id="textarea-'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.handler)) { inp.change(function() { change_handler(this); }); }
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_wysiwyg(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var inp = $('<textarea name="'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.handler)) { inp.change(function() { change_handler(this); }); }
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	var tinyopts = {
		script_url: '/includes/js/tinymce/3.5.8/jscripts/tiny_mce/tiny_mce.js',
		//mode: "exact",
		//elements : "richText",
		mode: 'none',
		theme : "advanced",
		plugins : "autolink,lists,spellchecker,style,table,save,advhr,advlink,iespell,inlinepopups,insertdatetime,preview,searchreplace,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template",
		theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,formatselect,fontselect,fontsizeselect,forecolor",
		theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,help,|,insertdate,inserttime,preview",
		theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,iespell,advhr",
		theme_advanced_buttons4 : "spellchecker,|,cite,abbr,acronym,del,ins,|,visualchars,nonbreaking,blockquote",
		theme_advanced_toolbar_location : "top",
		theme_advanced_toolbar_align : "left",
		theme_advanced_statusbar_location : "bottom",
		theme_advanced_resizing : true
	};
	// override defaults or add options
	if (defined(ob.pluginattrs)) {
		for (var key in ob.pluginattrs) { tinyopts[key] = ob.pluginattrs[key]; }
	}
	inp.attr('wysiwyg', '1');
	// store it in our hash
	editorconfs[ob.name] = tinyopts;
	return 1;
}

function add_select(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var opts = ob.opts;
	if (!defined(opts) || opts == null || opts.length == 0) { return 0; }
	var inp = $('<select name="'+ob.name+'" id="select-'+ob.name+'">');
	var sel = [];
	if (defined(ob.val)) { sel = sel.concat(ob.val); }
	else if (defined(ob.value)) { sel = sel.concat(ob.value); }
	for (var j =0; j< opts.length; j++) {
		var opt = opts[j];
		if (!defined(opt.val) || !defined(opt.txt)) { continue; }
		var itm = $('<option>');
		itm.text(opt.txt);
		itm.val(opt.val);
		inp.append(itm);
	}
	// have to set attrs so jQuery knows it is multiple select.  Then we can set the value.
	set_attrs(ob,inp);
	// set the value(s) of the select
	if (sel.length) { inp.val(sel); }
	
	if (defined(ob.handler)) {
		inp.change(function() { change_handler(inp); });
	}
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_checkbox(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var inp = $('<input type="checkbox" name="'+ob.name+'" id="checkbox-'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.handler)) { inp.change(function() { change_handler(this); }); }
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_radio(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	var opts = ob.opts;
	if (!defined(opts) || opts == null || opts.length == 0) { return 0; }
	var sel = '';
	if (defined(ob.val)) { sel = ob.val; }
	if (defined(ob.value)) { sel = ob.value; }
	var loc = 'before'
	if (defined(ob.labelloc)) { loc = ob.labelloc; }
	var itemsuff = '';
	var handle = false;
	if (defined(ob.handler)) { handle = true; }
	if (defined(ob.itemsuffix)) { itemsuff = ob.itemsuffix; }
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	var p = $('<p name="'+ob.name+'">');
	p.addClass('pfui-radio-wrapper');
	for (var j = 0; j < opts.length; j++) {
		var opt = opts[j];
		if (!defined(opt.val) || !defined(opt.txt)) { continue; }
		var inp = $("<input type='radio' name='"+ob.name+"' value='"+opt.val+"' id='radio-"+ob.name+"-"+opt.val+"'>");
		if (handle) { inp.change(function() { change_handler(this); }); }
		if (opt.val == sel) { inp.attr({'checked': 'checked'}); }
		// IE doesn't handle the span correctly, so we have to hard code it and append the HTML
		var prmpt = '<span class="pfui-radio-label"><label for="radio-'+ob.name+'-'+opt.val+'">'+opt.txt+'</label></span>';
		
		// add things in the specified order.
		if (loc == 'after') {
			p.append(inp);
			p.append(prmpt);
		}
		else {
			p.append(prmpt);
			p.append(inp);
		}
		if (itemsuff != '') {
			p.append('<span class="pfui-radio-suff">'+itemsuff+'</span>');
		}
	}
	elt.append(p);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function add_hidden(ob,elt) {
	if (!defined(ob.name)) { return; }
	var inp = $('<input type="hidden" name="'+ob.name+'">');
	set_val(ob,inp);
	if (defined(ob.global)) { $('form#packform').prepend(inp); }
	else { elt.append(inp); }
}

function add_button(ob,elt) {
	var inp = null;
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	if (defined(ob.name)) { inp = $('<input type="button" name="'+ob.name+'">'); }
	else { inp = $('<input type="button">'); }
	set_val(ob,inp);
	inp.click(function() { change_handler(this); });
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
}

function add_date(ob,elt) {
	if (!defined(ob.name)) { return 0; }
	if (defined(ob.prefix)) { elt.append(get_prefix(ob.prefix)); }
	var inp = $('<input type="text" name="'+ob.name+'" id="'+ob.name+'">');
	set_val(ob,inp);
	set_attrs(ob,inp);
	if (defined(ob.handler)) {
		inp.keyup(function(evt) { if (evt.keyCode == 13) { change_handler(this); } });
	}
	elt.append(inp);
	elt.append(get_suffix(ob.suffix));
	return 1;
}

function defined(obj) { return typeof(obj) != 'undefined' ? 1 : 0; }

// construct for the handler.
function change_handler(e) {
	// Abort active transaction  
	if (jqXHR != null) { jqXHR.abort(); }
	
	/* In preparation for submitting the form, we need to remove all
	   data AFTER the changed option. */
	
	remove_after(e);
	
	// get the form data.
	var dat = $('form#packform').serialize();
	var $e = $(e);
	// include information about the button if that was the trigger.
	if ($e.is(':button')) {
		var name = $e.attr('name');
		var val = $e.attr('value');
		if (name != null && val != null) { dat = dat + '&' + name + '=' + val; }
	}
	
	// clean up prior messages
	$('div.pfui-errormsg').html("");
	$('div#pfui-details').html("");
	$('span.pfui-postfix-err').remove();
	
	// make ajax call
	jqXHR = $.ajax({ 
		data: dat,
		context: this,
		success: function(responseData) { process_response(responseData); jqXHR = null; }
	});
	// return false so we don't submit the form.
	return false;
}

function remove_after(e) {
	// kill accordion since we're modifying it
	$('div#accordion').accordion( "destroy" );
	// get container div
	var d = $(e).closest('div');
	// remove all accordion elements after this one
	while (d.next('div, h3').length) { d.next('div, h3').remove(); }
	// remove all sibling spans as they may have info that depends on this choice
	var s = $(e).closest('span');
	while (s.next('span').length) { s.next('span').remove(); }
	// rebuild the accordion
	$('div#accordion').accordion( {heightStyle: "content", icons: false, collapsible: true, tabs: 'h3', active: -1 });
	return false;
}

function submits_to_buttons() {
	$('form#packform').find('input[type="submit"]').each(function() {
		var val = $(this).val();
		if (val == null || val == '') { val = 'Submit'; }
		var btn = $('<input type="button" value="' + val + '">');
		var name = $(this).attr('name');
		if (name == null || name == '') { name = 'Submit'; }
		if (name != null) { btn.attr('name', name); }
		btn.click(function() { change_handler(btn); });
		$(this).replaceWith(btn);
	});
}

// convert 'handler' attributes to actual handlers.
function set_handlers() {
	var handled = $('form#packform').find('[handler]');
	handled.filter('select,[type="radio"],[type="checkbox"],textarea').change( function() { change_handler($(this)); });
	handled.filter('[type="text"],[type="password"]').keyup(function(evt) { if (evt.keyCode == 13) { change_handler($(this)); } });
	handled.filter('.pfui-p-input,[type="submit"],[type="button"]').click(function() { change_handler($(this)); });
	handled.removeAttr('handler');
}

// need the entire object so we can be good about providing labels for ADA considerations
function get_prefix(obj) {
	var str = obj.prefix;
	var pfx = $('<p class="pfui-prefix">');
	var spn = $('<span>');
	var label = get_label(obj);
	if (defined(label)) {
		label.append(str);
		spn.append(label);
	}
	else {
		spn.append(str);
	}
	pfx.append(spn);
	return pfx;
}

function get_label(obj) {
	var type = obj.type;
	var label
	// text, textarea, password, select, checkbox, date get a label for the input
	if (type == 'text' || type == 'textarea' ||
	    type == 'password' || type == 'date' ||
	    type == 'select' || type == 'checkbox')
	{
		label = $('<label>');
		var tag = type + '-' + obj.name;
		if (type == 'date') { tag = obj.name; }
		label.attr('for', tag);
	}
	return label;
}

function get_suffix(html) {
	var ns = $('<span>');
	ns.addClass('pfui-post-input');
	if (defined(html)) { ns.append(html); }
	else if (defaultsuffix != '') {  ns.append(defaultsuffix); }
	else { return ""; }
	return ns;
}


$(document).ready( function() {
	// set ajax error handler
	$(document).ajaxError( function(e,xhr,settings,thrown) {
		// ignore aborts.
		if (! xhr.getAllResponseHeaders()) { return; }
		// Give them an error message otherwise.
		$('div.pfui-errormsg').html(xhr.responseText+'<p>Please reload the page if the problem continues.</p>');
        });
	// set some of the ajax defaults
	$.ajaxSetup({cache: false, dataType: "json", type: "POST"});
	// prevent actual submission of the form if javascript is enabled
	$('form#packform').submit(function() { return false; });
	$(function() {
		// set up style bindings for ajax running.
		$("html").bind("ajaxStart", function() { $(this).addClass('busy'); })
		.bind("ajaxStop", function() { $(this).removeClass('busy'); });
		// make the accordion
		$('div#accordion').accordion( {heightStyle: "content", icons: false, collapsible: true, tabs: 'h3' });
		$('div#accordion div').each(function() { set_prefix_width($(this)); });
	});
	submits_to_buttons();
	set_handlers();
}); // end document.ready
