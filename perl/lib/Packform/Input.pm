package Packform::Input;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

# packages for the various input types.
use Packform::Input::Option;
use Packform::Input::Plugin;
use Packform::Input::Simple;

=head1 NAME

Packform::Input - Objects representing inputs sent back to the page for use with Packform.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


my @known_types = qw(text textarea select radio hidden submit checkbox password paragraph date modal wysiwyg);
my @has_label = qw(text textarea select checkbox password date);
my %label_hash = map { $_ => undef } @has_label;
my @attributes = qw(name value prompt suffix global labelloc opts sort pluginattrs attrs itemsuffix);
my %known_attrs = map { $_ => undef } @attributes;


=head1 SYNOPSIS

	use Packform;
	my $ui = Packform->new('target');
	my $select = $ui->add_select('selectbox','this one','Pick one: ');
	$select->add_options({'this one' => 'This one!', 'that one' => 'NOT ME'});
	$ui->add_submit();
	# Print the HTML for the sandbox portion only.
	print $ui->html_output();
	# or, if you are writing to the front-end:
	print $ui->json_output();

=head1 DESCRIPTION

This is the parent of all of the input types, and provides methods to get/set the name, value prompt,
suffix and HTML attributes for any input element.  The methods are set_* and get_* where * is one of
the aforementioned attributes.  

Use of the new constructor directly is not advised.  
	
=head1 CONSTRUCTOR

=over 4

=item new(class, type, b<args> );

Create an input of the given type with the parameters given by args.  The parameters depend on the type.
This SHOULD NOT be used directly.  Rather, use the new_* and add_* methods in Packform.

=back
=cut

sub new {
	my $class = shift;
	my $type = shift;
	# Check type
	unless (scalar(grep { lc $_ eq lc $type } @known_types)) { carp "Unknown type: $type"; return; }
	# Build base
	my $self = { 'type' => $type, _get_args(@_) };
	
	# Correct for alternative calling styles
	if ($type eq 'submit' or $type eq 'paragraph' or $type eq 'modal') {
		if (_has_name_not_value($self)) {
			$self->{value} = $self->{name};
			delete $self->{name};
		}
	}
	
	# Bless according to type
	if (_is_plugin($type)) { bless($self, $class."::Plugin"); }
	elsif (_is_option($type)) { bless ($self, $class."::Option"); }
	else { bless ($self, $class."::Simple"); }
	# Make sure required attributes are present
	my $e;
	($e = _carp_required_attributes($self)) && carp $e;
	# Set up defaults
	$self->_init_defaults();
	return $self;
}


=head2 Methods

The following methods are available to all Packform::Input::* objects.  Note, however, that not
every input type will be affected by the methods.  Notably, paragraphs, hidden inputs and modal
overlays have no equivalent of prompt or suffix.  Though they can be set, they will be ignored
by the front end.

These are best demonstrated with an

B<Example:>

	my $ui = Packform->new('target');
	my $inp = $ui->add_text('txt');
	# Give it a default value
	$inp->set_value('Text goes here');
	# Change the name (because you can, not because you should)
	$inp->set_name('newtxt');
	# set prompt
	$inp->set_prompt('Enter some text: ')
	# set suffix
	$inp->set_suffix('enter to my left<br />');
	
	# Build a select input with given name and prompt
	my $sel = $ui->add_select('select',undef,'Pick some options');
	# Print the things
	print "Value: '" . $sel->get_value ."'\n";
	print "Prompt: '" . $sel->get_prompt ."'\n";
	# Note, $sel->get_value will return undef.
	# Set some attributes (multiple, and size)
	$sel->set_attrs('multiple' => 'multiple', 'size' => 6);
	# Add a lot of options
	my $opts = [ qw(first second third fourth fifth sixth) ];
	$sel->add_options($opts);
	my $selected = [$opts->[1], $opts->[3], $opts->[5]];
	$sel->set_value($selected);
	
	# Build a simple select input that is not multi-valued
	# and give it a default value.
	$sel = $ui->add_select('select2',undef,'Pick one: ');
	$sel->add_options($opts);
	$sel->set_value('fourth');
	
	...

