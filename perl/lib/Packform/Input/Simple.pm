package Packform::Input::Simple;

use 5.006;
use strict;
use warnings FATAL => 'all';

our @ISA = qw(Packform::Input);

=head1 NAME

Packform::Input::Simple - Standard Packform inputs that require no special treatment.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This merely provides the as_html method for the objects.  All other methods are inhereted from
Packform::Input.  This should not be used directly.

=head1 METHOD

=over 4

=item as_html( );

This returns the HTML equivalent of the object.

=back
=cut

sub as_html {
	my $obj = shift;
	my $type = $obj->{type};
	my $prefix = $obj->_html_prefix;
	my $suffix = $obj->_html_suffix;
	my $attrs = $obj->_html_attrs;
	my $name = $obj->{name};
	my $val = $obj->get_value();
	my $id = $type . '-' . $name;
	my $html = "";
	if ($type eq 'text') {
		$html .= $prefix . "<input type='text' id='$id'";
	}
	elsif ($type eq 'checkbox') {
		$html .= $prefix . "<input type='checkbox' name='$name' id='$id' value='$val' $attrs />$suffix\n";
	}
	elsif ($type eq 'textarea') {
		$val //= "";
		$html .= $prefix . "<textarea name='$name' id='$id' $attrs>$val</textarea> $suffix\n";
	}
	elsif ($type eq 'submit') {
		$html .= $prefix . '<input type="submit" onclick="change_handler(this)"';
		($val) && ($html .= " value='$val'");
		$name ||= 'Submit';
		$html .= " name='$name' $attrs> $suffix";
	}
	elsif ($type eq 'paragraph') {
		if ($name) { $html .= "<p name='$name' "; }
		else { $html .= "<p "; }
		$html .= "class='pfui-p-input'>$val</p>\n";
	}
	elsif ($type eq 'hidden') {
		$html .= "<input type='hidden' name='$name' value='$val' />\n";
	}
	elsif ($type eq 'password') {
		$html .= "<input type='password' name='$name' id='$id' $attrs";
		($val) && ($html .= " value='$val'");
		$html .= " />$suffix\n";
	}
	return $html;
}


sub _bootstrap { shift; }

sub _init_defaults {
	my $self = $_[0];
	my $attrs = $self->{attrs};
	if ($attrs) {
		delete $self->{attrs};
		$self->set_attrs(%$attrs);
	}
	$_[0] = $self;
}

=head1 SEE ALSO

Packform

Packform::Input

Packform

=head1 AUTHOR

Zachary Hanson-Hart, C<< <zachhh at temple.edu> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Packform::Input::Simple

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

1; # End of Packform::Input::Simple
