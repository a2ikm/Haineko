#  _   _         ____                                      
# | | | |  _ _  |  _ \ ___  ___ _ __   ___  _ __  ___  ___ 
# | |_| | (_|_) | |_) / _ \/ __| '_ \ / _ \| '_ \/ __|/ _ \
# |  _  |  _ _  |  _ <  __/\__ \ |_) | (_) | | | \__ \  __/
# |_| |_| (_|_) |_| \_\___||___/ .__/ \___/|_| |_|___/\___|
#                              |_|                         
package Haineko::Response;
use strict;
use warnings;
use Class::Accessor::Lite;

my $rwaccessors = [
    'dsn',      # (String) Delivery Status Notifier
    'code',     # (Integer) SMTP reply code
    'error',    # (Integer)
    'command',  # (String) SMTP Command
    'message',  # (ArrayRef) Reply messages
    'greeting', # (ArrayRef) EHLO Greeting response
];
my $roaccessors = [];
my $woaccessors = [];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );

my $Replies = {
    'conn' => {
        'ok' => {
            'dsn' => undef,
            'code' => 220,
            'message' => [ 'ESMTP Haineko' ],
        },
        'no-checkrelay' => {
            'dsn' => '5.7.4',
            'code' => 500,
            'message' => [ 'Security features not supported' ],
        },
        'access-denied' => {
            'dsn' => '5.7.1',
            'code' => 500,
            'message' => [ 'Access denied' ],
        },
        'cannot-connect' => {
            'dsn' => undef,
            'code' => 400,
            'message' => [ 'Cannot connect SMTP Server' ],
        },
    },
    'ehlo' => {
        'invalid-domain' => {   # 501 5.0.0 Invalid domain name
            'dsn' => '5.0.0',
            'code' => 501,
            'message' => [ 'Invalid domain name' ],
        },
        'require-domain' => {   # 501 5.0.0 EHLO requires domain address
            'dsn' => '5.0.0',
            'code' => 501,
            'message' => [ 'EHLO requires domain address' ],
        },
        'helo-first' => {       # 503 5.0.0 Polite people say HELO first
            'dsn' => '5.0.0',
            'code' => 503,
            'message' => [ 'Polite people say HELO first' ],
        },
    },
    'auth' => {
        'cannot-decode' => {    # 501 5.5.4 cannot decode AUTH parameter
            'dsn' => '5.5.4',
            'code' => 501,
            'message' => [ 'cannot decode AUTH parameter' ],
        },
        'auth-failed' => {      # 535 5.7.0 authentication failed
            'dsn' => '5.7.0',
            'code' => 535,
            'message' => [ 'authentication failed' ],
        },
        'unavailable-mech' => { # 504 5.3.3 AUTH mechanism * not available
            'dsn' => '5.3.3',
            'code' => 504,
            'message' => [ 'Unavailable AUTH mechanism' ],
        },
        'no-auth-mech' => {     # 501 5.5.2 AUTH mechanism must be specified
            'dsn' => '5.5.2',
            'code' => 501,
            'message' => [ 'AUTH mechanism must be specified' ],
        },
    },
    'mail' => {
        'ok' => {
            'dsn' => '2.1.0',
            'code' => 250,
            'message' => [ 'Sender ok' ],
        },
        'sender-specified' => { # 503 5.5.0 Sender already specified
            'dsn' => '5.5.0',
            'code' => 503,
            'message' => [ 'Sender already specified' ],
        },
        'mesg-too-big' => {     # 552 5.2.3 Message size exceeds fixed maximum message size (10485760)
            'dsn' => '5.2.3',
            'code' => 552,
            'message' => [ 'Message size exceeds fixed maximum message size' ],
        },
        'domain-required' => {  # 553 5.5.4 <*>... Domain name required for sender address *
            'dsn' => '5.5.4',
            'code' => 553,
            'message' => [ 'Domain name required for sender address' ],
        },
        'syntax-error' => {     # 501 5.5.2 Syntax error in parameters scanning "FROM"
            'dsn' => '5.5.2',
            'code' => 501,
            'message' => [ 'Syntax error in parameters scanning "FROM"' ],
        },
        'domain-does-not-exist' => {    # 553 5.1.8 <*>... Domain of sender address * does not exist
            'dsn' => '5.1.8',
            'code' => 553,
            'message' => [ 'Domain of sender address does not exist' ],
        },
        'need-mail' => {    # 503 5.0.0 Need MAIL before RCPT
            'dsn' => '5.0.0',
            'code' => 503,
            'message' => [ 'Need MAIL before RCPT' ],
        },
        'non-ascii' => {    # non-ASCII addresses are not permitted
            'dsn' => '5.6.7',
            'code' => 553,
            'message' => [ 'non-ASCII address is not permitted' ],
        },
    },
    'rcpt' => {
        'ok' => {           # 250 2.1.5 <*@*>... Recipient ok
            'dsn' => '2.1.5',
            'code' => 250,
            'message' => [ 'Recipient ok' ],
        },
        'syntax-error' => { # 501 5.5.2 Syntax error in parameters scanning "TO"
            'dsn' => '5.5.2',
            'code' => 501,
            'message' => [ 'Syntax error in parameters scanning "TO"' ],
        },
        'address-required' => {     # 553 5.0.0 <>... User address required
            'dsn' => '5.0.0',
            'code' => 553,
            'message' => [ 'User address required' ],
        },
        'too-many-recipients' => {  # 452 4.5.3 Too many recipients
            'dsn' => '4.5.3',
            'code' => 452,
            'message' => [ 'Too many recipients' ],
        },
        'is-not-emailaddress' => {
            'dsn' => '5.1.5',
            'code' => 553,
            'message' => [ 'Recipient address is invalid' ],
        },
        'need-rcpt' => {    # 503 5.0.0 Need RCPT (recipient)
            'dsn' => '5.0.0',
            'code' => 503,
            'message' => [ 'Need RCPT (recipient)' ],
        },
        'rejected' => {
            'dsn' => '5.7.1',
            'code' => 553, 
            'message' => [ 'Recipient address is not permitted' ],
        },
    },
    'data' => {
        'ok' => {   # 250 2.0.0 r5H6WfHC023944 Message accepted for delivery
            'dsn' => '2.0.0',
            'code' => 250,
            'message' => [ 'Message accepted for delivery' ],
        },
        'enter-mail' => {   # 354 Enter mail, end with "." on a line by itself
            'dsn' => undef,
            'code' => 354,
            'message' => [ 'Enter mail' ],
        },
        'empty-body' => {
            'dsn' => '5.6.0',
            'code' => 500,
            'message' => [ 'Message body is empty' ],
        },
        'empty-subject' => {
            'dsn' => '5.6.0',
            'code' => 500,
            'message' => [ 'Subject header is empty' ],
        },
        'discard' => {
            'dsn' => undef,
            'code' => 200,
            'message' => [ 'Discard' ],
        },
    },
    'rset' => {
        'ok' => {   # 250 2.0.0 Reset state
            'dsn' => '2.0.0',
            'code' => 250,
            'message' => [ 'Reset state' ],
        },
    },
    'vrfy' => { # 252 2.5.2 Cannot VRFY user; try RCPT to attempt delivery (or try finger)
        'cannot-vrfy' => {
            'dsn' => '2.5.2',
            'code' => 252,
            'message' => [ 'Cannot VRFY user; try RCPT to attempt delivery (or try finger)' ],
        },
    },
    'verb' => { # 502 5.7.0 Verbose unavailable
        'verb-unavailable' => {
            'dsn' => '5.7.0',
            'code' => 502,
            'message' => [ 'Verbose unavailable' ],
        },
    },
    'noop' => { # 250 2.0.0 OK
        'ok' => {
            'dsn' => '2.0.0',
            'code' => 250,
            'message' => [ 'OK' ],
        },
    },
    'quit' => {
        'ok' => {
            'dsn' => '2.0.0',
            'code' => 221,
            'message' => [ 'closing connection' ],
        },
    },

};

