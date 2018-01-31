use Cro::HTTP::Router;
use HTML::Tag::Tags;
use HTML::Tag::Macro::List;
use HTML::Tag::Macro::Table;

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

sub routes() is export {
    route {
        get -> {
            my $roll = (1..3).pick;
            
            my $cups-table = HTML::Tag::Macro::Table.new;
            my @data = (1..3).map({ HTML::Tag::a.new(href => "http://$ip/$roll/pick/$_", 
                                                     text => $solo) });
            $cups-table.row(@data);
            
            content 'text/html', $header ~ "Please pick a cup<br><br>" ~ $cups-table.render;
        }

        get -> $roll, "pick", $choice {
            dd $roll;
            # dd $choice;
            my $reveal = ((1, 2, 3).Set (-) (+$roll, +$choice).Set).pick;
            # dd $reveal;
            
            my $cups-table = HTML::Tag::Macro::Table.new;
            my @data = (1..3).map({ HTML::Tag::a.new(href => "http://$ip/$roll/pick/$choice/pick/$_", 
                                                     text => $solo) });
            @data[$reveal - 1] = $frown;
            $cups-table.row(@data);
            @data = "" xx 3;
            @data[$choice - 1] = "your initial choice";
            $cups-table.row(@data);
            
            content 'text/html', $header ~ "Please pick a cup (either stay the same or go for the other)<br><br>" ~ $cups-table.render;
        }

        get -> $roll, "pick", $choice, "pick", $second-choice {
            dd $second-choice;
            my $reveal = ((1, 2, 3).Set (-) (+$roll, +$choice).Set).pick;
            
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
            
            content 'text/html', $header ~ "<br><br>" ~ $cups-table.render;
        }

    }
}

