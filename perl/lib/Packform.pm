package Packform;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

# Required for encoding JSON
# NOTE: if JSON::XS is available, it is used by this module (unless you have a broken JSON install)
require JSON;

use JSON;

# We are explicitly creating Packform::Input objects.
use Packform::Input;

######################## TODO #################################
# 
# Think about using fieldset for some of our groupings.
# Look into accessibility of the various plugins.  
#
######################## TODO #################################


=head1 NAME

Packform - Perl and Ajax Communication Kit, a Framework for Organized Response Management

=head1 VERSION

Version 1.01

=cut

######################
## GLOBAL VARIABLES ##
######################

our $VERSION = '1.01';

### Some configuration stuff for defaults.
### If we do package and deploy this, we need a way of making this configurable.
### Or, give instructions for setting a default base path for the packform includes (js and css)
### FRONTEND_VERSION/frontend.js
### FRONTEND_VERSION/packform.css
### and make them tell us the path to tinymce if they want to use it (it's not on any CDN).
###
### Need to find a way to make this easier to install.....
### How do you set global defaults for the file...  Environment?
### Like $ENV{JQ_VERSION} // '1.8.3'?
### More likely, Autoconfig should handle this...  where does IT get it's information.
###
my $JQ_VERSION = '1.9.1';
my $JQUI_VERSION = '1.10.3';
my $JQUI_THEME = 'base';
my $TINYMCE = '/includes/js/tinymce/3.5.8/jscripts/tiny_mce/jquery.tinymce.js';
my $FRONTEND = '0.5';
my $JSDIR = '/includes/packform/js';
my $CSSDIR = '/includes/packform/css';
my $DOCTYPE = '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">';

my @known_types = qw(text textarea textbox select radio hidden button submit checkbox password paragraph date wysiwyg);

=head1 SYNOPSIS

	use Packform;
	my $ui = Packform->new('target');
	$ui->set_url("https://server.com/path/to/this/script");
	$ui->set_title('New Title');
	$ui->set_heading('Accordion Heading');
	my $sel = $ui->add_select('inputname','default_value','Prompt: ');
	my %options = ('choice1' => 'First Choice', 'choice2' => 'Second Choice',
					'default_value' => 'Will be selected');
	$sel->add_options(\%options);
	$sel->prepend_option('','Choose One');
	$ui->add_submit();
	my $ajax = (lc $ENV{'HTTP_X_REQUESTED_WITH'} eq 'xmlhttprequest') ? 1 : 0;
	if ($ajax) {
		print "Content-Type: text/json\n\n";
		print $ui->json_output;
	}
	else {
		print "Content-Type: text/html\n\n";
		# You must provide a header, or configure and use html_header
		print $header_stuff;
		# Our self-contained sandbox
		print $ui->html_output;
		# You must provide a footer / closing tags
		print $footer_stuff;
	}
	exit;

=head1 DESCRIPTION

B<Packform> provides an interface to a JavaScript front end, but strives to allow functionality
without JavaScript (with a little work in your script).  If the JavaScript front end is not there
or the client does not have JavaScript enabled, sending json_output will result in the client
just getting JSON.  It is your job to determine if the request is from the front-end or not.

The html_output method will produce an HTML snippet suitable for using the perl script as both
the "starting" page and the processing page.  By this I mean that you can respond to an AJAX
request from the front end with json_output, or provide a fully functional form to continue
the script with html_output and appropriate headers.
Notably, if it is an initial request (will not be AJAX), and you give html_output with a header
that includes the front-end JavaScript, it will bootstrap and send/receive AJAX from that point
forward.

The html_output function does NOT produce a full HTML page.  This is intentional.  This way you
are able to add your own header file with your css, javascript, navigation, etc.  Really, the
html_output provides a self-contained sandbox, and does not touch anything outside of it's
container.

The front end uses jQuery to improve cross-platform compatibility, and to provide some function-
ality.  The sandbox is a wrapper around an accordion, with room for global error messages at the
top, a "title" of the sandbox, a "heading" for the accordion pane, and an "info" area at the
bottom.  The idea is to use the accordion to allow progressive forms and to hide "previous" parts
for privacy, and to keep down the clutter.  Every response has an accordion pane as it's target,
and the target is required.  The front-end auto-vivifies an accordion pane if the target you are
sending output to does not exist.

The Packform object is the message carrier to the front end.  It consists of a subset of the
following:
=over 4
=item The target of the response (required)
=item The title of the sandbox
=item The heading of the target pane
=item Information for persistent info portions above and below
=item The information for the temporary "info" portion below
=item Inputs to add to the page
=item Instructions to remove things from the page
=item Error messages

All of the inputs you want to add to the page have to be added to the Packform object.  They can
be created and added in one shot with the add_* methods, or they can be created as stand-alone
objects with the new_* methods.  Both creation types return the object, which you can then modify
with it's methods (depending on the object type).

The types of inputs are not limited to form elements.  We want to be able to access everything
we have put in the sandbox, so they are referred to as inputs (even if they are a paragraph).
A name is required for all actual form elements (except submit buttons), but it need not be unique.

Most methods and constructors will take a list of inputs with predefined positions, or
you can use named inputs (as a hash reference).  This is useful if you don't want to remember the
positions of the inputs, or if you want to only set a few and don't want to write "undef" in all
the unused positions.  

The names of the hash keys will be given as the placeholder name in the prototype in this doc. As
a general rule, if it has more than 3 arguments, it also accepts the hash form.

=head1 INTERACTION WITH THE FRONT END

The object here is the wrapper for a response to the front end.  The front end is JavaScript
that parses the response and follows the instructions given to it.  The response contains
instructions for how the front end should b<change> the page.

=head2 COMMUNICATION

The javascript front end expects JSON that has instructions for how to modify the page.  This con-
sists of instructions to remove items from the page or a portion of it, elements to add to a
given portion of the page (one target per response), and replacements for certain areas of the page.
The input elements can have event handlers attached to them.  It is always the same event handler,
and it carries out the following three tasks:

=over 4

1) abort any previous transactions
2) clear everything that was sent down in a response after the one that created the input
	(by removing it from the page entirely)
3) submit the form with whatever data remains.

=back

The first task is to prevent the page from being unresponsive in the event of network problems.

The second task is with the idea in mind that the inputs returned together belong together (so none
of them are removed), and the subsequent response fields depend on the input from the data already
entered.  This provides the form data as though it is the first time they set the fields from that
response, making it easier to code the logic in your perl script.

The third is necessary to send the data to the perl script.

When the front end gets a response from the perl script, it processes the information in the order:

=over 4

1) Check for errors.  If any are present, display them and ignore the rest of the response.
2) Check for instructions to remove existing things.  If there are any, do the removals.
3) Modify the label areas (title, info messages, heading).
3) Create the target pane if it does not exist.
4) Add the inputs to the target.
5) Do some cleanup.

=back

=head2 LAYOUT OF THE PAGE

The front end is responsible only for a sandbox that is structured as follows:

	ERROR STATEMENTS HERE

	PERSITENT TOP PORTION HERE

	TITLE OF SANDBOX

		Heading of 1st accordion pane (target)
			input1 of first response to target
			...
			inputN of first response to target
			input1 of second response to target
			...
			inputN of second response to target

		...

		Heading of Nth accordion pane
			input1 of first response
			...
			inputN of first response
			input1 of second response
			...
			inputN of second response
			...

	PERSISTENT BOTTOM PORTION HERE

	INFO MESSAGES GO HERE

The form encapsulates the accordion, but not the info messages or error message.  So, don't hardcode
inputs in the info or error messages -- they will be missed.

The accordion panes correspond to the targets.  If the specified target is not on the page, it will
be created at the bottom of the accordion.  By default, the last accordion will be shown and the
others will be collapsed.  A target is b<required> with every response that will be adding to the
page or removing elements from the target.

The inputs given in any response will stay together.  That is, the event handler will only destroy
inputs that were created in a response after the one triggering the submission of the form.  So,
if input2 of the 3rd response to a given target triggers the event handler, all targets after the
one containing the input will be removed, as will everything from the 4th and later responses to
the given target.

By default, only buttons have triggers, and these are on the click event.  That is, clicking a
button will fire off the aforementioned sequence of events to remove subsequent data and submit the
form to the script.  You can add a trigger to any standard input types (and even paragraphs if
you are so inclined).