See the comments for set_value about using an array reference as the value.  	

=head3 Setters

=over 4

=item set_value( value );

The setter for the value attribute.  The setter takes either a single value, or an
array reference.  The only time an array reference is acceptable is when the input is a select
input.  In this case, if you give it the multiple="multiple" attribute, then all of the values
in the array reference will be selected.  If it is not given the multiple attribute, then the
last in the list will be the value.  In every other case, you should use a scalar value.

=cut

# Set the value of the input.
sub set_value { return _set_attr('value',@_); }


=item set_name( name );

Sets the name of the input to the given name.

=cut

sub set_name { return _set_attr('name',@_); }


=item set_prompt( prompt );

Sets the prompt of the input to the given text.  This is ignored for hidden, paragraph and modal
inputs.

=cut

sub set_prompt { return _set_attr('prompt',@_); }


=item set_suffix( suffix );

Sets the suffix of the input to the given value.  This is ignored for hidden, paragraph and modal
inputs.

=cut

sub set_suffix { return _set_attr('suffix',@_); }

=item set_attrs( key1 => value1, key2 => value2, ... ); or set_attrs( %hash );

In the end, these are HTML input elements.  We need a way to set the HTML attributes of the form
elements, and this is it.  For setting attributes for a plugin object (date, modal, wysiwyg), see
Packform::Input::Plugin.

Two common things are to set the size of something, or to make a multiple select input.

B<Example:>

	my $ui = Packform->new("target");
	my $multisel = $ui->new_select("multselect","temporary value","Select some: ");
	my @options = qw(first second third fourth fifth);
	my @default = qw(second fifth);
	$multiselect->add_options( \@options );
	$multiselect->set_attrs( 'multiple' => 'multiple', 'size' => scalar(@options) );
	$multiselect->set_value( \@default );
	
	my $txt = $ui->new_text('txt');
	$txt->set_attrs( 'size' => 30, 'maxlength' => '30');
	
	$ta = $ui->new_textarea('txtarea');
	$ta->set_attrs( 'rows' => 10, 'cols' => 50 );

	...

All of these will be incorporated in the resulting HTML tag.  

=back
=cut

sub set_attrs {
	my $self = shift;
	unless (scalar @_ % 2 == 0) { carp "Bad call to set_attrs"; return $self; }
	if (exists $self->{attrs}) {
		$self->{attrs} = { %{$self->{attrs}}, ( @_ ) };
	}
	else {
		$self->{attrs} = { ( @_ ) };
	}
	$self;
}

# Getters


=head3 Getters

There is also a way to retrieve all of the information that we set.

=over 4

=item get_value();

Returns the current default value for the input.  NOTE: if you provided an array reference as the
value, you will be getting an array reference back!

=cut

sub get_value { return shift->{value}; }

=item get_name();

Returns the name of the input field.

=cut

sub get_name { return shift->{name}; }

=item get_prompt();

Returns the prompt for the input field.

=cut

sub get_prompt { return shift->{prompt}; }

=item get_suffix();

Returns the suffix for the input field.

=cut

sub get_suffix { return shift->{suffix}; }

=item get_attr( attribute_name );

Returns the value of the attribute given by attribute_name.

B<Example:>

	my $ui = Packform->new('target');
	my $text = $ui->add_text('txt');
	$txt->set_attrs(size => '40', maxlength => '60');
	print "Max length is " . $txt->get_attr('maxlength');

=cut

sub get_attr { my ($self,$att) = @_; return $self->{attrs}->{$att}; }

=item get_attrs();

Returns a hash of all of the attributes set for the input.  Example:

B<Example:>

	my $ui = Packform->new('target');
	my $text = $ui->add_text('txt');
	$txt->set_attrs(size => '40', maxlength => '60');
	my %html_attributes = $txt->get_attrs();
	# %html_attributes will have data (size => '40', maxlength => '60')

=cut

# Give them the attributes
sub get_attrs { %{shift->{attrs}}; }


=item set_global( );

Applies to a hidden input, and marks it as a global input.

=cut

sub set_global {
	my $self = shift;
	unless ($self->{type} and $self->{type} eq 'hidden') {
		carp "Method only applies to hidden inputs";
		return $self;
	}
	$self->{global} = 1;
	$self;
}

=item set_noglobal( );

Applies to a hidden input, and unmarks it as global so it will be placed with the rest of the
response information, and be destroyed if that section is destroyed.

=cut

sub set_noglobal { my $self = shift; delete $self->{global}; $self; }

######################################
### INTERNAL / PRIVATE SUBROUTINES ###
######################################

# Returns undef if no errors occurred
# Otherwise, returns the text to carp with.
sub _carp_required_attributes {
	my $obj = shift;
	my $type = $obj->{type};
	my $n = (exists $obj->{name});
	my $v = (exists $obj->{value});
	unless ($type) { return "Unknown type"; }
	if ($type eq 'submit') { return; }
	elsif ($type eq 'paragraph' or $type eq 'modal') {
		if ($v) { return; }
		return "No value found for $type";
	}
	elsif ($type eq 'hidden') {
		return "Name and value required for hidden inputs" unless ($n and $v);
	}
	return "A name is required for type $type" unless ($n);
	return;
}


sub _html_prefix {
	my $self = shift;
	my $str = $self->get_prompt;
	my $type = $self->{type};
	# Be ADA-aware, and use labels where possible.
	if (exists $label_hash{$type} and $str) {
		my $id = $type."-".$self->{name};
		if ($type eq 'date') { $id = $self->{name}; }
		$str = "<label for='$id'>$str</label>";
	}
	if (defined $str) { return "<p class=\"pfui-prefix\"><span>$str</span></p>\n"; }
	return "\n";
}

sub _html_attrs {
	my $obj = shift;
	return join("", map { defined $obj->{attrs}->{$_} ? " $_='$obj->{attrs}->{$_}'" : " $_"  } keys %{$obj->{attrs}} );
}

sub _html_suffix {
	my $str = shift->{suffix};
	unless (defined $str) { return "\n"; }
	return "<span class='pfui-post-input'>$str</span>\n";
}

sub _set_attr {
	my ($attr,$obj,$val) = @_;
	$obj->{$attr} = $val;
	$obj;
}

sub _is_plugin {
	my $type = shift;
	return ($type eq 'modal' or $type eq 'date' or $type eq 'wysiwyg');
}

sub _is_option {
	my $type = shift;
	return ($type eq 'radio' or $type eq 'select');
}

sub _has_name_not_value {
	my $ref = shift;
	return (exists $ref->{name} and
		! exists $ref->{value} and
		! exists $ref->{prompt} and
		! exists $ref->{suffix});
}

sub _get_args {
	my %ret = ();
	# Nothing in, nothing out.
	unless (@_) { return %ret; }
	
	# If 1 argument, assume name
	if (scalar @_ == 1) {
		$ret{name} = shift;
		return %ret;
	}
	# If 2 args, assume name and value at this point
	if (scalar @_ == 2) {
		my ($n,$v) = @_;
		$ret{name} = $n;
		$ret{value} = $v;
		return %ret;
	}
	# Unless odd number, complain and return nothing
	unless (scalar @_ % 2 == 1) {
		carp "Invalid arguments";
		return %ret;
	}
	# Name is first
	$ret{name} = shift;
	# Options follow
	my %args = ( @_ );
	# store known data
	while (my ($k,$v) = each %args) {
		next unless (exists $known_attrs{$k});
		$ret{$k} = $v;
	}
	return %ret;
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

	perldoc Packform::Input

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

1; # End of Packform::Input
