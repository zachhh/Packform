#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok('Packform'); }

use Packform;

# Setters / Getters for the configuration
#	set_jquery_version set_jqueryui_version set_jqueryui_theme
#	set_tinymce_file set_js_path set_css_path set_page_title set_meta_data
#	set_doctype add_stylesheets add_stylesheet 


my $ui = Packform->new();

my %tests = (
	set_jquery_version => '1.2.3',
	set_jqueryui_version => '2.3.4',
	set_jqueryui_theme => 'silly',
	set_tinymce_file => '/includes/tiny/mce.js',
	set_js_path => '/includes/packform/js',
	set_css_path => '/includes/packform/css',
	set_page_title => 'TITLE OF PAGE',
	set_meta_data => '<meta name="test">',
	set_doctype => '<!DOCTYPE html>',
	add_stylesheets => '/includes/css/test.css',
	set_frontend => '1.2'
);

# Do the configuration
while (my ($method,$value) = each %tests) {
	ok( $ui->$method($value), $method);
}


my $jqCDN = 'https://ajax.googleapis.com/ajax/libs';

# Define the scripts
my %scripts = (
	'jquery' => "src=\"$jqCDN/jquery/$tests{set_jquery_version}/jquery.min.js\"",
	'jqueryui' => "src=\"$jqCDN/jqueryui/$tests{set_jqueryui_version}/jquery-ui.min.js\"",
	'packform' => "src=\"$tests{set_js_path}/$tests{set_frontend}/frontend.js\"",
	'tinymce' => "src=\"$tests{set_tinymce_file}\""
);

# Define the stylesheets
my %styles = (
	'jqueryui' => "href=\"$jqCDN/jqueryui/$tests{set_jqueryui_version}/themes/$tests{set_jqueryui_theme}/jquery-ui.css\"",
	'packform' => "href=\"$tests{set_css_path}/$tests{set_frontend}/packform.css\"",
	'extra' => "href=\"$tests{add_stylesheets}\""
);

# Get the header HTML
my $html = $ui->html_header;

# Check the title, doctype and meta data
like( $html, qr/<title>\s*\Q$tests{set_page_title}\E\s*<\/title>/, 'title');
like( $html, qr/^\s*\Q$tests{set_doctype}\E/, 'doctype');
like( $html, qr/\s*\Q$tests{set_meta_data}\E/, 'meta data');

# Check for script tags
while (my ($tag,$pattern) = each %scripts) {
	like( $html, qr/<script[^>]+\Q$pattern\E/, "$tag js");
}

# Check for style tags
while (my ($tag,$pattern) = each %styles) {
	like( $html, qr/<link[^>]+\Q$pattern\E/, "$tag css");
}

# Check header splicing leaves existing data
# We only need place holders and the tags need not be proper.
my $header = <<EOF;
<!DOCTYPE something else>
<head>
<title>the title</title>
<script src="my/copy/of/jquery-ui.js">
<link href="my/copy/of/jquery-ui.css">
<script src="whatever/jquery.tinymce.js">
<script src="my/copy/of/jquery.js">
<script src="my/frontend.js">
<link href="my/packform.css">
</head>
EOF

my $newhead = $ui->splice_header($header);

# Old title should remian
unlike( $newhead, qr/<title>\s*\Q$tests{set_page_title}\E\s*<\/title>/, 'leave existing title');
# Old doctype should remain
unlike( $newhead, qr/^\s*\Q$tests{set_doctype}\E/, 'leave existing doctype');

# Check for script tags
while (my ($tag,$pattern) = each %scripts) {
	unlike( $newhead, qr/<script[^>]+\Q$pattern\E/, "leave existing $tag js");
}

# Check for style tags
while (my ($tag,$pattern) = each %styles) {
	# The extra should be written
	next if ($tag eq 'extra');
	# The rest should NOT be replaced
	unlike( $newhead, qr/<link[^>]+\Q$pattern\E/, "leave existing $tag css");
}

like( $newhead, qr/\Q$tests{set_meta_data}\E/, "Meta data");

# Check that they are created if they do not exist.  
# Simply provide a blank head section.
$header = "<head></head>";
# Construct the spliced header.
$newhead = $ui->splice_header($header);

# Test that they all make it there.
like( $newhead, qr/<title>\s*\Q$tests{set_page_title}\E\s*<\/title>/, 'Set title');
like( $newhead, qr/^\s*\Q$tests{set_doctype}\E/, 'Set doctype');
like( $newhead, qr/\Q$tests{set_meta_data}\E/, 'Set meta data');
while (my ($tag,$pattern) = each %scripts) {
	like( $newhead, qr/<script[^>]+\Q$pattern\E/, "set $tag js");
}
while (my ($tag,$pattern) = each %styles) {
	like( $newhead, qr/<link[^>]+\Q$pattern\E/, "set $tag css");
}


done_testing();


