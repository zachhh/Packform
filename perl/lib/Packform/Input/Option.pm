package Packform::Input::Option;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

our @ISA = qw(Packform::Input);

=head1 NAME

Packform::Input::Option - The class of radio groups and select boxes in Packform.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This extends the Packform::Input class by adding methods to enable the management of the options
for a radio group or select box.  

=head1 METHODS

In addition to the methods presented here, all of the methods in Packform::Input are available.

The as_html method should probably not be used directly, since it only gives the snippet for the
input object itself.  It's primary purpose here is to be used in the call to html_output() on the
base Packform response object.  

There are several methods for dealing with the options for the radio and select inputs.  In both
cases there is displayed text, and the value of the input if the given option is selected.  

There are also several methods that apply only to radio inputs because the layout requires things
like placement of the label relative to the button, etc.

All of these methods return the modified object, unless explicitly stated otherwise.

=head2 HTML output

=over 4

=item as_html( );

Returns the HTML representation of the object (i.e. as it is included in the page).

=cut

sub as_html {
	my $self = shift;
	if ($self->{type} eq 'radio') { return _radio_html($self); }
	elsif ($self->{type} eq 'select') { return _select_html($self); }
	carp "This object does not seem to be a radio group or select box";
	return "";
}

=back

=head2 Option Management Methods

=over 4

=item add_options( \%hash, sort ); or add_options( \@array, sort ); or add_options( value, text );
=item or add_options( value );

The arguments are first a reference to the data, and second is a sort flag.  The data can come in
three varieties:
1) A hashref where the keys are the VALUES of the input and the values are the DISPLAYED text
2) An array reference whose elements are both the values and the displayed text
3) An array reference whose elements are array references with data [value, display text].

The sort parameter takes:
1 or 'text'
-1 or 'text_desc'
2 or 'value'
-2 or 'value_desc'
3 or 'text_num'
-3 or 'text_num_desc'
4 or 'value_num'
-4 or 'value_num_desc'

You need not use the abbreviated versions of "num" for numeric or "desc" for descending.  Case
is irrelevant.  The underscores are optional.  The order of the qualifiers is irrelevant.  

The minus sign or "desc" suffix indicates that it is a reverse sort.  The optional "num" qualifier
indicates that it is to be sorted numerically with <=> rather than cmp.  Finally, the first part
of the text is to indicate whether it's the displayed text or the item value that should be used
in the sort.  

NOTE: The order of the entries of a hash is arbitrary, so you should strongly consider sorting options
generated by a hash, or use the third flavor of data.

If the first argument is NOT a reference, it is assumed that a SINGLE option is being added.  In this
case, it will be appended to the list of options.  If the text is omitted, it will be taken to be the
same as the value.

=cut

