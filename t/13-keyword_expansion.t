# Pod::WikiDoc - check module loading and create testing directory

use Test::More; # plan comes later
use t::Casefiles;

use Pod::WikiDoc;


my $casefiles = t::Casefiles->new( "t/wiki2pod/keyword_expansion" );

my $parser = Pod::WikiDoc->new ( { keywords => { VERSION => 3.14 } } );

my $input_filter = sub { $parser->format( $_[0] ) };

$casefiles->run_tests( $input_filter );