sub new {
    my $class = shift;
    my $argvs = { @_ };

    return bless $argvs, __PACKAGE__;
}

sub r {
    my $class = shift;
    my $esmtp = shift || return undef;  # SMTP Command
    my $rname = shift || return undef;  # Response name
    my $mesgs = shift || [];            # Additional messages
    my $argvs = {};

    return undef unless grep { $esmtp eq $_ } keys %$Replies;
    return undef unless grep { $rname eq $_ } keys %{ $Replies->{ $esmtp } };

    for my $e ( keys %{ $Replies->{ $esmtp }->{ $rname } } ) {

        $argvs->{ $e } = $Replies->{ $esmtp }->{ $rname }->{ $e };
    }

    $argvs->{'message'} = $mesgs if scalar @$mesgs;
    $argvs->{'command'} = uc $esmtp;
    $argvs->{'error'} = $argvs->{'code'} =~ m/\A[45]\d+/ ? 1 : 0;
    return __PACKAGE__->new( %$argvs );
}

sub p {
    my $class = shift;
    my $argvs = { @_ };
    my $lines = [];
    my $nekor = { 
        'dsn'     => undef,
        'code'    => $argvs->{'code'} // undef,
        'error'   => 0,
        'message' => [],
        'command' => uc( $argvs->{'command'} // q() ),
    };

    $lines = ref $argvs->{'message'} eq 'ARRAY' ? $argvs->{'message'} : [ $argvs->{'message'} ];
    while( my $r = shift @$lines ) {

        chomp $r;
        $nekor->{'dsn'} = $1 if $r =~ /\b([2345][.]\d[.]\d+)\b/;
        $nekor->{'code'} = $1 if $r =~ /\b([2345]\d\d)\b/;
        push @{ $nekor->{'message'} }, $r;
    }

    $nekor->{'error'} = 1 if( defined $nekor->{'dsn'} && $nekor->{'dsn'} =~ /\A[45]/ );
    $nekor->{'error'} = 1 if( defined $nekor->{'code'} && $nekor->{'code'} =~ /\A[45]/ );
    return __PACKAGE__->new( %$nekor );
}

sub damn {
    my $self = shift;
    my $smtp = {};

    for my $e ( @$rwaccessors, @$roaccessors ) {
        next if $e eq 'greeting';
        $smtp->{ $e } = $self->{ $e };
    }
    return $smtp;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::Response - SMTP Response class

=head1 DESCRIPTION

SMTP Response class contain SMTP status code, D.S.N. value, response messages,
and SMTP command.

=head1 SYNOPSIS

    use Haineko::Response;
    my $e = Haineko::Response->r( 'ehlo', 'invalid-domain' );

    print $e->dsn;      # 5.0.0
    print $e->code;     # 500

    warn Dumper $e->message;
    $VAR1 = [
        'Invalid domain name'
    ];

    my $v = { 'command' => 'RCPT', message => [ '550 5.1.1 User unknown' ] };
    my $f = Haineko::Response->p( %$v );

    print $e->dsn;      # 5.1.1
    print $e->code;     # 550

    warn Dumper $e->message;
    $VAR1 = [
        '550 5.1.1 User unknown'
    ];


=head1 CLASS METHODS

=head2 B<new( I<%arguments> )>

new() is a constructor of Haineko::Response

=head2 B<r( I<SMTP Command>, I<Error type> )

r() creates an Haineko::Response object from specified SMTP command and error type.

=head2 B<p( I<%arguments> )>

p() creates an Haineko::Response object from SMTP response message.

    my $v = { 'command' => 'MAIL', message => [ '552 5.2.2 Mailbox full' ] };
    my $f = Haineko::Response->p( %$v );

    print $e->dsn;      # 5.2.2
    print $e->code;     # 552

    warn Dumper $e->message;
    $VAR1 = [
        '552 5.2.2 Mailbox full'
    ];

=head1 INSTANCE METHODS

=head2 B<damn>

damn() returns instance data as a hash reference

    my $v = { 'command' => 'DATA', message => [ '551 5.7.1 Refused' ] };
    my $f = Haineko::Response->p( %$v );

    print Data::Dumper::Dumper $e->damn;
    $VAR1 = {
        'dsn' => '5.7.1',
                'error' => 1,
                'code' => '551',
                'message' => [
                                '551 5.7.1 Refused'
                             ],
                'command' => 'DATA'
    }

=head1 REPOSITORY

https://github.com/azumakuniyuki/haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