=head2 HANDLING OF INPUTS

The layout of the inputs (except paragraphs) consists of a prompt and a suffix.  The prompt is put
before the input, and all prompts are aligned to be the width of the widest one in each pane.  You
can, however, use css to set the maximum width of the .pfui-prefix to something, and turn on word
wrap.  There is a default line break after each input (as the default for the "default_suffix").
If a suffix is specified for an input, it is used for that input and the default is ignored (so you
have to provide your own line break if you want one).  In the absence of a specific suffix, the
default_suffix is used.  You can change the default suffix.

Radio inputs have a special "item suffix" that is defined per radio group, and is appended after
each radio option.  By default, it is nothing.  

There are instructions that can be given to remove things from the page, or from the target only.
You can specify inputs by name, buttons or paragraphs generically, all inputs, targets by name, all
targets, or you can specify to remove only elements that conflict (by name) with one of the elements
being returned in the response ("duplicates").

Buttons and paragraphs do not require a name.  However, if you wish to remove them individualy at a
later time, you must provide them with one (since the name is how the inputs to be removed are
identified).

The inputs that exist in the response will be added in the order they were added to the structure.

There is no requirement that the names of the inputs be unique.  However, removing an existing input
by name will remove b<all> elements with that name within scope of the removal.

You can change the title of the sandbox at any time, via the set_title method on the base object.
Otherwise, the title is persistent.

You can change the heading of an accordion pane at any time with the set_heading method on the base
object.  Otherwise, the heading is persistent.

The error and info portions are cleared on every submission of the form.  They are not persistent.

The info message can be set in any response.  It is cleared on each form submission.

The persistent messages at the top and bottom do not change unless you specifically
set_persistent_top or set_persistent_bottom.

=head1 IMPLEMENTATION

The html_output does NOT automatically create the header.  The default behavior is to provide a
self-contained sandbox that can be dropped into any page with minimal extra work.   The "extra work"
consists of including the javascript for the packform front end, jQuery, the jQuery UI and tinyMCE
(the last is only necessary if you want to use a wysiwyg editor).  You also must include some
jQuery UI stylesheet (theme) because they include functional CSS, without which things will break.

The only time HTML should be sent back is in response to a request that is not an AJAX request.
AJAX requests must be replied to with JSON.  This means that in a typical session, the HTML header
information is only sent once.  There are really three ways of implementing this.  ALL THREE
REQUIRE that jQuery, jQuery UI, and the Packform front end javascript are available.  Furthermore,
jQuery UI css (of some form) must be present, as well as the packform frontend css, because they
are FUNCTIONAL css.

The three primary implementations are:

1) Have an HTML entry page that has the javascript and css files included, and only have your perl
respond to AJAX requests.  If it is not an AJAX request, you can spit back some page that says
JavaScript is required.  In fact, you can get the HTML sandbox for your entry page by constructing
it with Packform, and then printing html_output() to a file.  But, you still have to include all of
the javascript files that are necessary.  This allows you to take a page you already have, add some
javascript and css includes, and drop the sandbox into it where you see fit.  Then the browser will
never leave that URL, as all of the requests are AJAX.  You will also have to add one thing to tell
the script where to send the requests.  This is done with:

<script type="text/javascript">
$(document).ready( function() { $.ajaxSetup({ url: 'http://server.com/script.pl' }); });
</script>

2) Your script can be the starting point and it can generate the HTML you need for the sandbox.
You provide the encapuslating HTML (including all of the javascript and css includes in the header).  

3) You tell Packform where everything is, and it can generate the entire HTML response, or even
splice itself into a provided page.  See splice_html and splice_header for more information.  

It is recommended that you create a custom css file (or files) to make packform look a certain way.
See:
apps.cst.temple.edu/advising
apps.cst.temple.edu/jobfair
apps.cst.temple.edu/department_letters
for three different implementations.  Look at the css includes for guidance.

=head2 MAIN CONSTRUCTOR

=over 4

=item new( target, title, heading, url, frontend );

This is the base constructor for the response.  All arguments are optional.  However, a target is
required if you are actually adding something or removing something from "the target"
(but you can set it later with the set_target method).  The url is required if your user does
not have JavaScript, so that the form has somewhere to post.  

The title appears at the top of the sandbox pane.

The heading is for the target pane.

The url is the URL the form should submit to if JavaScript is not available.

The frontend is the version of the frontend you are using.  By default it is 0.3.

The method returns the new object, or undef on errors.

B<Example:>

	my $ui = Packform->new('the_target','the title','the heading');
	# Or equivalently,
	$ui = Packform->new({'target'=>'the_target', 'title'=>'the title',
								'heading'=>'the heading'});

=back

=cut

sub new { 
	my ($class,$args) = @_;
	my ($target,$title,$heading,$url,$frontend);
	my $self = {
		target => undef,
		inputs => [],
		defsuffix => '<br />',
		config => {
			'frontend' 	=> $FRONTEND,
			'jq'		=> $JQ_VERSION,
			'jqui'		=> $JQUI_VERSION,
			'jqtheme'	=> $JQUI_THEME,
			'tinymce'	=> $TINYMCE,
			'jspath'	=> $JSDIR,
			'csspath'	=> $CSSDIR,
			'style'		=> [],
			'title'		=> '',
			'meta'		=> '',
			'doctype'	=> $DOCTYPE
		}
	};
	bless($self, $class);
	if (scalar @_ > 2) { (undef,$target,$title,$heading,$url,$frontend) = @_; }
	elsif (ref $args eq 'HASH') {
		$target = $args->{target};
		$title = $args->{title};
		$heading = $args->{heading} // $args->{alt};
		$url = $args->{url};
		$frontend = $args->{frontend};
	}
	elsif ( ! ref $args ) { $target = $args; }
	else { carp "Invalid input"; return; }
	if (defined $target) { $self->{target} = $target; }
	if (defined $heading) { $self->{alt} = $heading; }
	if (defined $title) { $self->{title} = $title; }
	if (defined $url) { $self->{url} = $url; }
	if (defined $frontend) { $self->{frontend} = $frontend; }
	return $self;
}


=head2 Setters for the core of the response object

We are assuming that we have

	my $ui = Packform->new();

for all of the examples.

=over 4

=item set_target( target );

Sets the target to the value passed.  Returns the modified object, or undef if there is an error.
	
Example:

	$ui->set_target('login');

=cut

sub set_target {
	my ($self,$target) = @_;
	unless ($target) {
		carp "Invalid call to set_target.  No target provided.";
		return;
	}
	$self->{target} = $target;
	$self;
}


=item set_title( title );

Sets the title to the given value.  If no argument (or undef) is given, it will leave the current
title unchanged.  If you want a blank title, pass the empty string "". It returns the modified
object.

Example:

	$ui->set_title( "My fun survey" );

=cut

sub set_title { _set_attr('title',@_); }

=item set_heading( heading );

Sets the heading to the given value.  If no argument (or undef) is given, it will leave the current
heading unchanged.  If you want a blank heading, pass the empty string "". It returns the modified
object.

Example:

	$ui->set_heading( 'Tell us more' );

=cut

sub set_heading { _set_attr('alt',@_); }


=item set_url( url );

Sets the url for the form (if you are using html_output).  It returns the modified object.

Example:

	$ui->set_url('https://myexample.com/myscript.pl');

=cut


sub set_url { _set_attr('url',@_); }


=item set_frontend( version );

Sets the version of the front end.  The version must be numeric.  It returns the modified object,
or undef if there is an error.

=cut

sub set_frontend { _set_config('frontend',@_); }


=item set_context( target, title, heading );
=item or
=item set_context({target => 'target', title => 'title', heading => 'heading'});

All arguments are optional.  It sets the fields that are defined to the given value.  For the
hash construct, it sets the values according to the existing keys.

Examples:

	# Set the target and heading only.
	$ui->set_context('login',undef,'Log In');
	# Or, with a hash
	$ui->set_context({target => 'login', heading => 'Log In'});

=cut

sub set_context {
	my ($self,$args) = @_;
	my ($target,$title,$heading);
	if (scalar @_ > 2) { (undef,$target,$title,$heading) = @_; }
	elsif (ref($args) eq 'HASH') {
		$target = $args->{target};
		$heading = $args->{alt} // $args->{heading};
		$title = $args->{title}
	}
	elsif (!ref($args)) { $target = $args; }
	else { carp "Invalid arguments"; return; }
	if ($target) { $self->set_target($target); }
	if ($heading) { $self->set_heading($heading); }
	if ($title) { $self->set_title($title); }
	return 1;
}

