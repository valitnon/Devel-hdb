package Devel::hdb::Client;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;

our $VERSION = "1.0";

use Exception::Class (
        'Devel::hdb::Client::Exception' => {
            fields => [qw( http_code http_message http_content )],
        },
);

my $JSON ||= JSON->new();

sub new {
    my $class = shift;
    my %params = @_;

    my %self;
    $self{base_url} = delete $params{url};
    $self{base_url} =~ s{/$}{};

    $self{http_client} = LWP::UserAgent->new();
    $self{http_client}->agent("Devel::hdb::Client/$VERSION");

    return bless \%self, $class;
}

sub stack {
    my $self = shift;

    my $response = $self->_GET('stack');
    _assert_success($response, q(Can't get stack position));
    return $JSON->decode($response->content);
}

sub _base_url { shift->{base_url} }
sub _http_client { shift->{http_client} }

sub _http_request {
    my $self = shift;
    my $method = shift;
    my $url_ext = shift;
    my $body = shift;

    my $url = join('/', $self->_base_url, $url_ext);

    my $request = HTTP::Request->new($method => $url);
    $request->content_type('application/json');

    if (defined $body) {
        $body = $JSON->encode($body) if ref($body);
        $request->content($body);
    }

    my $response = $self->_http_client->request($request);
    return $response;
}

sub _GET {
    my $self = shift;
    $self->_http_request('GET', @_);
}

sub _POST {
    my $self = shift;
    $self->_http_request('POST', @_);
}

sub _HEAD {
    my $self = shift;
    $self->_http_request('HEAD', @_);
}

sub _DELETE {
    my $self = shift;
    $self->_http_request('DELETE', @_);
}

sub _assert_success {
    my $response = shift;
    my $error = shift;
    unless ($response->is_success) {
        Devel::hdb::Client::Exception->throw(
                error => $error,
                http_code => $response->code,
                http_message => $response->message,
                http_content => $response->content,
        );
    }
}

1;