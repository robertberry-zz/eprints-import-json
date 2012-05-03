package EPrints::Plugin::Import::JSON;

=head1 NAME

EPrints::Plugin::Import::JSON - JSON Import Plugin

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

Import JSON documents into EPrints. Assumes a hash with appropriate key-value pairs.

=cut

use EPrints::Plugin::Import::TextFile;
use strict;
use warnings;
use autodie;

use JSON;
use TryCatch;

our @ISA = ('EPrints::Plugin::Import::TextFile');

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);

    $self->{name} = "JSON";
    $self->{visible} = "all";
    $self->{produce} = ["list/eprint"];

    my $rc = EPrints::Utils::require_if_exists('JSON');

    unless ($rc) {
        $self->{visible} = '';
        $self->{error} = "Failed to load required module JSON.";
    }

    return $self;
}

=head1 METHODS

=head2 input_fh

Given a filehandle, opens it, reads the JSON document, imports the given array
of EPrints, then returns an EPrints::List of the imported documents.

=cut

sub input_fh {
    my ($self, %opts) = @_;

    my ($json, $prints, @ids);

    {
        # Read entire file into string
        my $fh = $opts{fh};
        local $/ = undef;
        $json = <$fh>;
    }

    try {
        $prints = decode_json($json);
    } catch ($error) {
        $self->error("Malformed JSON, could not import.");
    }

    for my $print (@{$prints}) {
        my $epdata;
        try {
            $epdata = $self->convert_input($print);
        } catch ($err) {
            # ignore errors for now (maybe add some logging)
            next;
        }
        my $dataobj = $self->epdata_to_dataobj($opts{dataset}, $epdata);
        if (defined $dataobj) {
            push @ids, $dataobj->get_id();
        }
    }

    return EPrints::List->new(dataset => $opts{dataset},
                              session => $self->{session},
                              ids => \@ids);
}

=head2 convert_input

Strips any fields that do not belong in EPrints from the JSON document and
produces warnings.

=cut

sub convert_input {
    my ($self, $print) = @_;

    my %clean;
    my $dataset = $self->{session}->get_dataset('archive');

    for my $field (keys %$print) {
        unless ($dataset->has_field($field)) {
            $self->warning("Unrecognized field in document: '$field'.");
            next;
        }

        $clean{$field} = $print->{$field};
    }

    return \%clean;
}

=head1 AUTHOR

Robert J. Berry <robert.berry@liverpool.ac.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 The University of Liverpool

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
