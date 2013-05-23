package Packform::Input::Plugin;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

our @ISA = qw(Packform::Input);

=head1 NAME

Packform::Input::Plugin - The class of wysiwyg, date and modal inputs for Packform.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This gives extended functionality to the inputs that are actuall some kind of JavaScript widget.

The "wysiwyg" input type is actually a TinyMCE widget, which falls back to a simple textarea if the
javascript is not there.  This provides a "what you see is what you get" HTML editor.  It is
currently buggy, in that when the panel containing it collapses, the data is lost.  It requires
jumping through hoops to keep track of it.  For example, when you do have it, store it in a hidden
input for the rest of the session.

The "date" input type is a jQuery-ui datepicker widget.  The fallback is a simple text input if the
widget is not available.

The "modal" widget is a jQuery-ui dialog that is set as modal.  The fallback is a simple paragraph
input if the widget is not available.

Basic usage:

	use Packform;
	my $ui = Packform->new();
	
	# Add a jQuery-ui datepicker widget to the form
	my $date_input = $ui->add_date('date');
	# modify the $date_input
	
	my $editor = $ui->add_wysiwyg('html');
	# modify the $editor
	
	my $modal = $ui->add_modal("This is the text in the overlay");
	# modify $modal
	
	print $ui->json_output();

=head1 WARNING

These plugins rely on jQuery widgets or jQuery plugins that may not be accessible.  Much work has
gone in to making the interface compliant by following the WAI-ARIA recommendation (as of May
2013).  The jQuery widget at the heart of Packform is the accordian, which is compliant.
However, the datepicker is not fully compliant (though it is undergoing an rewrite).  The modal
dialog is known to have problems with screen readers (though this seems to be fixed with some of
the newer versions of jQuery and the jQuery UI).  Finally, the tinyMCE plugin may not be accessible
due to its use of an iframe, among other things.

If you require accessibility, it is your responsibility to ensure compliance.  You may want to patch
the frontend.js file to modifiy these widgets upon creation.  Or, you may want to just avoid these
plugins entirely.  
	
=head1 METHODS

This is a subclass of Packform::Input, so all of the methods in Packform::Input are available to
these objects.  The primary functionality specific to these is the configuration of the plugin
itself.  To that end, a set_plugin_attrs method is available.  

=over 4

=item as_html( );

This returns the HTML for the plugin, including any JavaScript necessary for instanciating the
widget.  It should probably not be called directly unless you really need just the HTML for the
particular input item.  Its primary purpose is to provide the HTML when html_output() is called
on the Packform base object.  

=cut

