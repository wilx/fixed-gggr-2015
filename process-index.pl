use strict;
use XML::XPath;
use XML::XPath::XMLParser;
use Text::CSV::Encoded;
use IO::File;
use IO::Handle;
use Data::Dumper;

binmode(STDOUT, ":encoding(UTF-8)");

my $inputf = IO::File->new();
$inputf->open("gggr-index.xml", "<");
$inputf->binmode(":encoding(UTF-8)");
my $xml;
{
    local $/;
    $xml = <$inputf>;
}
my $xp = XML::XPath->new($xml);
my @value_nodes = $xp->find(
    '//page/text[@font = \'4\' and @height = \'10\']')->get_nodelist;
my @value_text = map {$_->string_value} @value_nodes;

# Count from 2nd element all elements that are numbers. This will be the
# column count for this table.

my $columns;
for ($columns = 0; $value_text[$columns + 1] =~ /^\d/; ++$columns)
{}
++$columns;
print STDERR "detected ", $columns, " columns\n";

# Store the index rows.

my $csv = Text::CSV::Encoded->new({encoding => undef, binary => 1});
my $f = IO::File->new();
$f->open("global-index.csv", ">");

my $size = scalar @value_text;
for (my $i = 0; $i < $size; $i += $columns) {
    my @row = @value_text[$i..($i + $columns - 1)];

    $csv->print($f, \@row);
    print $f "\n";
}
