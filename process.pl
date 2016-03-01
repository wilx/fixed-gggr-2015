use strict;
use XML::XPath;
use XML::XPath::XMLParser;
use Text::CSV::Encoded;
use IO::File;
use IO::Handle;
use Regexp::Common;
use Data::Dumper;

binmode(STDOUT, ":encoding(UTF-8)");

my $inputf = IO::File->new();
$inputf->open("gggr.xml", "<");
$inputf->binmode(":encoding(UTF-8)");
my $xp = XML::XPath->new($inputf);
my $pages = $xp->find('//page');

foreach my $page ($pages->get_nodelist) {
    my @table_title_nodes = $page->find('./text[@font = \'1\']')->get_nodelist;
    my $table_title = $table_title_nodes[0]->string_value;
    print STDERR "table title: ", $table_title, "\n";
    my @value_nodes = $page->find('./text[@font = \'5\' and @height = \'10\']'
                                  . '| ./text[@font = \'7\' and @height = \'11\']')->get_nodelist;
    my @value_text = map {$_->string_value} @value_nodes;

    # Count from 2nd element all elements that are numbers. This will be the
    # column count for this table.

    my $columns;
    for ($columns = 0; $value_text[$columns + 1] =~ /^\d/; ++$columns)
    {}
    ++$columns;
    print STDERR "detected ", $columns, " columns\n";

    # Create separate CSV file for each table.

    my $file_name = $table_title;
    $file_name =~ s/.*?:\s*(\S.*)/$1/;
    $file_name =~ s/\s+/-/g;    
    my $table_name = $file_name;
    $file_name .= '.csv';
    my $csv = Text::CSV::Encoded->new({encoding => undef, binary => 1});
    my $f = IO::File->new();
    $f->open("$file_name", ">");
    #$f->binmode(":encoding(UTF-8)");

    # Output all rows.

    # Each record specifies columns of F/M ratio, F/M ratio truncated and
    # rank.
    
    my %table_info = (
        'Enrolment-in-primary-education' => [3, 4, 5],
        'Enrolment-in-secondary-education' => [3, 4, 5],
        'Enrolment-in-tertiary-education' => [3, 4, 5],
        'Estimated-earned-income' => undef,
        'Healthy-life-expectancy' => [3, 4, 5],
        'Labour-force-participation' => [3, 4, 5],
        'Legislators,-senior-officials-and-managers' => [3, 4, 5],
        'Literacy-rate' => [3, 4, 5],
        'Professional-and-technical-workers' => [3, 4, 5],
        'Sex-ratio-at-birth' => undef,
        'Wage-equality-survey' => [2, 3, 4],
        'Women-in-ministerial-positions' => [3, 4, 5],
        'Women-in-parliament' => [3, 4, 5],
        'Years-with-female-head-of-state' => [3, 4, 5]
        );

    my $size = scalar @value_text;
    for (my $i = 0; $i < $size; $i += $columns) {
        my @row = @value_text[$i..($i + $columns - 1)];
        #print STDERR "row: ", Dumper(\@row), "\n";

        if ($table_name eq 'Estimated-earned-income') {
            $row[1] =~ s/,//g;
            $row[2] =~ s/,//g;
            $row[3] =~ s/,//g;
            $row[4] =~ s/,//g;
        }

        # Try to compute ratio corrected for instances where F/M ratio > 1.
        if (exists $table_info{$table_name}
            && defined $table_info{$table_name}) {
            my @cols = @{$table_info{$table_name}};
            my $fmr = $row[$cols[0]];
            my $orig_fmr = $fmr;
            my $diff = 0;
            if ($fmr =~ /$RE{num}{real}/) {
                $fmr += 0.0;
                if ($fmr > 1) {
                    $fmr = 1.0 / $fmr;
                }
                $diff = $fmr - $orig_fmr;
                if ($diff != 0) {
                    print STDERR ("", $row[0], ": ", $orig_fmr, " -> ", (sprintf "%5.2f", $fmr),
                                  " (delta ", (sprintf "%5.2f", $diff), ")\n");
                }
            }
            push @row, $fmr;
            #push @row, $diff;
        }
        
        $csv->print($f, \@row);
        print $f "\n";
    }
}