sub as_html {
	my $obj = shift;
	my $type = $obj->{type};
	my $prefix = $obj->_html_prefix;
	my $suffix = $obj->_html_suffix;
	my $attrs = $obj->_html_attrs;
	my $name = $obj->{name};
	my $val = $obj->get_value();
	my $plugin_attrs = encode_json $obj->{pluginattrs};
	my $html = "";
	if ($type eq 'date') {
		$html .= $prefix . '<input type="text" name="' . $name . '" id="' . $name . '"';
		$html .= ' value="' . $val . '"' . $attrs . ">\n";
		$html .= "<script type=\"text/javascript\"> \$('input#$name').datepicker($plugin_attrs); ";
		$html .= "</script>\n";
		$html .= $suffix;
	}
	elsif ($type eq 'wysiwyg') {
		$html .= $prefix . '<textarea name="' . $name . '"' . $attrs . ">\n";
		$html .= $val // "";
		$html .= "</textarea>" . $suffix;
		$html .= "<script type=\"text/javascript\"> \$('textarea#$name').tinymce($plugin_attrs); ";
		$html .= "</script>\n";
	}
	elsif ($type eq 'modal') {
		my $rand = int(rand(2**30));
		$html .= '<div class="pfui-modal" modaltag="'.$rand.'">';
		$html .= "$val</div>";
		$html .= "<script type=\"text/javascript\">\n";
		$html .= "
		$(docuement).ready(function{
			\$('[modaltag=$rand]).dialog($plugin_attrs);
			\$('[modaltag=$rand]).on( \"dialogclose\", function(evt,ui) {
				\$(this).dialog(\"destroy\").remove();
			});
		});
		</script>\n";
	}
	return $html;
}

=item set_plugin_attrs( %attrs ) or set_plugin_attrs( attr1 => value1, attr2 => value2, ...);

The attributes set here will be used in the construction or configuration of the plugin widget.
For all of these input types, the plugin attributes are used at the initialization of the widget.

The setting of attributes for a given object is cumulative.  That is, you can make multiple calls
to it, and all of them take effect.  However, if you set an attribute more than once, it is the
LAST value set that is realized.  

For the wysiwyg, the options are realized as: $(textarea#name).tinymce(plugin_attributes)

For date pickers, they are realized as: $(element).datepicker(plugin_attributes);

For the modal dialog, it is: $(element).dialog(plugin_attributes);

The wysiwyg editor has an attribute script_url that should point to the tiny_mce.js file.  This is
NOT the tinymce jquery plugin script that is needed for initialization.  That's to provide the
method on the jQuery object.  This is the tiny_mce backend for the widget.  In general, it's in the
same folder as the jquery.tinymce.js file.  It defaults to the tiny_mce.js file in the same folder as
the jquery.tinymce.js file set with $ui->set_tinymce_file.  If this was NOT set before creating a
wysiwyg input, it will have NO script_url attribute.  It is your responsibility to then set this
attribute to an appropriate value.  If this attribute is not set, it is almost certain to break.

NOTE: There are certain attributes included by default, such as 'modal' for the dialog.
You can overwrite them simply by providing your own value for the attribute.  So, if you don't
want your dialog to be modal, simply $modal->set_plugin_attrs( 'modal' => 'false' );

NOTE: Currently, any "attribute" that requires a function is untested and is not guaranteed to work.
For instance, the beforeShowDay attribute of the datepicker takes a function as the "value" (if you
were going to, say, omit holidays).  These are not guaranteed to function properly, if at all.

Attributes accepting an object rather than a scalar should provide references to the object.  That is,
if an attribute wants an array, provide an array reference.  If it wants some more complicated structure,
provide the structure as references.

NOTE: Anything requiring a JavaScript object (like a function, Date or jQuery object) is unlikely to
work, and is to be used AT YOUR OWN RISK.  You would likely have to modify the as_html method for
the specific type of widget to provide the necessary JavaScript, or the frontend.js file.  

=cut

sub set_plugin_attrs {
	my $self = shift;
	unless (scalar @_ % 2 == 0) {
		carp "Bad call to set_plugin_attrs";
		return $self;
	}
	$self->{pluginattrs} = { %{$self->{pluginattrs}}, ( @_ ) };
	$self;
}

=item get_plugin_attrs( );

This returns a hash containing the plugin attributes set.  

=cut

sub get_plugin_attrs { return %{shift->{pluginattrs}}; }

######################
## INTERNAL
######################

# Use the PARENT's info to configure the input object.
sub _bootstrap {
	my ($self,$packform) = @_;
	unless ($self->{type} && $self->{type} eq 'wysiwyg') { return $self; }
	my $url = $packform->{config}->{tinymce};
	return $self unless ($url);
	my $path = "";
	if ($url =~ m/^(.*+)\/.*$/) { $path = $1; }
	$self->set_plugin_attrs( 'script_url' => "$path/tiny_mce.js" );
	$self;
}

sub _init_defaults {
	my $self = shift;
	$self->{pluginattrs} //= {};
	my %existing = %{$self->{pluginattrs}};
	# These get pluginattrs (if not already there)
	$self->{pluginattrs} //= { %existing };
	my $type = $self->{type};
	
	
	# The "name" of the modal window is the title, unless the title exists
	if ($type eq 'modal') {
		# Set the modal attribute, if not already set.
		$self->{pluginattrs}->{modal} //= 'true';
		# Convert name to title
		if (exists $self->{name} and ! exists $self->{title}) {
			$self->{pluginattrs}->{'title'} = $self->{name};
			delete $self->{name};
		}
	}
	# Initialize the pluginattrs with the defaults for the type.
	if ($type eq 'wysiwyg') {
		
		$self->{pluginattrs} = { 
			'theme' => "advanced",
			'plugins' => "autolink,lists,spellchecker,style,table,save,advhr,advlink,iespell,inlinepopups,insertdatetime,preview,searchreplace,contextmenu,paste,directionality,fullscreen,noneditable,visualchars,nonbreaking,xhtmlxtras,template",
			'theme_advanced_buttons1' => "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,formatselect,fontselect,fontsizeselect,forecolor",
			'theme_advanced_buttons2' => "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,help,|,insertdate,inserttime,preview",
			'theme_advanced_buttons3' => "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,iespell,advhr",
			'theme_advanced_buttons4' => "spellchecker,|,cite,abbr,acronym,del,ins,|,visualchars,nonbreaking,blockquote",
			'theme_advanced_toolbar_location' => "top",
			'theme_advanced_toolbar_align' => "left",
			'theme_advanced_statusbar_location' => "bottom",
			'theme_advanced_resizing' => 'true',
			# Theirs get appended to replace any defaults
			%existing
		};
	}
	# date has no default attributes
	$self;
}

=back

=head1 SEE ALSO

The "modal" inputs are jQuery dialogs, and the documentation can be found at:
http://api.jqueryui.com/dialog/

The "date" input is a jQuery datepicker, with documentation at:
http://api.jqueryui.com/datepicker/

The "wysiwyg" input is a tinymce editor, with documentation at:
http://www.tinymce.com/wiki.php

Packform::Input

Packform

=head1 AUTHOR

Zachary Hanson-Hart, C<< <zachhh at temple.edu> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Packform::Input::Plugin

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Zachary Hanson-Hart.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of Packform::Input::Plugin
