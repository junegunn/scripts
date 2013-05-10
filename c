#!/usr/bin/perl -w
use Term::ANSIColor;
use Getopt::Long;
$nomain = 0;
$nonu = 0;
$argv = 0;
GetOptions(
	"nomain|n" => \$nomain,
	"nonu" => \$nonu,
	"argv=s" => \$argv,
);

die "$0 [--nomain] [--argv=<argv>] [--nonu] 'C code...'\n" if(!@ARGV);

$libjg = "$ENV{HOME}/cpp/lib/libjg.a";
$libjg = "" unless (-e $libjg);

my $C = ".$$.c";
my $O = ".$$.out";
my @headers = qw/cstdio cstdlib algorithm iostream iomanip vector list map deque sstream fstream fcntl.h/;

sub intr { unlink $C, $O; }
$SIG{INT} = 'intr';

open CODE, "> $C";
my $code;
$code .= "#include <$_>\n" for(@headers);
$code .= "#include \"libjg.h\"\n" if ($libjg);
$code .= "using namespace std;\n".
		($nomain ? "" : "\nint main(int argc, char **argv) {\n");
my @lines;
push @lines, split("\n", $_) for(@ARGV);
shift @lines unless($lines[0]);
$code .= ($nomain ? "" : "\t")."$_\n" for(@lines);
$code .= "}\n" unless($nomain);
print CODE $code;
close CODE;

print colored ":: CODE\n", "BOLD BLUE";
open CODE, "< $C";
@code = <CODE>;
$ln = 1;
for(@code) {
	$lstr = (!$nonu) ? (sprintf "%3d  ", $ln++) : "";
	print colored $lstr, "GREEN";
	print;
}
close CODE;
print "\n";

$cmd =  "g++ -o $O $C";
$cmd .= " \"$libjg\" -I\"$ENV{HOME}/cpp/lib\"" if ($libjg);
system $cmd;

if ($? == 0) {
	print colored ":: RESULT\n", "BOLD BLUE";
	$cmd = "./$O ";
	$cmd .= $argv if ($argv);
	system $cmd;
	print colored "\n:: FINISHED\n", "BOLD WHITE";
}

&intr;

