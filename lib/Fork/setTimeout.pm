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
use POSIX;
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

sub setTimeout (&$) {
    my ($sub, $time) = @_;
    my $self = __PACKAGE__->new;

    # parent
    if (my $pid = fork()) {
        $self->pid($pid);
        return $self;
    }

    # child
    elsif ($pid == 0) {
        usleep $time;
        eval { $sub->() };
        die $@ if $@;
        exit 0;
    }

    else {
        die "fork failed: $!";
    }
}

sub clearTimeout ($) {
    my ($self) = @_;
    kill $TERMSIG, $self->pid;
    $self->pid(undef);
}

sub new {
    my ($class, $pid) = @_;
    bless {
        pid        => $pid,
        parent_pid => $$,
    }, $class;
}

sub pid {
    my ($self, $pid) = @_;
    $self->{pid} = $pid if defined $pid;
    $self->{pid};
}

sub DESTROY {
    my $self = shift;

    if (defined $self->pid) {
        local $?;
        while (waitpid($self->pid, 0) == 0) {}
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
