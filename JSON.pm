package EPrints::Plugin::Import::JSON;

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

    my $self->{name} = "JSON";
    my $self->{visible} = "all";
    my $self->{produce} = ["list/eprint"];

    my $rc = EPrints::Utils::require_if_exists('JSON');

    unless ($rc) {
        $self->{visible} = '';
        $self->{error} = "Failed to load required module JSON.";
    }
}

sub input_fh {
    my ($self, %opts) = @_

    my ($json, $prints, @ids);

    $json = <$opts{fh}>;
    $prints = decode_json $json;

    for my $print (@{$prints}) {
        try {
            my $epdata = $self->convert_input($print);
        } catch ($err) {
            # ignore errors for now (maybe add some logging)
            next;
        }

        my $dataobj = $self->epdata_to_dataobj($opts{dataset}, $epdata);
        if (defined $dataobj) {
            push @ids, $dataobj->get_id;
        }
    }

    return EPrints::List->new(dataset => $opts{dataset},
                              session => $self->{session},
                              ids => \@ids);
}

=method convert_input

Removes unwanted information from the JSON document and reports warnings.

todo: add more validation. validate that fields with 'multiple' set on
      metafield are indeed lists, not scalars.

=cut

sub convert_input {
    my ($self, $print) = @_;

    my %clean;
    my $dataset = $plugin->{session}->get_dataset('archive');

    for my $field (keys %{$print}) {
        unless ($dataset->has_field($field)) {
            $self->warning("Unrecognized field in document: '{$field}'.");
            next;
        }

        $clean{$field} = $print->{field};
    }

    return \%clean;
}