=item set_err( error );

Sets the error message to be displayed.

=cut

sub set_err { _set_attr('err',@_); }

=item add_info( message );

There is a div outside of the form used for storing large output.  The message given gets placed
there.  This can be called more than once, and the new text is simply appended.  You are responsible
for providing line breaks.  The info box this is placed in is not persistent (it is cleared with ever
form submission).

=cut

sub add_info {
	my $self = shift;
	$self->{help} //= '';
	$self->{help} .= shift // '';
	$self;
}


=item set_persistent_bottom( message );

Sets the message in the persistent bottom portion to the given message.

=cut

sub set_persistent_bottom { _set_attr('stickybottom',@_); }

=item set_persistent_top( message );

Sets the message in the persistent top portion to the given message.

=cut

sub set_persistent_top { _set_attr('stickytop',@_); }

=item set_default_suffix( suffix );

This will set a default suffix for every input element.  The default is '<br />' so that every input
will begin on a new line.  When no suffix is specified for an input, this is the one provided.

This is only applied in the event that no suffix is given.  If a suffix is given, you are responsible
for providing the line break if one is desired.

If you want two things to appear next to one another, you should NOT use a prompt for the second.
Rather, you should put the prompt as the suffix of the first.  This is because the prompts are auto-
scaled to the maximum width of all of them in the visible pane.  You likely do not want to have this
extra space added.  The suffix is never scaled.  The second must have an undefined prompt (that is,
don't provide an argument, or provide undef, for the prompt when creating the input).

=cut

sub set_default_suffix { _set_attr('defsuffix',@_); }

=back

=head2 Getters for the core of the response object

=over 4

=item get_target();

Example:

	$target = $ui->get_target();

=cut

sub get_target { shift->{target}; }

=item get_title();

Returns the CHANGE of the title.  This will not return the title of the object on the page.
If you have not changed the title, this will return undef.  If you are setting the title to
something, it will be returned.

Example:

	$title = $ui->get_title();

=cut

sub get_title { shift->{title}; }

=item get_heading();

Again, this gives what you are changing the heading to, not the current heading on the page.

Example:

	$current_heading = $ui->get_heading();

=cut

sub get_heading { shift->{alt}; }

=item get_url();

=cut

sub get_url { shift->{url}; }

=item get_frontend();

This tells you the front end version being used.  It does NOT imply that you have the front end
of the given version set up.

Example:

	$version = $ui->get_frontend();

=cut

sub get_frontend { shift->{config}->{frontend}; }


=item get_err();

Returns the current error message.

=cut

sub get_err { shift->{err}; }


=item get_persistent_bottom();

Returns the message to be placed in the persistent bottom portion of the page.

=cut

sub get_persistent_bottom { shift->{stickybottom}; }

=item get_persistent_top();

Returns the message to be placed in the persistent top portion of the page.

=cut

sub get_persistent_top { shift->{stickytop}; }

=item get_default_suffix();

Returns the current default suffix.

=back
=cut

sub get_default_suffix { shift->{defsuffix}; }


=head1 INPUT OBJECT CONSTRUCTORS

NOTE: YOU PROBABLY SHOULD NOT USE THESE.  You should use the add_* methods instead if you are
going to put them in the response immediately.  These are here for completeness.

All of these constructors give you objects that you can manipulate directly with the applicable
methods.  Also, they can be added to the interface via $ui->add_input($input);

These constructors probably shouldn't be used directly unless you REALLY don't want to add it
to the response at the time of creation.  You should use the add_* counterparts.  They also return
the object, and put it in the response.  You can continue to edit the returned object from the
add_* methods just like you can with the new_* methods.



=head1 INPUT CREATION

There are two ways of adding inputs.  Either you can create and add them to the response in
one step with the add_* methods, or you can create a standalone input with a new_* method that
will need to be added to the response later.

The differences between new_* and add_* can be summarized with an example:

	# Build the base object
	my $ui = Packform->new('thetarget');
	
	# The new_* methods are constructors
	my $object = $ui->new_text('txt', prompt => 'Please enter text');
	# This then has to be added explicitly to the response
	$ui->add_input($object);
	
	# The add_* methods do both of the above things together, and returns the object that was
	# added. 
	my $object = $ui->add_text('txt', prompt => 'Please enter text');

Essentially, the add_* methods create the new input, add it to the response, and return the created input.

In both cases, the returned object is of type L<Packform::Input> or a subclass.

=over 4

=item add_input( $input_object );

If you created an input with one of the new_* methods, you must add it to the response with the
add_input method.  The updated response object is returned.

B<Example:>

	# Create a text input and then add it.
	my $input = $ui->new_text('name','value','Enter some text: ');
	$ui->add_input($input);
	
	# Or, do both at once:
	my $input = $ui->add_text('name','value','Enter some text: ');
	
	# Both result in a text input being added to the response, and $input holding
	# the object that was added.

=back

=cut

sub add_input { my ($self,$obj) = @_; push @{$self->{inputs}}, $obj; $self; }

=head3 Creation of various types.

The general arguments are of the form
	add_*( name, %args )
	or
	new_*( name, %args ), 
and can be called as
	add_*(name, key => "value", key2 => "value2", ... )
	or
	new_*(name, key => "value", key2 => "value2", ... );

The supported keys depend on the type, and some types support alternate calling styles.

All input types support creation of the object with all of the properties set with one call.  All
properties of an input object can be modified or added later.  The exception is that required
arguments must be present at the beginning.

The totality of the supported arguments, what their role is, and when they apply are as follows:

=over 4

=item value

All input types support a value.  Paragraph, modal and hidden inputs require it.

This is default value of the input.  For select inputs, this can be be an array reference to allow
for automatic selection of multiple inputs in a select input that has the multiple="multiple"
attribute.

=item prompt

This applies to all but hidden, paragraph and modal inputs.

It is optional for those that support it.

This is the prompt that shows up before the input.  These are automatically aligned to fit the
longest one.  So, care should be taken if these start getting long to provide a line break, or the
input may end up below the prompt rather than next to it.

=item suffix

This applies to all but hidden, paragraph and modal inputs.

It is optional for all that support it.

The suffix is appended to the HTML after the input object, and is wrapped in a span tag.  If no
suffix is provided, the default suffix is used (and the defalut for this is a BR tag).

For the case of radio groups, this is appended after the last radio element in the group.  To
change what goes after each individual input, use itemsuffix.

=item global

This applies only to hidden inputs.  It is a flag that if the key is present, then the input will
be treated as a global hidden input and remain in the form even if the section it was created with
gets destroyed.  

=item itemsuffix

This applies only to radio groups, and it is optional.  If you want something to go after every
radio input, you can specify it here.  By default, nothing is added so the radio inputs end up
next to one another in a linear fashion, and can roll to the next line.

=item labelloc

This applies only to radio groups, and it is optional.  It specifies where the label for the
radio button should go.  The values are 'before' and 'after'.  The default is 'before'.

=item attrs

This applies to everything except hidden and modal inputs.  It is a hash reference with key/value
pairs that will be turned into key="value" in the HTML tag for the input.

NOTE: It is far more efficient to create a css stylesheet to provide look-and-feel attributes for
the various input types rather than placing them in a style attribute.  

=item opts

This applies to radio groups and select boxes only.  It is optional and can be set later.

Its value is a reference to either an array, an array of references to 2 element arrays, or a hash
reference.  The purpose is to provide the value for the option, and the displayed text for the
option.  If the value is simply an array reference, the values are taken to be both the value and
the displayed text.  If it is an array of references to 2 element arrays, they are interpreted as
[ value, display text ].  Finally, if it is a hash reference, it is interpreted as
{ value => 'display text', ... }.

=item sort

This also applies to radio groups and select boxes only.  It is responsible for determining how to
sort the data.  If not present, no sorting will be done.  It should be noted that hash elements
are arbitrarily ordered internally.  The accepted values are
1 or 'text'
-1 or 'text_desc'
2 or 'value'
-2 or 'value_desc'
3 or 'text_num'
-3 or 'text_num_desc'
4 or 'value_num'
-4 or 'value_num_desc'

The minus sign or "desc" suffix indicates that it is a reverse sort.  The optional "num" qualifier
indicates that it is to be sorted numerically with <=> rather than cmp.  Finally, the first part
of the text is to indicate whether it's the displayed text or the item value that should be used
in the sort.  


=item pluginattrs

This applies ONLY to the date, modal and wysiwyg inputs.  These are all instantiated as jQuery
widgets, and can be configured when they are loaded.  Attributes to be passed to the widget,
not the underlying HTML element, should be added here.

Presently, there is no support for callback functions or method invocation.

Fundamentally this is a hash reference.  However, there can be sub-structure if the attribute
takes something other than a scalar.  To provide such a structure, use a reference to the data
type.  For instance, if you need to specify a list, use an array reference.  If you need to specify
a "dictionary", use a hash reference.  There is currently no support for attributes that require a
function.  


=over 4

=item add_button( name, value => "value", attrs => {} )
=item alternate calling styles: add_button( name, value) or add_button( value ) or add_button()
=item new_button( name, value => "value", attrs => {} )
=item alternate calling styles: new_button( name, value) or new_button( value ) or new_button();

=back

The value is what the button displays and what gets sent with the submission if the button has a
name.  The default is "Submit".  All arguments are optional.  If only one argument is given, it is
assumed to be the b<value> with no name.  If no arguments are provided, a value of "Submit" will be
used, with no name.  

B<Examples:>

	my $input = $ui->new_button('name','value');
	my $input = $ui->new_button('value');
	my $input = $ui->new_button('name',value=>'value');
	my $input = $ui->new_button();
	
	# Or, to add it to the response at creation time
	my $input = $ui->add_button('name','value');

=cut

sub add_button { return _add_input('submit',@_); }
sub new_button { return _new_input('submit',@_); }


=item add_submit( )
=item new_submit( )

These are synonyms for add_button and new_button and take the same calling styles.

=cut

sub add_submit { return add_button(@_); }
sub new_submit { return new_button(@_); }

=item add_text( name, %args );
=item new_text( name, %args );

This creates a text field.  The name is required. The supported keys in the args hash are:
value, prompt, suffix and attrs.

B<Examples:>
	# Standalone object
	my $input = $ui->new_text('name',
			value => 'value',
			prompt => 'prompt before the input ',
			suffix => 'after the input',
			attrs => { size => '50' }
		);
	# Then add to the response object:
	$ui->add_input( $input ); 
	# Create and add
	my $input = $ui->add_text('name',
			value => 'value',
			prompt => 'prompt before the input ',
			suffix => 'after the input',
			attrs => { size => '50' }
		);
=cut

sub new_text { return _new_input('text',@_); }
sub add_text { return _add_input('text',@_);  }

=item add_textarea( name, %args );
=item new_textarea( name, %args );

Similar to add_text and new_text, except it is for a textarea.  It accepts the keys in the args
hash: value, prompt, suffix and attrs.

=cut

sub add_textarea { return _add_input('textarea',@_);  }
sub new_textarea { return _new_input('textarea',@_);  }

=item add_radio( name, %args );
=item new_radio( name, %args );

The supported keys of the args hash are: value, prompt, suffix, attrs, itemsuffix, opts, sort
and labelloc.

This returns a radio GROUP.  The value is the default selected value.  You add the options after
it has been created.  You can also specify whether the label goes before or after the button.  The
default is to put the label before the button.

See Packform::Input::Option for more details on radio-specific methods.

=cut

sub new_radio { return _new_input('radio',@_);  }
sub add_radio { return _add_input('radio',@_); }

=item add_select( name, %args );
=item new_select( name, %args );

The supported keys of the args hash are: value, prompt, suffix, attrs, opts, sort.

Returns a select input.  You can add the options once it is constructed.

The value is the default selected value.  There is nothing stopping you from supplying multiple
values as an array reference.  If you set the multiple attribute (see ???), then every value in the
list will be selected.

=cut

sub new_select { return _new_input('select',@_); }
sub add_select { return _add_input('select',@_); }

=item add_checkbox( name, %args );
=item new_checkbox( name, %args );

The supported args keys are: value, prompt, suffix, attrs.

Returns a checkbox input object.

=cut

sub new_checkbox { return _new_input('checkbox',@_); }
sub add_checkbox { return _add_input('checkbox',@_); }

=item add_password( name, %args );
=item new_password( name, %args );

The supported args keys are: value, prompt, suffix, attrs.

Returns a password input object.

=cut

sub new_password { return _new_input('password',@_); }
sub add_password { return _add_input('password',@_);  }

=item add_paragraph( name, %args ) or add_paragraph( name, value ) or add_paragraph( value );
=item new_paragraph( name, %args ) or new_paragraph( name, value ) or new_paragraph( value );

The supported args keys are value and attrs.  If you are providing attrs, you must use the first
calling style.  

Though a paragraph is not an input, it is treated as one for consistency.  All of the input methods
apply to it.  However, the prompt and suffix are NOT rendered in the output.  The name is so it can
be selected for removal, and is optional.  The value is the contents of the paragraph tag (in
particular, you can include HTML).

=cut

sub new_paragraph { return _new_input('paragraph',@_); }
sub add_paragraph { return _add_input('paragraph',@_);  }

=item add_hidden( name, %attrs ); or add_hidden(name, value);
=item new_hidden( name, %attrs ); or new_hidden(name, value);

The %attrs hash supports keys: value and global.  The value is required.  If setting the global
option, you must use the first calling style.  If using the second calling style, the input will
not be global.  

The name and value are required, and are the name and value of the hidden input.  The global field
is optional, and sets the hidden input as global if it is present (regardless of the truth of the
value).

B<Example:>

	my $input = $ui->new_hidden('name','value');
	my $input = $ui>new_hidden('name',value=>'value',global=>1);
	
	# Or, to add it
	my $input = $ui->add_hidden('name','value');

=cut

sub new_hidden { return _new_input('hidden',@_); }
sub add_hidden { return _add_input('hidden',@_); }

=item add_hidden_hash( \%hash );

The hash has keys that are the names of the inputs, and values that are the values.  If an input
with the name already exists, the hidden field is skipped.

This is most useful for the HTML output in the event that the user does not have javascript.  For then,
you can pass all of the prior form values along to the next page with hidden inputs.  The return value
is the number of inputs added. If you want to add a hidden input that shares a name with an item already
on the form, you can use add_hidden separately.

=back
=cut

sub add_hidden_hash {
	my ($self,$args) = @_;
	unless (ref($args) eq 'HASH') { carp "Invalid input -- expecting a hashref"; return; }
	# Remove values for existing input item names
	my @names = $self->get_all_names() // ();
	foreach (@names) { delete $args->{$_}; }
	# Add the hidden inputs.
	my $n = 0;
	foreach (keys %$args) { $self->add_hidden($_,$args->{$_}) and $n++; }
	return $n;
}

=head4 Plugin objects

To extend the functionality and increase usability for the client, there are several plugins
that are included for use.  These are the jQuery datepicker widget, the tinyMCE editor and the
jQuery dialog widget.

The tinyMCE editor is not part of jQuery and must be installed by you prior to use.  The tinyMCE
jQuery plugin is used.  You must include it in the header file in order of the plugin to work
properly.  Presently, it loses its data once the panel is collapsed, so you need to track it
some once you get it (say, by shoving it into a hidden input).

All of these fall back to regular input elements when JavaScript is not available to the client.

You can specify properties of the plugin widget itself by using
	$plugin->set_plugin_attrs( \%attributes );
where $plugin is one of these objects.  At this time, handlers and callbacks for the plugin objects
are not supported.

To set the properties of the fall-back form element, use $plugin->set_attrs( \%attributes );
The fall-back for a datepicker is a text input, for a tinyMCE what you see is what you get editor
the fall-back is a textarea, and the fallback for the modal dialog is just a div (since it is not
actually an input element).

=over 4

=item add_date( name, %args );
=item new_date( name, %args );

The supported keys for the %args hash are: value, prompt, suffix, attrs, pluginattrs.

A "date" field is a text field that gets bound to a jQuery datepicker object.  If there is no
JavaScript on the client, it falls back to a text input.

=cut

sub new_date { return _new_input('date',@_);  }
sub add_date { return _add_input('date',@_);  }

=item add_modal( name, %args ); or add_modal( title, content ); or add_modal( content );
=item new_modal( name, %args ); or new_modal( title, content ); or new_modal( content );

The supported keys to args are: value (or content), pluginattrs.

The simplest invocation is to just provide the title and the content or just the content.  If you
use the first construction, you will be able to identify the input by name while the response is
being constructed.  The name is ignored in the actual HTML since the widget is destroyed when they
close the box.

Using the first calling style, you have to set the title in pluginattrs with something like:

	# You must provide a name with this calling style.
	$ui->add_modal('name',
		value => "This will be displayed",
		pluginattrs => { title => "Title" }
	);
	# If you do not need the name, it would be easier to just
	$ui->add_modal('Title', 'This will be displayed');
	

This gives a modal dialog that overlays the whole form.  It is very useful for ensuring the client
sees the content in it.  NOTE: The title is cast as a plugin attribute, so it will show up there.
For more information about plugin attributes, see Packform::Input::Plugin.

=cut

sub new_modal { return _new_input('modal',@_); }
sub add_modal { return _add_input('modal',@_); }

=item add_wysiwyg( name, %args );
=item new_wysiwyg( name, %args );

The supported keys for the %args hash are: value, prompt, suffix, pluginattrs.

This provides a tinyMCE WYSIWYG editor.  You must install the tinyMCE editor with the jQuery plugin
and have it included in the header.  This is currently buggy with passing the information along
after the accordion pane containing it has collapsed.  

=cut

sub new_wysiwyg { return _new_input('wysiwyg',@_); }
sub add_wysiwyg { return _add_input('wysiwyg',@_); }

=back

=head3 Response Object Input Retrieval and Removal

If you have lost track of an input (say, it went out of scope), but still want to work with one,
you can get information about the existing inputs in the response, and remove inputs from the
response.  This will NOT affect inputs already existing on the page.  

=over 4

=item get_input_by_name( name );

Returns the last input object added that currently has name 'name', or undef if none could be found.

B<Example:>

	my $input = $ui->get_input_by_name('inputname');
	# You can work with this directly and the changes ARE reflected.
	$input->set_value('new value');
	$input->set_suffix('did you see this field?<br />');

=cut

sub get_input_by_name {
	my ($self,$name);
	unless (@{$self->{inputs}}) { return; }
	foreach (reverse @{$self->{inputs}}) { return $_ if ($_->{name} && $_->{name} eq $name); }
	return;
}

=item input_exists( name );

Returns 1 if there is an input with the given name, and a false value otherwise.

=cut

sub input_exists {
	my ($self,$name) = @_;
	unless (@{$self->{inputs}}) { return; }
	foreach (@{$self->{inputs}}) { if ($_->{name} && $_->{name} eq $name) { return 1; } }
	return;
}

=item get_all_names();

Returns an array of the names of all of the inputs, or an empty array if there are none.  This does
not find only distinct names.  It will give all names in the order that they appear, provided the
name is defined.

=cut

sub get_all_names {
	my $self = shift;
	my @names = ();
	foreach (@{$self->{inputs}}) { push @names, $_->{name} if (defined $_->{name}); }
	return @names;
}

=item get_all_inputs();

This returns an array of input objects, in the order they were added.  Just as with
get_input_by_name, you can work directly on the resulting objects.  Say you wanted to add an event
handler to all of the objects (whether they support it or not!).  You could:

	my @inputs = $ui->get_all_inputs();
	foreach (@inputs) { $_->add_handler(); }

=cut

sub get_all_inputs { @{shift->{inputs}}; }

=item clear_inputs();

Use clear_inputs to remove all of the inputs already added to the response.  This has no bearing
on items already on the page.  There is no meaningful return value.

=cut

sub clear_inputs { shift->{inputs} = []; }

=item remove_input( name );

This will remove all of the inputs with the given name from the response object (not from the page).
It returns an array or array reference, depending on whether it is called in list or scalar context,
with the removed elements, or undef if there was an error.  Since the removed elements
are actual input objects, you can use all of the input object methods on them, and even add them
back to the response.  

=cut

sub remove_input {
	my $self = shift;
	my $name = shift;
	unless ($name) { carp "A name must be provided to remove_input"; return; }
	my @keep = ();
	my @removed = ();
	foreach my $inp (@{$self->{inputs}}) {
		my $n = $inp->{name};
		if (! defined($n) or ($n ne $name)) { push @keep, $inp; }
		else { push @removed, $inp; }
	}
	$self->{inputs} = \@keep;
	return wantarray ? @removed : \@removed;
}

=item remove_buttons();

This removes all of the buttons from the response object (not from the page).  The
removed buttons are returned.

=cut

sub remove_buttons {
	my $self = shift;
	my @remove = grep { ! $_->{type} or $_->{type} ne 'submit' } @{$self->{inputs}};
	@{$self->{inputs}}= grep { $_->{type} and $_->{type} eq 'submit' } @{$self->{inputs}};
	return wantarray ? @remove : \@remove;
}

=back

=head3 Modifying existing objects on the page

It may be desired to remove things from the page, or to associate something to an element that you
are not explicitly returning.  These are methods that can be called on the base object to achieve
such results.

The general naming convention here is remove_*_from_** where * is some descriptive qualifier and
** is the scope for the removal.  The scope can be either "page" or "target".  If you made a call to
one of these and later change your mind, you don't have to start from scratch.  There is a corre-
sponding leave_*_on_** that will remove the instruction from the response.

They all return the modified response object.

=over 4

=item remove_target_from_page( target, target2, ... )

To remove targets and all of their contents from the page, provide the name of the target to this
function.  This can be called multiple times, and the results are cumulative.  The primary use of
this is to completely destroy the login data.  It is also useful to remove every input from the
page if you want to disable any further input from the user.  

If the target is not on the page, no harm is done.

=cut

sub remove_target_from_page {
	my $self = shift;
	push @{$self->{xtargets}}, @_;
	$self;
}

=item leave_target_on_page( target, target2, ... )

This will remove a target from the list of targets to be removed from the page.  That is, it will
undo a call to remove_target_from_page for a given target.  This is simply so every function call
is reversible.  If the target has not been marked for removal, nothing will be done.

=cut

sub leave_target_on_page {
	my $self = shift;
	unless (@_) { return $self; }
	my @targets = @_;
	for (my $j = 0; $j < scalar @{$self->{xtargets}}; $j++) {
		foreach my $t (@targets) {
			if ($self->{xtargets}->[$j] eq $t) { splice @{$self->{xtargets}}, $j, 1; $j--; }
		}
	}
	$self;
}

=item remove_input_from_page( name, name2, ... )

This gives the instruction to remove all inputs with a given name that exist on the page.  This is
done prior to any addition of inputs.  So, if you remove inputs with name 'inp' and add one with
this name, your new one will be put on the page.

=cut

sub remove_input_from_page {
	my $self = shift;
	push @{$self->{xinputs}}, @_;
	$self;
}


=item leave_input_on_page( name )

This is so you can change your mind about removing an input already on the page (not in the re-
sponse).  It will undo a call to remove_input_from_page.  If the input had not been marked for
removal, this has no effect.  This will NOT leave an input on the page if it is destined to be
destroyed by removing it's parent target.

=cut

sub leave_input_on_page {
	my $self = shift;
	my @inps = @_;
	unless (exists $self->{xinputs}) { return $self; }
	for (my $j = 0; $j < scalar @{$self->{xinputs}}; $j++) {
		foreach my $inp (@inps) {
			if ($self->{xinputs}->[$j] eq $inp) { splice @{$self->{xinputs}}, $j, 1; $j--; }
		}
	}
	$self;
}

=item remove_all_targets_from_page( )

Remove every target from the page.  It will not remove global hidden inputs. 

=cut

sub remove_all_targets_from_page { _set_param('xalltargets',@_); }

=item leave_all_targets_on_page( )

This is the "undo" of remove_all_targets_from_page.  It will b<NOT> clear the list of targets marked
to be removed with remove_target_from_page.

=cut

sub leave_all_targets_on_page { _delete_param('xalltargets',@_); }

=item remove_all_inputs_from_page( )

Remove every "input" from the page.  This includes the paragraphs that have been added to the page
via the interface (not those hard-coded in a response).  The primary purpose of this is when you're
logging out and want everything gone, you need to get rid of the global hidden inputs.  Since they
are not in a target, removing the targets from the page is not sufficient to destroy all of the info
that may remain on the page.

This is done PRIOR to any adding of data.  You can remove all inputs, and push back whatever you
want, effectively preventing the user from changing anything that has already been submitted.

=cut

sub remove_all_inputs_from_page { _set_param('xallinputs',@_); }

=item leave_all_inputs_on_page( )

This is the "undo" for changing your mind about removing all inputs.  It will b<NOT> clear the list
of the inputs that have been specified by name to be removed.

=cut

sub leave_all_inputs_on_page { _delete_param('xallinputs',@_); }

=item remove_all_buttons_from_page( )

This will remove all existing buttons from the b<target> div.  This occurs prior to any of your add-
itions to the page.  If you want to remove prior buttons, this is the way to go.

=cut

sub remove_all_buttons_from_page { _set_param('xallbuttons',@_); }

=item leave_all_buttons_on_page( )

This is the "undo" function for remove_all_buttons_from_page, and will not remove the buttons from
the page.

=cut

sub leave_all_buttons_on_page { _delete_param('xallbuttons',@_); }

=item remove_all_pars_from_page( )

This will remove all "paragraph inputs" from the page.

=cut

sub remove_all_pars_from_page { _set_param('xallpars',@_); }

=item leave_all_pars_on_page( )

This cancels the call to remove_all_pars_from_page.

=cut

sub leave_all_pars_on_page { _delete_param('xallpars',@_); }


=item remove_dups_from_page( )

If you want to not have your new inputs conflict with old inputs, remove_dups_from_page will remove
those inputs that currently exist on the page that have the same name as an input in the response.
This does b<not> prevent you from sending multiple inputs with the same name back to the page, it
only gets rid of those on the page for which there is at least one in input with the same name in
the response.  The adding of your inputs to the page is done after all of the removing.

=cut

sub remove_dups_from_page { _set_param('xdups', @_); }


=item leave_dups_on_page( )

Cancel a request to remove_dups_from_page.

=cut

sub leave_dups_on_page { _delete_param('xdups', @_); }


=item

The following are the same, except they only carry out the action in the target for the response.

=item remove_input_from_target( input, input2, ... )
=cut

sub remove_input_from_target {
	my $self = shift;
	push @{$self->{xinptarget}}, @_;
	$self;
}

=item leave_input_on_target( input, input2, ... )
=cut

sub leave_input_on_target {
	my $self = shift;
	my @inps = @_;
	unless (exists $self->{xinptarget}) { return $self; }
	for (my $j = 0; $j < scalar @{$self->{xinptarget}}; $j++) {
		foreach my $inp (@inps) {
			if ($self->{xinptarget}->[$j] eq $inp) { splice @{$self->{xinptarget}}, $j, 1; $j--; }
		}
	}
	$self;
}

=item remove_all_inputs_from_target( input, input2, ... )
=cut

sub remove_all_inputs_from_target { return _set_param('xallinputstarget',@_); }

=item leave_all_inputs_on_target( )
=cut

sub leave_all_inputs_on_target { return _delete_param('xallinputstarget',@_); }

=item remove_all_buttons_from_target( )
=cut

sub remove_all_buttons_from_target { return _set_param('xallbuttonstarget',@_); }

=item leave_all_buttons_on_target( )
=cut

sub leave_all_buttons_on_target { return _delete_param('xallbuttonstarget',@_); }

=item remove_all_pars_from_target( )
=cut

sub remove_all_pars_from_target { return _set_param('xallparstarget',@_); }

=item leave_all_pars_on_target( )
=cut

sub leave_all_pars_on_target { return _delete_param('xallparstarget',@_); }


=item remove_dups_from_target( )
=cut

sub remove_dups_from_target { return _set_param('xdupstarget',@_); }

=item leave_dups_on_target( )
=cut

sub leave_dups_on_target { return _delete_param('xdupstarget',@_); }

=item input_err( name, value )

If there was an error for an input value (like it was not provided, or is invalid for some reason),
you can specify the name of the input field and text (or HTML) as the value to place immediately
after the input element.  This is removed on every submission of the form.  It prevents any new
inputs from being added to the page, as it is an error.  

=cut

sub input_err {
	my ($self,$name,$err) = @_;
	push @{$self->{inputerrs}}, {name => $name, value => $err };
	$self;
}

=back


=head3 Output generation

=over 4

=item html_output( );

This returns the HTML of the sandbox b<only>.  This should be called when your client does not have
javascript, which you are responsible for determining, or if it was a direct call to the script.
The output is compatible with the javascript, so if a direct call to the script is made, then the
HTML output is a full-fleged sandbox for the starting page, whose structure is compatible with the
javascript front end.

B<Example:>

	if ($no_javascript) {
		# YOU must provide this function
		print_header();
		# Pass back all data that isn't in the form (otherwise it's lost)
		$ui->add_hidden_hash( \%formdata );
		# get the HTML for the sandbox and form
		print $ui->html_output();
		# YOU must provide this function
		print_footer();
	}

You are responsible for the header and footer.  This will create a form with only the inputs that
you have added to the object.  So it would probably be wise to add all necessary form variables as
hidden inputs prior to calling html_output since the prior responses will be lost if you don't.  

=cut

sub html_output {
	my $self = shift;
	my $defsuff = $self->{defsuffix};
	my $err = $self->{err} // "";
	my $heading = $self->{alt} // "";
	my $tgt = $self->{target} // 'XXXXXXXX';
	my $title = $self->{title} // "";
	my $top = $self->{stickytop} // "";
	my $bot = $self->{stickybottom} // "";
	my $details = $self->{help} // "";
	my $url = $self->{url} // "";
	my $fe = $self->{frontend};
	my $target = $self->{target};
	my $html = "<!-- BEGIN Packform area -->\n";
	# Provide info to assistive technology that this has active content
	$html .= '<div class="pfui-hidden-div">';
	$html .= "This page uses active content and a tabbed presentation through an accordion.  <br/>\n";
        $html .= "The content of each accordion panel (the tab content) contains both text and form elements. <br/>\n";
        $html .= "The text components are given a role of document so they may be read with assistive technology. <br/>\n";
        $html .= "Since some of the text is essential for understanding the form, it is recommended that you step ";
        $html .= "through the document one line at a time.\n";
        $html .= '</div>';
	# Our wrapper should inform the user of additions (and removals?)
	$html .= "\n<!-- begin pfui-wrapper -->\n";
	$html .= '<div class="pfui-wrapper" aria-live="polite" aria-relevant="additions">';
	# Region for the error messages should be live
	$html .= "\n\t" . '<div class="pfui-errormsg" aria-live="polite" aria-relevant="text">';
	$html .= $err . "</div>\n\t";
	# The persistent top should also be live
	$html .= '<div id="pfui-persistent-top" aria-live="polite" aria-relevant="text">';
	$html .= $top . "</div>\n";
	# Begin sandbox.
	$html .= "\t<div id=\"pfui-sandbox\"><!-- begin pfui-sandbox -->\n\t";
	$html .= '<h1 id="pfui-sandbox-title" aria-live="polite" aria-relevant="text" aria-label="title">';
	$html .= "$title</h1>\n";
	$html .= "\t<form id=\"packform\" action=\"$url\" method=\"POST\">\n";
	$html .= "\t\t<!-- begin accordion --><div id='accordion'>";
	$html .= '<h3 aria-atomic="true" aria-live="polite" aria-relevant="text">';
	$html .= "$heading</h3>\n";
	# The span that wraps the response needs to be an aria-live region. 
	$html .= "\t\t\t<div id=\"$target\" aria-live=\"polite\" aria-relevant=\"text\">";
	$html .= '<span aria-live="polite" aria-atomic="true">' . "\n";
	# Add the input elements (using their own methods)
	foreach my $item (@{$self->{inputs}}) { $html .= $item->as_html(); }
	$html .= "\n\t\t\t</span></div><!-- end target -->\n";
	# End the accordion and form
	$html .= "\t\t</div><!-- end accordion -->\n";
	$html .= "\t</form>\n";
	# Add the scratch areas -- persistent bottom and details.
	$html .= "\t<div id='pfui-details' aria-live='polite' aria-relevant='text'>$details</div>\n";
	$html .= "\t<div id='pfui-persistent-bottom' aria-live='polite' aria-relevant='text'>$bot</div>\n";
	# End the sandbox
	$html .= "\t</div><!-- end pfui-sandbox -->\n";
	$html .= "</div><!-- end pfui-wrapper -->\n";
	$html .= "<!-- END Packform area -->\n";
}

=item json_output();

This returns the JSON to be sent back to the front-end.  If they have JavaScript, this is the
preferred way of sending the result, since the point of all of this is to build a structure for the
AJAX response.  This is the AJAX response.

B<Example:>

	print "Content-Type: text/json\n\n";
	print $ui->json_output();
	exit;

=back
=cut

# get JSON representation of the things.
sub json_output {
	my $self = shift;
	# encode_json won't take blessed objects.  So, unless the response object
	my $hash = { %$self };
	# Don't send the config down with the response
	delete $hash->{config};
	# Rebuild the inputs with unblessed hashrefs.
	delete $hash->{inputs};
        my @inps = ();
	foreach my $inp (@{$self->{inputs}}) { push @inps, { %$inp }; }
        if (@inps) { $hash->{inputs} = \@inps; }
	# Now we can encode
	return encode_json $hash;
}


####################################
### HEADER HELP
####################################

=head1 HEADER GENERATION / MODIFICATION

To ease the HTML output, these methods are provided so you can incorporate the Packform specific
javascript and css files into the head of your document.  These include things like the location of
the tinyMCE jQuery plugin javascript file (usually called jquery.tinymce.js), the version of jQuery,
the jQuery UI version, and even the theme (grabbed from the google CDN), and any specific
stylesheets that are specifically for the Packform interface.

=over 4

=item set_jquery_version( version );

This sets the version of jQuery to be loaded from the Google CDN.  The default version as of the
writing of this module is 1.8.3.

=cut

sub set_jquery_version { _set_config('jq',@_); }

=item set_jqueryui_version( version );

The version of the jQueury UI to include from the Google CDN.  This version is also used for the
jQuery UI theme.  The default jQuery UI version is 1.9.2.

=cut

sub set_jqueryui_version { _set_config('jqui',@_); }

=item set_jqueryui_theme( theme );

The Google CDN also hosts jQuery UI themes.  The default is "base", and the version is the same as
the one set with jqueryui_version in order to keep the css aligned with the javascript.  

=cut

sub set_jqueryui_theme { _set_config('jqtheme',@_); }

=item set_tinymce_file( path/to/file );

Set the path as it is to appear in the script src attribute in the HTML.  So, this should be:
1) A complete URL (eg https://your.server/includes/tinymce/jquery.tinymce.js)
2) A path relative to the server base (eg /includes/tinymce/jquery.tinymce.js)
3) A relative path that will be resolved correctly (eg jquery.tinymce.js if it has the same base
path as the page being served).

