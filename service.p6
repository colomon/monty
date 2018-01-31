use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Routes;

%*ENV<MONTY_HOST> = "192.168.1.169";
%*ENV<MONTY_PORT> = 20000;

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<MONTY_HOST> ||
        die("Missing MONTY_HOST in environment"),
    port => %*ENV<MONTY_PORT> ||
        die("Missing MONTY_PORT in environment"),
    application => routes(),
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<MONTY_HOST>:%*ENV<MONTY_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
