# Pod::WikiDoc - check module loading and create testing directory

use Test::More; # plan comes later
use t::Casefiles;

use Pod::WikiDoc;


my $casefiles = t::Casefiles->new( "t/wiki2pod/complex" );

my $parser = Pod::WikiDoc->new ();

my $input_filter = sub { $parser->format( $_[0] ) };

$casefiles->run_tests( $input_filter );


