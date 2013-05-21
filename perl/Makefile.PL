use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Packform',
    AUTHOR           => q{Zachary Hanson-Hart <zachhh@temple.edu>},
    VERSION_FROM     => 'lib/Packform.pm',
    ABSTRACT_FROM    => 'lib/Packform.pm',
    LICENSE          => 'GPL_3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'JSON'	=> 2.00,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Packform-*' },
);