sub add_options {
	my $self = shift;
	my ($data,$sort) = @_;
	unless (ref($data)) {
		push @{$self->{opts}}, {'val' => $data, 'txt' => $sort // $data };
		return $self;
	}
	push @{$self->{opts}}, _sorted_opts($data,$sort);
	$self;
}

=item add_option

This is a synonym for add_options, and takes the same arguments.  The purpose is to allow for more
readable code.  For example:

	my $ui = Packform->new();
	my $sel = $ui->add_select('select', 'xxx');
	# Add one option
	$sel->add_option('xxx', 'Choose One');
	# The above is more "logical" than the equivalent:
	$sel->add_options('xxx', 'Choose One');

	# However, they do the same thing:
	# provide a single option with value 'xxx' displayed as 'Choose One' in the list.
	
=cut

sub add_option { return add_options(@_); }

=item append_options
=item append_option

These are synonyms for add_options, and have the same syntax.  Again, this is only for code readability.

=cut

sub append_options { return add_options(@_); }
sub append_option { return add_options(@_); }

=item prepend_options( \%hash, sort ); or prepend_option( \@array, sort);
=item or prepend_options( value, text ); or add_options( value );

The input is identical to that of add_options.  The difference is that the resulting options are
put at the beginning of the options list.

=cut

sub prepend_options {
	my $self = shift;
	my ($data,$sort) = @_;
	unless (ref($data)) {
		unshift @{$self->{opts}}, {'val' => $data, 'txt' => $sort // $data };
		return $self;
	}
	unshift @{$self->{opts}}, _sorted_opts($data,$sort);
	$self;
}


=item prepend_option

This is a synonym for prepend_options, and takes the same arguments.  Again, it's for readability.

=cut

sub prepend_option { return prepend_options(@_); }

=item clear_options( );

This removes all of the options from the input.  If for some reason you want to start from scratch,
you can get a clean slate of options using this.  

=cut

sub clear_options { my $self = shift; $self->{opts} = []; $self; }

=item get_options( );

This will return an array of array references, whose entries are [ value, text ] where value is
the value of the input, and text is what will be displayed in the list.

=cut

sub get_options {
	my $self = shift;
	my @ret = map { [ $_->{val}, $_->{txt} ] } @{$self->{opts}};
	return @ret;
}


###########################
## RADIO GROUP SPECIFIC ###
###########################

=back

=head2 Radio Group Specific Methods

The following methods are specific to radio groups and should not be used on any other input type.

=over 4

=item label_before();

This will make the label go before the radio button.  (This is the default.)

=cut

sub label_before {
	my $self = shift;
	carp "Method only applies to radio groups" unless ($self->{type} eq 'radio');
	$self->{labelloc} = 'before';
	$self;
}

=item label_before();

This will make the label go after the radio button.

=cut

sub label_after {
	my $self = shift;
	carp "Method only applies to radio groups" unless ($self->{type} eq 'radio');
	$self->{labelloc} = 'after';
	$self;
}

=item get_label_location();

=cut

sub get_label_location { return shift->{labelloc}; }


###################
## INTERNAL
###################

sub _init_defaults {
	my $self = $_[0];
	# This needs an ops arrayref.
	$self->{opts} //= [];
	# If there's any sort directive at this time, do it.
	if ($self->{sort}) {
		my $opts = $self->{opts};
		$self->{opts} = [];
		$self->add_options($opts,$self->{sort});
		delete $self->{sort};
	}
	my $attrs = $self->{attrs};
	if ($attrs) {
		delete $self->{attrs};
		$self->set_attrs(%$attrs);
	}
	delete $self->{pluginattrs};
	# radios have a default label location.
	if ($self->{type} eq 'radio') { $self->{labelloc} //= 'before'; }
	$_[0] = $self;
}

sub _bootstrap { shift; }

sub _radio_html {
	my $obj = shift;
	my $name = $obj->{name};
	unless (defined $name) { return ""; }
	my $html = $obj->_html_prefix;
	my $val = $obj->get_value;
	my $loc = $obj->get_label_location // 'before';
	my $html_attrs = $obj->_html_attrs;
	my $radsuff = $obj->{itemsuffix} // "";
	if (ref ($val)) { $val = pop @$val; }
	$html .= '<p class="pfui-radio-wrapper" name="' . $name . '">';
	foreach my $opt (@{$obj->{opts}}) {
		my $txt = $opt->{txt};
		my $id = "radio-" . $name . "-" . $val;
		if (! defined $txt or $txt eq '' ) { $txt = '&nbsp;'; }
		my $label = "<span class='pfui-radio-label'><label for='$id'>$txt</label></span>";
		my $checked = "";
		if ($val eq $opt->{val}) { $checked = " checked"; }
		my $radio = "<input type='radio' name='$name' id='$id' value='";
		$radio .= $opt->{val} . "' $html_attrs $checked>";
		# Now we have the label and the checkbox.  Put them in the right order
		if ($loc eq 'after') { $html .= $radio . $label; }
		else { $html .= $label . $radio; }
		# Add the radiosuffix.
		$html .= "<span class='pfui-radio-suff'>$radsuff</span>\n";
	}
	$html .= $obj->_html_suffix . "</p>\n";
	return $html;
}

sub _select_html {
	my $obj = shift;
	my $name = $obj->{name};
	unless (defined $name) { return ""; }
	my $val = $obj->get_value;
	# Make it an array ref
	unless (ref($val)) { $val = [ $val ]; }
	# Now a hash for easy checking.
	my %vals = map { $_ => undef } @$val;
	my $html_attrs = $obj->_html_attrs;
	my $html = $obj->_html_prefix;
	$html .= "<select name='$name' id='select-$name' $html_attrs>\n";
	foreach my $opt (@{$obj->{'opts'}}) {
		my $v = $opt->{val} // "";
		my $txt = $opt->{txt} // "";
		$html .= "<option value=\"$v\"";
		if (exists $vals{$v}) { $html .= ' selected'; }
		$html .= " >$txt</option>\n";
	}
	$html .= "</select>" . $obj->_html_suffix;
	return $html;
}

sub _sorted_opts {
	
	my ($data,$sort) = @_;
	my @opts;
	# Convert data into internal format
	if (ref($data) eq 'HASH') {
		@opts = map { { 'val' => $_ , 'txt' => $data->{$_} } } keys %$data;
	}
	elsif (ref($data) eq 'ARRAY') {
		if (ref($data->[0]) eq 'ARRAY') {
			@opts = map { {'val' => $_->[0], 'txt' => $_->[1] } } @$data;
		}
		else { @opts = map { {'val' => $_, 'txt' => $_} } @$data; }
	}
	else { carp "Expecting array or hash reference for options"; return; }
	unless ($sort) { return @opts; }
	my $filter;
	my $s;
	if ($sort =~ m/^\s*(-?\d+)\s*/) {
		my $s = $1 + 0;
		unless ($s and -4 <= $s and $s <= 4) {
			carp "Invalid sort option, assuming 1 (by displayed text)";
			$s = 1;
		}
	}
	else { # default is by text with cmp ascending
		my ($v,$numeric,$desc) = (1,0,-1);
		if ($sort =~ m/val/i) { $v = 2; }
		if ($sort =~ m/num/i) { $numeric = 1; }
		if ($sort =~ m/desc/i) { $desc = 1; }
		$s = (-1 * $desc) * ($v + (2 * $numeric));
	}
	
	if ($s == -4) { # by value numerically descending
		@opts = map { $_->[0] } sort { $b->[1] <=> $a->[1] }
			map { [$_, $_->{val} ] } @opts;
	}
	elsif ($s == -3) { # by text numerically descending
		@opts = map { $_->[0] } sort { $b->[1] <=> $a->[1] }
			map { [$_, $_->{txt} ] } @opts;
	}
	elsif ($s == -2) { # by value descending
		@opts = map { $_->[0] } sort { $b->[1] cmp $a->[1] }
			map { [$_, $_->{val} ] } @opts;
	}
	elsif ($s == -1) { # by text descending
		@opts = map { $_->[0] } sort { $b->[1] cmp $a->[1] }
			map { [$_, $_->{txt} ] } @opts;
	}
	elsif ($s == 1) { # by text
		@opts = map { $_->[0] } sort { $a->[1] cmp $b->[1] }
			map { [$_, $_->{txt} ] } @opts;
	}
	elsif ($s == 2) { # by value
		@opts = map { $_->[0] } sort { $a->[1] cmp $b->[1] }
			map { [$_, $_->{val} ] } @opts;
	}
	elsif ($s == 3) { # by text numerically
		@opts = map { $_->[0] } sort { $a->[1] <=> $b->[1] }
			map { [$_, $_->{txt} ] } @opts;
	}
	elsif ($s == 4) { # by value numerically
		@opts = map { $_->[0] } sort { $a->[1] <=> $b->[1] }
			map { [$_, $_->{val} ] } @opts;
	}
	else {
		carp "Invalid sorting option, assuming 1 (by displayed text)";
		@opts = map { $_->[0] } sort { $a->[1] cmp $b->[1] }
			map { [$_, $_->{txt} ] } @opts;
	}
	return @opts;
}

=back

=head1 SEE ALSO

Packform::Input

Packform

=head1 AUTHOR

Zachary Hanson-Hart, C<< <zachhh at temple.edu> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Packform::Input::Option

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

1; # End of Packform::Input::Option