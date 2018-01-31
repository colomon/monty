use Cro::HTTP::Router;
use HTML::Tag::Tags;
use HTML::Tag::Macro::List;
use HTML::Tag::Macro::Table;
use OO::Monitors;

my $ip = "192.168.1.169:20000";

my $solo = HTML::Tag::img.new(src => "http://www.harmonyware.com/pictures/solo.jpg",
                              width => 300,
                              height => 300);
my $smiley = HTML::Tag::img.new(src => "http://www.harmonyware.com/pictures/smiley.png",
                                width => 300,
                                height => 300);
my $frown = HTML::Tag::img.new(src => "http://www.harmonyware.com/pictures/frown.png",
                               width => 300,
                               height => 295);
my $header = q:to/END/;
    <h1> monty </h1>
    <style>
      table, th, td {
          font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
      }
      th, td {
          padding: 5px;
      }
      td { text-align: center }
      td:nth-child(0) { text-align: right }
      tr:hover {background-color: #f5f5f5;}
    </style>
END

monitor Scorekeeper {
    has $.switched-and-won = 0;
    has $.switched-and-lost = 0;
    has $.stayed-and-won = 0;
    has $.stayed-and-lost = 0;
    has %.games-seen;
    
    method register-game($id, Bool :$switched, Bool :$won) {
        return if %.games-seen{$id}:exists;
        %.games-seen{$id} = 1;
        
        if $switched {
            if $won {
                $!switched-and-won++;
            } else {
                $!switched-and-lost++;
            }
        } else {
            if $won {
                $!stayed-and-won++;
            } else {
                $!stayed-and-lost++;
            }
        }
    }

    method stats {
        $.switched-and-won, $.switched-and-lost, $.stayed-and-won, $.stayed-and-lost;
    }
}

my $scorekeeper = Scorekeeper.new;

sub result-table {
    my ($switched-and-won, $switched-and-lost, $stayed-and-won, $stayed-and-lost) = $scorekeeper.stats;
    
    my $result-table = HTML::Tag::Macro::Table.new;
    my @data = "", "Won", "Lost";
    $result-table.row(:header, @data);
    @data = "Stayed", ~$stayed-and-won, ~$stayed-and-lost;
    $result-table.row(@data);
    @data = "Switched", ~$switched-and-won, ~$switched-and-lost;
    $result-table.row(@data);

    $result-table;
}

sub encode-roll($roll) {
    my $big-num = (10000..1000000000000).roll;
    $big-num -= $big-num % 8;
    # dd $big-num.base(2);
    $big-num += $roll * 2;
    # dd $big-num.base(2);
    $big-num += (0..1).roll;
    $big-num;
}

sub decode-roll($big-num) {
    # dd $big-num.base(2);
    my $roll = ($big-num +& 0b110) div 2;
    # dd $roll;
    $roll;
}

sub decide-reveal($roll, $choice, $entropy) {
    my $possible-reveals = (1, 2, 3).Set (-) (+$roll, +$choice).Set;
    if $possible-reveals > 1 {
        $possible-reveals.keys.sort[$entropy % 2];
    } else {
        $possible-reveals.keys[0];
    }
}

sub routes() is export {
    route {
        get -> {
            my $roll = (1..3).pick;
            my $encoded-roll = encode-roll($roll);
            
            my $cups-table = HTML::Tag::Macro::Table.new;
            my @data = (1..3).map({ HTML::Tag::a.new(href => "http://$ip/$encoded-roll/pick/$_", 
                                                     text => $solo) });
            $cups-table.row(@data);
            
            content 'text/html', $header ~ "Please pick a cup<br><br>" ~ $cups-table.render;
        }

        get -> $encoded-roll, "pick", $choice {
            my $roll = decode-roll(+$encoded-roll);
            my $reveal = decide-reveal($roll, $choice, $encoded-roll);
            
            my $cups-table = HTML::Tag::Macro::Table.new;
            my @data = (1..3).map({ HTML::Tag::a.new(href => "http://$ip/$encoded-roll/pick/$choice/pick/$_", 
                                                     text => $solo) });
            @data[$reveal - 1] = $frown;
            $cups-table.row(@data);
            @data = "" xx 3;
            @data[$choice - 1] = "your initial choice";
            $cups-table.row(@data);
            @data = "" xx 3;
            $cups-table.row(@data);
            
            content 'text/html', $header ~ "Please pick a cup (either stay the same or go for the other)<br><br>" ~ $cups-table.render;
        }

        get -> $encoded-roll, "pick", $choice, "pick", $second-choice {
            my $roll = decode-roll(+$encoded-roll);
            my $reveal = decide-reveal($roll, $choice, $encoded-roll);
            
            my $cups-table = HTML::Tag::Macro::Table.new;
            my @data = $solo xx 3;
            @data[$reveal - 1] = $frown;
            @data[$second-choice - 1] = ($second-choice == $roll) ?? $smiley !! $frown;
            $cups-table.row(@data);
            @data = "" xx 3;
            @data[$choice - 1] = "your initial choice";
            $cups-table.row(@data);
            @data = "" xx 3;
            @data[$second-choice - 1] = "your final choice";
            $cups-table.row(@data);
            
            my $switched = $choice != $second-choice;
            # dd $switched;
            my $won = $roll == $second-choice;
            # dd $won;
            $scorekeeper.register-game($encoded-roll, :$switched, :$won);
            my $result = "You " ~ ($switched ?? "switched" !! "stayed") ~ " and "
                         ~ ($won ?? "won!" !! "lost.") ~ "<br>"
                         ~ HTML::Tag::a.new(href => "http://$ip", text => "Play again?").render ~ "<br>"
                         ~ result-table().render;
            
            content 'text/html', $header ~ "<br><br>" ~ $cups-table.render ~ $result;
        }

    }
}

