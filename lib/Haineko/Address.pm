package Haineko::Address;
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [];
my $roaccessors = [
    'address',  # (String) Email address
    'user',     # (String) local part of the email address
    'host',     # (String) domain part of the email address
];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$roaccessors );


sub new {
    my $class = shift;
    my $argvs = { @_ }; 

    return undef unless defined $argvs->{'address'};

    if( $argvs->{'address'} =~ m{\A([^@]+)[@]([^@]+)\z} ) {

        $argvs->{'user'} = lc $1;
        $argvs->{'host'} = lc $2;

        map { $argvs->{ $_ } =~ y{`'"<>}{}d } keys %$argvs;
        $argvs->{'address'} = sprintf( "%s@%s", $argvs->{'user'}, $argvs->{'host'} );

        return bless $argvs, __PACKAGE__

    } else {
        return undef;
    }
}

sub canonify {
    my $class = shift;
    my $email = shift;

    return q() unless defined $email;
    return q() if ref $email;

    # "=?ISO-2022-JP?B?....?="<user@example.jp>
    # no space character between " and < .
    $email =~ s{(.)"<}{$1" <};

    my $canonified = q();
    my $addressset = [];
    my $emailtoken = [ split ' ', $email ];

    for my $e ( @$emailtoken ) {
        # Convert character entity; "&lt;" -> ">", "&gt;" -> "<".
        $e =~ s/&lt;/</g;
        $e =~ s/&gt;/>/g;
        $e =~ s/,\z//g;
    }

    if( scalar( @$emailtoken ) == 1 ) {
        push @$addressset, $emailtoken->[0];

    } else {
        foreach my $e ( @$emailtoken ) {

            chomp $e;
            next unless $e =~ m{\A[<]?.+[@][-.0-9A-Za-z]+[.][A-Za-z]{2,}[>]?\z};
            push @$addressset, $e;
        }
    }

    if( scalar( @$addressset ) > 1 ) {

        $canonified = [ grep { $_ =~ m{\A[<].+[>]\z} } @$addressset ]->[0];
        $canonified = $addressset->[0] unless $canonified;

    } else {
        $canonified = shift @$addressset;
    }

    return q() unless defined $canonified;
    return q() unless $canonified;

    $canonified =~ y{<>[]():;}{}d;  # Remove brackets, colons
    $canonified =~ y/{}'"`//d;  # Remove brackets, quotations
    return $canonified;
}

sub damn {
    my $self = shift;
    my $addr = { 
        'user' => $self->user,
        'host' => $self->host,
        'address' => $self->address,
    };
    return $addr;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::Addreess - Create an email address object

=head1 DESCRIPTION

Create an simple object containing a local-part, a domain-part, and an email
address.

=head1 SYNOPSIS

    use Haineko::Address;
    my $e = Haineko::Address->new( 'address' => 'kijitora@example.jp' );

    print $e->user;     # kijitora
    print $e->host;     # example.jp
    print $e->address;  # kijitora@example.jp

    print Data::Dumper::Dumper $e->damn;
    $VAR1 = {
          'user' => 'kijitora',
          'host' => 'example.jp',
          'address' => 'kijitora@example.jp'
        };

=head1 CLASS METHODS

=head2 B<new( 'address' => I<email-address> )>

new() is a constructor of Haineko::Address

    my $e = Haineko::Address->new( 'address' => 'kijitora@example.jp' );

=head2 B<canonify>( I<email-address> )

canonify() picks an email address only (remove a name and comments)

    my $e = Haineko::Address->canonify( 'Kijitora <kijitora@example.jp>' );
    my $f = Haineko::Address->canonify( '<kijitora@example.jp>' );
    print $e;   # kijitora@example.jp
    print $f;   # kijitora@example.jp

=head1 INSTANCE METHODS

=head2 B<damn>

damn() returns instance data as a hash reference

    my $e = Haineko::Address->new( 'address' => 'kijitora@example.jp' );
    my $f = $e->damn;

    print Data::Dumper::Dumper $f;
    $VAR1 = {
          'user' => 'kijitora',
          'host' => 'example.jp',
          'address' => 'kijitora@example.jp'
        };

=head1 REPOSITORY

https://github.com/azumakuniyuki/haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
