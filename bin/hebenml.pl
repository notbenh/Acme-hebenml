#!/usr/bin/env perl 
use strict;
use warnings;
use YAML qw{LoadFile};

foreach my $file (@ARGV) {
  print parse_doc('',LoadFile($file));
}

use Data::Dumper;
sub parse_tag {
  my ($name,@attr) = split /\s+/, shift;

  sub rpk { sprintf q{%s='%s'}, $_[0] =~ m/^[#](.*)/ ? (id    => $1)   # id shortcut
                              : $_[0] =~ m/^[.](.*)/ ? (class => $1)   # class shortcut
                              :                        ($_[0] => $_[1])# everything else
  }
  sub walk { 
    my @out;
    while (my $x = shift @_) {
      my ($name) = $x =~ m/^!?(.*)/;
      push @out, rpk( $name && $_[0] && $_[0] !~ m/^!/ 
                    ? ($name, shift)
                    : $name 
                    );
    }
    unshift @out, '' if @out; # indent from the tag name if there are any attrs
    return @out;
  };
  
  sprintf qq{<%s%s>%%s%%s</%1\$s>\n} # TODO it might be nice for tags that don't have content to use a <tag /> style
        , $name
        , join ' ', grep{defined} walk(@attr);
}

sub parse_doc {
  my $indent = shift; # TODO this is a hack and you know it
  my $stuff  = ref($_[0]) ? $_[0] : \@_;
  my $out = '';
  foreach my $item ( @$stuff ) {
    $item = {$item => ''} unless ref($item);
    while( my ($tag, $content) = each %$item ) {
      $out .= sprintf qq{\n%s%s}
                    , $indent
                    , sprintf( parse_tag($tag)
                             , ref($content) ? (parse_doc(qq{  $indent}, $content), $indent)
                                             : ($content =~ m/\n/ ? do{ chomp $content; 
                                                                        $content =~ s/\n/\n$indent  /gx; 
                                                                        qq{\n$indent  $content\n$indent} 
                                                                      }
                                                                  : qq{$content}
                                               , '' 
                                               )
                             )
                    ; 
    }
  }
  return $out;
}

