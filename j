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

die "$0 [--nomain] [--argv=<argv>] [--nonu] 'java code...'\n" if(!@ARGV);

$libjg = "$ENV{HOME}/cpp/lib/libjg.a";
$libjg = "" unless (-e $libjg);

my $CLASS = "J$$";
my $J = "$CLASS.java";
my $O = "$CLASS.class";
my @headers = qw/java.io.* java.util.* java.sql.* java.lang.*/;

sub intr { unlink $J, $O; }
$SIG{INT} = 'intr';

open CODE, "> $J";
my $code;
$code .= "import $_;\n" for(@headers);
$code .= "\npublic class $CLASS {\n";
$code .= "\tpublic static void p(String s) {\n";
$code .= "\t\tSystem.out.println(s);\n";
$code .= "\t}\n\n";
$code .= ($nomain ? "" : "\tpublic static void main(String[] argv) {\n");
my @lines;
push @lines, split("\n", $_) for(@ARGV);
shift @lines unless($lines[0]);
$code .= ($nomain ? "" : "\t")."\t$_\n" for(@lines);
$code .= "\t}\n" unless($nomain);
$code .= "}\n";
print CODE $code;
close CODE;

print colored ":: CODE\n", "BOLD BLUE";
open CODE, "< $J";
@code = <CODE>;
$ln = 1;
for(@code) {
	$lstr = (!$nonu) ? (sprintf "%3d  ", $ln++) : "";
	print colored $lstr, "GREEN";
	print;
}
close CODE;
print "\n";

$cmd =  "javac $J";
system $cmd;

if ($? == 0) {
	print colored ":: RESULT\n", "BOLD BLUE";
	$cmd = "java -cp .:$ENV{CLASSPATH} $CLASS ";
	$cmd .= $argv if ($argv);
	system $cmd;
	print colored "\n:: FINISHED\n", "BOLD WHITE";
}

&intr;