In the end, this goes in the tag as
<script type="text/javascript" src="PATH"></script>
so it must be something that will resolve to the actual file.  

=cut

sub set_tinymce_file { _set_config('tinymce',@_); }

=item set_js_path( path )

This sets the BASE path for the frontend javascript.  This is the base path that will be put inside
the src attribute of a script tag.  So, it is something that will get parsed.  The scr attribtue
will be

	path/version/frontend.js

where version is the front-end version.

=cut

sub set_js_path { _set_config('jspath',@_); }

=item set_css_path( path )

This is the base for the css for the frontend.  It is resolved as:

	<link rel="stylesheet" type="text/css" href="path/version/packform.css" />

where version is the front-end version.
=cut

sub set_css_path { _set_config('csspath',@_); }

=item set_page_title( title );

To set the title for the page (not the sandbox) you can use this.  

=cut

sub set_page_title { _set_config('title',@_); }

=item set_meta_data( html )

If you want to include meta data (actually, anything) before all of the packform information, you
can provide the HTML with set_meta_data.  This is used if you are going to call html_full,
html_header, splice_html or splice_header.  In every case, this goes at the very beginning of the
HEAD tag, before anything else.

NOTE: You must provide the entire HTML tags!

=cut

sub set_meta_data { _set_config('meta',@_); }

