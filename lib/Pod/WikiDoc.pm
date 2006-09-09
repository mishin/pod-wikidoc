package Pod::WikiDoc;
use strict;
use warnings;
use vars qw($VERSION );
$VERSION     = "0.01";

use base 'Pod::Simple';
use Carp;
use Parse::RecDescent;
use Pod::WikiDoc::Parser;

#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

# Below is the stub of documentation for your module. You better edit it!


sub new {
    my $class = shift;
    my $self = Pod::Simple->new(@_);

    # setup for pod filtering
    $self->accept_targets( 'wikidoc' );
    $self->{in_wikidoc} = 0;

    # load up a parser 
    $self->{parser} = Pod::WikiDoc::Parser->new();
    
    return bless $self, $class;
}

sub _handle_element_start {
    my($parser, $element_name, $attr_hash_ref) = @_;
    if ( $element_name eq 'for' && $attr_hash_ref->{target} eq 'wikidoc' ) {
        $parser->{in_wikidoc} = 1;
    }

#    print "START: $element_name\n"; # Attr hash: ", Dumper $attr_hash_ref;
}

sub _handle_text {
    my($parser, $text) = @_;
    if ( $parser->{in_wikidoc} ) {
        print { $parser->{output_fh} } $text, "\n";
    }
#    print "TEXT: '$text'\n";
}

sub _handle_element_end {
    my($parser, $element_name) = @_;
    if ( $element_name eq 'for' ) {
        $parser->{in_wikidoc} = 0;
    }
    elsif ( $element_name eq 'Data' ) {
        print { $parser->{output_fh} } "\n";
    }
#    print "END: $element_name\n";
}

my $numbered_bullet;

my %opening_of = (
    Paragraph           =>  q{},
    Unordered_List      =>  "=over\n\n",
    Ordered_List        =>  sub { $numbered_bullet = 1; return "=over\n\n" },
    Preformat           =>  q{},
    Header              =>  sub { 
                                my $node = shift; 
                                my $level = $node->{level} > 4 
                                    ? 4 : $node->{level};
                                return "=head$level "
                            },
    Bullet_Item         =>  "=item *\n\n",
    Numbered_Item       =>  sub { 
                                return  "=item " . $numbered_bullet++ 
                                        . ".\n\n" 
                            },
    Indented_Line       =>  q{ },
    Plain_Line          =>  q{},
    RegularText         =>  q{},
    WhiteSpace          =>  q{},
    BoldText            =>  'B<',
    ItalicText          =>  'I<',
    LinkText            =>  'L<',
    SpecialChar         =>  q{},
);

my %closing_of = (
    Paragraph           =>  "\n",
    Unordered_List      =>  "=back\n\n",
    Ordered_List        =>  "=back\n\n",
    Preformat           =>  "\n",
    Header              =>  "\n\n",
    Bullet_Item         =>  "\n\n",
    Numbered_Item       =>  "\n\n",
    Indented_Line       =>  "\n",
    Plain_Line          =>  "\n",
    RegularText         =>  q{},
    WhiteSpace          =>  q{},
    BoldText            =>  ">",
    ItalicText          =>  ">",
    LinkText            =>  ">",
    SpecialChar         =>  q{},
);

my %content_handler_for = (
    RegularText         =>  \&_escape_pod, 
);

my %escape_code_for = (
    ">" =>  "E<gt>",
    "<" =>  "E<lt>",
);

sub _escape_pod {
    my $node = shift;
    my $input_text  = $node->{content};
    # replace special symbols with corresponding escape code
    $input_text =~ s{ ( [<>] ) }{$escape_code_for{$1}}gxms;
    return $input_text;
}

sub _wiki2pod {
    my ($nodelist, $insert_space) = @_;
    my $result = q{};
    for my $node ( @$nodelist ) {
        next unless ref $node eq 'HASH'; # skip empty blocks marked w/ ""
        my $opening = $opening_of{ $node->{type} };
        my $closing = $closing_of{ $node->{type} };

        $result .= ref $opening eq 'CODE' ? $opening->($node) : $opening;
        if ( ref $node->{content} eq 'ARRAY' ) {
            $result .= _wiki2pod( 
                $node->{content}, 
                $node->{type} eq 'Preformat' ? 1 : 0 
            );
        }
        else {
            my $handler = $content_handler_for{ $node->{type} };
            $result .= defined $handler 
                     ? $handler->( $node ) : $node->{content}
            ;
        }
        $result .= ref $closing eq 'CODE' ? $closing->($node) : $closing;
    }
    return $result;
}

sub format {
    my ($self, $wikitext) = @_;
    
    my $wiki_tree  = $self->{parser}->WikiDoc( $wikitext ) ;
    for my $node ( @$wiki_tree ) {
        undef $node if ! ref $node;
    }

    return _wiki2pod( $wiki_tree );
}

1; #this line is important and will help the module return a true value
__END__

=begin wikidoc

= NAME

Pod::WikiDoc - Put abstract here 

= SYNOPSIS

    use Pod::WikiDoc;
    blah blah blah

= DESCRIPTION

Description...

= USAGE

Usage...

= SEE ALSO

* HTML::WikiConverter
* Text::WikiFormat
* Template::Plugin::KwikiFormat
* PurpleWiki::Parser::WikiText
* Pod::TikiWiki
* Convert::Wiki
* Kwiki::Formatter
* CGI::Wiki::Formatter::*

= BUGS

Please report bugs using the CPAN Request Tracker at 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-WikiDoc

= AUTHOR

David A Golden (DAGOLDEN)

dagolden@cpan.org

http://dagolden.com/

= COPYRIGHT

Copyright (c) 2005 by David A Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=end wikidoc

