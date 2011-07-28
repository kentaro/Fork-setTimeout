package Fork::setTimeout;
use 5.008001;
use strict;
use warnings;
use Time::HiRes qw(usleep);

our $VERSION = '0.01';

use parent qw(Exporter);
our @EXPORT = qw(
    setTimeout
    clearTimeout
);

use Config;
use POSIX ':sys_wait_h';
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

my $subs = {};
sub sigchld {
    while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
        if ( my $sub = delete $subs->{$pid} ) {
            $sub->();
        }
    }
}

sub setTimeout (&$) {
    my ($sub, $time) = @_;
    my $self = __PACKAGE__->new;


    # parent
    if (my $pid = fork()) {
        $subs->{$pid} = $sub;
        $SIG{CHLD} = \&sigchld;
        $self->pid($pid);
        return $self;
    }

    # child
    elsif ($pid == 0) {
        $SIG{CHLD} = 'DEFAULT';
        usleep $time * 1000;
        exit 0;
    }

    else {
        die "fork failed: $!";
    }
}

sub clearTimeout ($) {
    my ($self) = @_;
    delete $subs->{$self->pid};
    kill $TERMSIG, $self->pid;
    $self->pid(undef);
}

sub new {
    my ($class, $args) = @_;
    bless {
        parent_pid => $$,
        %{$args || {}},
    }, $class;
}

sub pid {
    my ($self, $pid) = @_;
    $self->{pid} = $pid if defined $pid;
    $self->{pid};
}

sub is_parent {  defined shift->pid }
sub is_child  { !defined shift->pid }

sub DESTROY {
    my $self = shift;

    if (!$self->is_child && defined $self->pid) {
        local $?;

        while (waitpid($self->pid, 0) == 0) {}

        if ( my $sub = delete $subs->{$self->pid} ) {
            $sub->();
        }

        $self->pid(undef);
    }
}

!!1;

__END__

=encoding utf8

=head1 NAME

Fork::setTimeout - Implementation of setTimeout() function in
JavaScript

=head1 SYNOPSIS

  use Fork::setTimeout;

  my $timer = setTimeout(sub { ... }, 10);
  clearTimeout($timer);

=head1 DESCRIPTION

An emulation of setTimeout() funcion in JavaScript using fork(2).

=head1 METHODS

=head2 setTimeout( I<$code>, I<$msec> )

  my $timer = setTimeout(sub { ... }, 10);

Dispatches C<$code> after C<$msec> micro seconds.

You should store the return value, C<$timer>, in some lexical variable
to wait for child process to finish dispatching C<$code>.

=head2 clearTimeout( I<$timer> )

  clearTimeout($timer);

Kills the child process and clear C<$timer> out.

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