=item set_doctype( doctype );

Set the document type to the given value.  The default is

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">

mostly to force IE to work in standards mode, and because many browsers being used are not HTML 5.

=cut

sub set_doctype { _set_config('doctype',@_); }


=item add_stylesheets( @sheet_hrefs );

You can provide an array (or a single) stylesheet location that will be included in calls to
html_full, html_header, splice_header and splice_html.  These are included AFTER the packform
information, so you can override default behavior of the jQuery UI and Packform stylesheets.

=cut

sub add_stylesheets {
	my $self = shift;
	push @{$self->{config}->{style}}, @_;
	$self;
}

=item add_stylesheet( @sheet_hrefs );

This is a synonym for add_stylesheets, but more "gramatically correct" if only adding one.

=cut

sub add_stylesheet { add_styelsheets(@_); }


=item splice_header( html );

This will put the packform information, as configured by you, in the header.  This includes
the packform javascript and css, the jQuery javascript and css, the tinyMCE javascript, the
meta data, the stylesheets and page title.  It will NOT replace existing versions of any of these.
So, if you have a title tag, the page title will not be changed.  If you are including any jQuery or
jQuery UI javascript or css, the existing ones will remain.  The test for inclusion is a string match.
There is no check that it is not inside an HTML comment.  Meta data will be written without any
checking for existing metadata.

