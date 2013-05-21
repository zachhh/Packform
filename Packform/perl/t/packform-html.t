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

while (my ($method,$value) = each %tests) {
	ok( $ui->$method($value), $method);
}

# Get tags containing them
my $html = $ui->html_header;

my $jqCDN = 'https://ajax.googleapis.com/ajax/libs';

my %scripts = (
	'jquery' => "src=\"$jqCDN/jquery/$tests{set_jquery_version}/jquery.min.js\"",
	'jqueryui' => "src=\"$jqCDN/jqueryui/$tests{set_jqueryui_version}/jquery-ui.min.js\"",
	'packform' => "src=\"$tests{set_js_path}/$tests{set_frontend}/frontend.js\"",
	'tinymce' => "src=\"$tests{set_tinymce_file}\""
);

my %styles = (
	'jqueryui' => "href=\"$jqCDN/jqueryui/$tests{set_jqueryui_version}/themes/$tests{set_jqueryui_theme}/jquery-ui.css\"",
	'packform' => "href=\"$tests{set_css_path}/$tests{set_frontend}/packform.css\"",
	'extra' => "href=\"$tests{add_stylesheets}\""
);

like( $html, qr/<title>\s*\Q$tests{set_page_title}\E\s*<\/title>/, 'title');
like( $html, qr/^\s*\Q$tests{set_doctype}\E/, 'doctype');

# Check for script tags
while (my ($tag,$pattern) = each %scripts) {
	like( $html, qr/<script[^>]+\Q$pattern\E/, "$tag js");
}

# Check for style tags
while (my ($tag,$pattern) = each %styles) {
	like( $html, qr/<link[^>]+\Q$pattern\E/, "$tag css");
}

# Check the header splicing

my $header = <<EOF;
<!DOCTYPE something else>
<head>
<title>the title</title>
<script src="my/copy/of/jquery-ui.js">
<style href="my/copy/of/jquery-ui.css">
</head>
EOF

my $newhead = $ui->splice_header($header);

# Do the checks again, but verify the logic.

# Old title should remian
unlike( $newhead, qr/<title>\s*\Q$tests{set_page_title}\E\s*<\/title>/, 'title');
# Old doctype should remain
unlike( $newhead, qr/^\s*\Q$tests{set_doctype}\E/, 'doctype');

# Check for script tags
while (my ($tag,$pattern) = each %scripts) {
	# We provided our own jquery ui tags
	if ($tag eq 'jqueryui') {
		unlike( $newhead, qr/<script[^>]+\Q$pattern\E/, "$tag js");
	}
	else { like( $newhead, qr/<script[^>]+\Q$pattern\E/, "$tag js"); }
}

# Check for style tags
while (my ($tag,$pattern) = each %styles) {
	if ($tag eq 'jqueryui') {
		unlike( $newhead, qr/<link[^>]+\Q$pattern\E/, "$tag css");
	}
	else { like( $newhead, qr/<link[^>]+\Q$pattern\E/, "$tag css"); }
}

done_testing();


