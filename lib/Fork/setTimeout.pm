package Fork::setTimeout;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

use parent qw(Exporter);
our @EXPORT = qw(
    setTimeout
    clearTimeout
);

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
        sleep $time / 1000;
        eval { $sub->() };
        exit 0;
    }

    else {
        die "fork failed: $!";
    }
}

sub clearTimeout ($) {
    my ($self) = @_;
    kill 9, $self->pid;
    $self->pid(undef);
}

sub new {
    my ($class, $pid) = @_;
    bless { pid => $pid }, $class;
}

sub pid {
    my ($self, $pid) = @_;
    $self->{pid} = $pid if defined $pid;
    $self->{pid};
}

sub DESTROY {
    my $self = shift;

    if ($self->pid) {
        my $kid = waitpid($self->pid, 0);
        $self->pid(undef);
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Fork::setTimeout -

=head1 SYNOPSIS

  use Fork::setTimeout;

=head1 DESCRIPTION

Fork::setTimeout is

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