The order of the information will be the same as in html_header.  

If no head section is found, it returns the text unaltered.

=cut

sub splice_header {
	my $self = shift;
	my $txt = shift;
	return "" unless $txt;
	my ($end_head, $start_head);
	if ($txt =~ m/(<\s*\/head\s*>)/i) { $end_head = $1; }
	if ($txt =~ m/(<\s*head\s*>)/i) { $start_head = $1; }
	if (!$start_head and !$end_head) {
		carp "Could not find HEAD section";
		return $txt;
	}
	elsif (!$start_head) {
		carp "Could not find the beginning of your HEAD section";
		return $txt;
	}
	elsif (!$end_head) {
		carp "Could not find the ending of your HEAD section";
		return $txt;
	}
	
	# Set the doctype at the VERY beginning
	my $dt = ($self->{config}->{doctype} // $DOCTYPE) unless ($txt =~ m/<!DOCTYPE\s+/i);
	if ($dt) { $txt = $dt . "\n" . $txt; }
	
	# Add the title and meta data at the top (order: meta then title)
	
	# Get the data to put there.
	my $meta = $self->{config}->{meta} // "";
	if ($meta) { $meta .= "\n"; }
        my $first = "";
	my $tit = $self->{config}->{title} // "";
	if ( $txt =~ m/<title/i ) { $tit = ""; }
        if ($tit) { $first = "\n<title>$tit</title>\n"; }
	if ($meta) { $first = "\n" . $meta . $first;}

	# Add it at the beginning.
	if ($first) { $txt =~ s/\Q$start_head\E/$start_head$first/; }

	# Get the corresponding strings unless they are already present
	# so we can just write all of the things in one shot.
	my ($tiny,$jq,$jqui,$jqui_css,$pf,$pf_css) = ("","","","","","");
	$tiny = $self->get_tinymce_tags() unless ($txt =~ m/jquery\.tinymce\.js/i);
	$jq = $self->get_jq_js() unless ($txt =~ m/jquery\.(min\.)?js/i);
	$jqui = $self->get_jqui_js() unless ($txt =~ m/jquery-ui\.(min\.)?js/i);
	$jqui_css = $self->get_jqui_css() unless ($txt =~ m/jquery-ui.css/i);
	$pf = $self->get_pf_js() unless ($txt =~ m/frontend.js/i);
	$pf_css = $self->get_pf_css() unless ($txt =~ m/packform.css/i);
	# Get stylesheets to add (ones that aren't there)
	# Note the meta quoting in the regex with \Q \E so we don't match the wrong things or
	# provide an invalid pattern.
	#my $styles = join("\n",
	#		map { "<link rel=\"stylesheet\" type=\"text/css\" href=\"$_\">" }
	#		grep { ! $txt =~ m/\Q$_\E/ } @{$self->{config}->{style}});
	
	my $styles = $self->get_stylesheet_tags();
	
	# Take care of what we are appending by grabbing the end of the heading
	# and applying that.
	
	my $append = "\n" . $jq . "\n" . $jqui . "\n" . $jqui_css . "\n" . $tiny .
		"\n" . $pf . "\n" . $pf_css . "\n" . $styles . "\n";
	
	# Replace the end_head with the appropriate information
	$txt =~ s/\Q$end_head\E/$append$end_head/;
	
	return $txt;
}

=item splice_html( html );

This will splice the Packform information into an existing HTML page.  The expectations are that:
1) 	You have set up the necessary information, or are happy with the defaults for:
	js and css path, frontend version, tinyMCE file, jQuery and jQuery UI versions, jQuery UI
	theme, (optionally) any additional style sheets or meta information.
