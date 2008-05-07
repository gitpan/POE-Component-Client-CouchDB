use Test::More tests => 2;
use HTTP::Server::Simple::Dispatched;
use JSON;

eval "use HTTP::Server::Simple::Dispatched";
plan skip_all => "HTTP::Server::Simple::Dispatched required to test against"
  if $@;

BEGIN {
	use_ok( 'POE::Component::Client::REST::JSON' );
}

my $server = HTTP::Server::Simple::Dispatched->new(
  port => 5984,
  dispatch => [
    qr{^/_all_dbs$} => sub {
      my $response = shift;
      $response->content_type('application/json');
      $response->content(encode_json(['foo', 'bar', 'baz']));
      return 1;
    }
  ]
);

my $pid = $server->background();

    use POE::Component::Client::REST::JSON;
    use POE;

    # simple CouchDB example

    POE::Session->create(inline_states => {
      _start => sub {
        $poe_kernel->alias_set('foo');
        my $rest = $_[HEAP]->{rest} = POE::Component::Client::REST::JSON->new;
        $rest->call(GET => 'http://localhost:5984/_all_dbs', callback =>
          [$_[SESSION], 'response']);
      },

      response => sub {
        my ($data, $response) = @_[ARG0, ARG1];
        die $response->status_line unless $response->code == 200;

#       print 'Databases: ' . join(', ', @$data) . "\n";
        $poe_kernel->alias_remove('foo');
        $_[HEAP]->{rest}->shutdown();
kill TERM => $pid;
ok($data->[0] eq 'foo' && $data->[1] eq 'bar' && $data->[2] eq 'baz',
  "Correct output");
      },
    });

    $poe_kernel->run();