2)	Your html is a full HTML file including <head>, </head> and a body.
3)	An HTML comment <!-- Packform --> to be replaced by the sandbox.

If there is no <!-- Packform --> comment, the sandbox will be placed immediately before the end
of the body.  If there is niether a </body> or <!-- Packform --> tag, the sandbox will NOT be
included.

It is likely that the default jQuery and jQuery UI information will be functional without any
modification, since these are being taken from the Google CDN.

It is UNLIKELY that tinyMCE will be available (i.e. wysiwyg inputs) unless you INSTALL the
TinyMCE jQuery package and point tinymce_file to the jquery.tinymce.js file, and the version of
tinymce is compatible with the version of jQeury in use.

Download the TinyMCE jQuery package from http://www.tinymce.com/download/download.php

It is UNLIKELY that the front end will function at all unless you have obtained the frontend CSS
and JavaScript files.  (Ok, in full disclosure, it will probably "work" without the CSS, but there
is no chance of it working without the javascript (except as HTML-only with full form submissions
and full HTML page responses (since these do not require javascript (do I have a LISP?)))).

These will be available shortly at: https://github.com/zachhh/Packform

=cut

sub splice_html {
	my $self = shift;
	my $html = shift;
	# Splice in the available things if nothing is already included.
	$html = splice_header( $html );
	
	if ($html =~ m/<!--\s*Packform\s*-->/i) {
		my ($before,$after) = split(/<!--\s*Packform\s*-->/i, $html, 2);
		$html = $before . $self->html_output() . $after;
	}
	elsif ($html =~ m/(<\s*\/\s*body\s*>)/i) {
		my $b = $1;
		my ($before,$after) = split($b, $html, 2);
		# Need to replace the </body> tag.
		$html = $before . $self->html_output() . $b . $after;
	}
	return $html;
}

=item html_full( );

To get a full HTML page, you need to satisfy condition 1) in splice_html, i.e., have configured the
necessary things to provide a header.  Without having done that, the comments about what will and
will not work in the discussion of splice_html apply.

The return value is HTML suitable for a browser to read and a form that will submit to the given URL.

=cut

sub html_full {
	my $self = shift;
	return $self->html_header() . "<body>\n" . $self->html_output() . "</body>\n</html>";
}

=item get_jquery_tags( );

This returns the HTML script and link tags for the .js and .css files for jQuery and the jQuery UI.
This is used internally, but is documented in case you find a need for it.

=cut

# Return the script tags for everything that's been configured
sub get_jquery_tags {
	my $self = shift;
	# jQuery
	return $self->get_jq_js() . "\n". $self->get_jqui_js() ."\n" . $self->get_jqui_css() . "\n";
}

sub get_jq_js {
	my $self = shift;
	my $jq = $self->{config}->{jq} // $JQ_VERSION;
	return "<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/$jq/jquery.min.js\" type=\"text/javascript\"></script>";
}

sub get_jqui_js {
	my $self = shift;
	my $jqui = $self->{config}->{jqui} // $JQUI_VERSION;
	return "<script src=\"https://ajax.googleapis.com/ajax/libs/jqueryui/$jqui/jquery-ui.min.js\" type=\"text/javascript\"></script>";
}

sub get_jqui_css {
	my $self = shift;
	my $jqui = $self->{config}->{jqui} // $JQUI_VERSION;
	my $theme = $self->{config}->{jqtheme} // $JQUI_THEME;
	return "<link rel=\"stylesheet\" href=\"https://ajax.googleapis.com/ajax/libs/jqueryui/$jqui/themes/$theme/jquery-ui.css\" />";
}


=item get_tinymce_tags( );

This returns the HTLM script tag to include the tinyMCE jQuery plugin, assuming you have already
set_tinymce_file( path/and/filename ), or the default miraculously works on your server.

=cut

sub get_tinymce_tags {
	my $self = shift;
	my $tiny = $self->{config}->{tinymce};
	#$tiny //= $TINYMCE;
	return "\t<script src=\"$tiny\" type=\"text/javascript\"></script>\n";
}

=item get_frontend_tags( );

Returns the tags for including the JS and CSS for the front end, assuming you have
set_frontend( version ), set_js_path( path ) and set_css_path( path ), or have them in a suitable
place to be found by the defaults.

=cut

sub get_frontend_tags { my $self = shift; return $self->get_pf_js . "\n" . $self->get_pf_css . "\n"; }


sub get_pf_js {
	my $self = shift;
	my $fe = $self->{config}->{frontend} // $FRONTEND;
	my $js = $self->{config}->{jspath} // $JSDIR;
	return "<script src=\"$js/$fe/frontend.js\" type=\"text/javascript\"></script>";
}

sub get_pf_css {
	my $self = shift;
	my $fe = $self->{config}->{frontend} // $FRONTEND;
	my $css = $self->{config}->{csspath} // $CSSDIR;
	return "<link rel=\"stylesheet\" href=\"$css/$fe/packform.css\" />";
}

=item get_stylesheet_tags( );

Returns the tags to include the stylesheets added by add_stylesheets( );

=cut

sub get_stylesheet_tags {
	my $self = shift;
	my $html  = "";
	foreach (@{$self->{config}->{style}}) { $html .= "\t<link rel=\"stylesheet\" type=\"text/css\" href=\"$_\" />\n"; }
	return $html;
}

=item html_header( );

Returns a full HTML header, accounting for the document type, page title, jQuery includes, tinyMCE
includes, Packform includes and stylesheets, assuming they have already been configured or you are
happy with the defaults.

=cut

# Full blown HTML header...
sub html_header {
	my $self = shift;
	my $title = $self->{config}->{title};
	my $meta = $self->{config}->{meta} // "";
	my $doctype = $self->{config}->{doctype} // $DOCTYPE;
	# NOTE: To evaluate a function in a heredoc, you need to dereference the
	# sub call so it gets evaluated, and then re-reference for printing.
	# Since these return a scalar, it is achieved as ${ \( sub() ) }
	# For an array, it is @{ [ sub() ] }
	# This is a useful trick.  Without this trick, it simply prints the function name.
	my $html = <<EOF;
$doctype
<html>
<head>
$meta
<title>$title</title>
<!-- jQuery from the Google CDN -->
${ \( $self->get_jquery_tags() ) }
<!-- TinyMCE local installation -->
${ \( $self->get_tinymce_tags() ) }
<!-- Packform front end -->
${ \( $self->get_frontend_tags() ) }
${ \( $self->get_stylesheet_tags() ) }
</head>
EOF
	return $html;

}



####################################
### INTERNAL / PRIVATE FUNCTIONS ###
####################################

sub _set_attr {
	my ($key,$obj,$val) = @_;
	$obj->{$key} = $val;
	$obj;
}

sub _set_param {
	my ($key,$obj) = @_;
	$obj->{$key} = 1;
	$obj;
}

sub _delete_param {
	my ($key,$obj) = @_;
	delete $obj->{$key};
	$obj;
}

sub _set_config {
	my ($key,$obj,$val) = @_;
	$obj->{config}->{$key} = $val;
	$obj;
}

## This is so we can pass along requests to add an input
## without typing this every time.

sub _add_input {
	my ($type,$packform,@args) = @_;
	my $obj = Packform::Input->new($type,@args);
	$obj->_bootstrap($packform);
	$packform->add_input($obj);
	$obj;
}

sub _new_input {
	my ($type,$packform,@args) = @_;
	my $obj = Packform::Input->new($type,@args);
	$obj->_bootstrap($packform);
	$obj;
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

github

=head1 AUTHOR

Zachary Hanson-Hart, C<< <zachhh at temple.edu> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Packform

	
=head1 ACKNOWLEDGEMENTS

Thanks to Omar Hijab for all of his patience, suggestions and testing.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Temple University - College of Science and Technology.

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

1; # End of Packform
