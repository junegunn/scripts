#!/usr/bin/perl -w
# a serial webget
# 
# 20060728 by j_g

use Getopt::Long;
use Term::ANSIColor qw/:constants/;
use LWP::UserAgent;
use threads;
use Thread::Semaphore;
use threads::shared;

# global
my (@OPT, $USAGE);
sub helpEntries {
	my $tlen = 25;
	print STDERR "\n";
	for $aref (@OPT) {
		my ($opt, $desc, $input) = @$aref[0, 2, 3];
		my $title = (split "\\|", $opt)[0];
		$title =~ s/=.*//;
		my $fmt = (length($title) > 1) ? "--%-${tlen}s" : "-%-${tlen}s ";
		$title .= (length($title) > 1) ? "=$input" : " $input" if($input);
		print STDERR ON_BLACK.BOLD.CYAN, "\t";
		printf STDERR $fmt, $title;
		print STDERR RESET.ON_BLACK."$desc\n".RESET;
	}
	print STDERR "\n";
}

sub usage {
	# CLEAR, RESET, BOLD, DARK, UNDERLINE, UNDERSCORE, BLINK, REVERSE, CONCEALED,
	# BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE,
	# ON_BLACK, ON_RED, ON_GREEN, ON_YELLOW, ON_BLUE, ON_MAGENTA, ON_CYAN, ON_WHITE	
	print STDERR ON_BLACK.BOLD.WHITE. "usage: " .GREEN. "$0 " .RESET. "$USAGE\n";
	exit 1 unless(shift);
	helpEntries @OPT if(@OPT > 0);
	exit 0;
}

sub optHelper {
	$USAGE = shift;
	@OPT = @_;
	my %hash;
	for $aref (@OPT) {
		my ($opt, $ref) = @$aref[0, 1];
		$$ref = 0;
		$hash{$opt} = $ref;
	}
	my $help;
	GetOptions %hash, ("help|h" => \$help);
	usage 1 if($help);
}

sub INT_HANDLER {
    print "\nInterrupted ...\n";
    exit 1;
}
#$SIG{INT} = "INT_HANDLER";

my ($proxy, $num_threads);
optHelper (
	# usage
	ON_BLACK.GREEN. "<http addr with @@@@ pattern> <start index> [<end index>] ".RESET,
	# opts
	["proxy|p=s", \$proxy, "use proxy server", "<server>"],
	["threads|t=i", \$num_threads, "Number of threads", "<num>"],
);
$num_threads = 1 unless($num_threads);

sub getLink {
	my $ua = shift;
	my $link = shift;
	
	my $dest;
	unless($link =~ /\/([^\/]*\.[^\/]*$)/) {
		if ($link =~ /\/([^\/]*$)/) {
			$dest = $1;
			print $dest;
		}
		else {
			print "** Ambiguous link: $link\n";
			return;
		}
	}
	else
	{
		$dest = $1;
	}
	# Substitution of forbidden characters
	$dest =~ s#\?#@#g;
	
	my $req = HTTP::Request->new(GET => $link);
	$req->header("Connection" => "Keep-Alive");
	$req->header("Referer" => $referer);
	$req->content_type('application/x-www-form-urlencoded');

	my $res = $ua->request($req, $dest);

	if ($res->is_success) {
		print ":: $link saved to [$dest]\n";
	}
	else {
		print "** $link download failed: ", $res->code, "\n";
		return;
	}
}

if(@ARGV >= 2) {
	($link, $s, $e) = @ARGV;
	$e = $s unless($e);
	die "** Indices are not numeric\n" unless($s =~ /^\d/ && $e =~ /^\d/)
} else { usage; }


$link = "http://".$link unless($link =~ /^(http|ftp)/);
die "** Wrong format, must contain a series of \@s\n" unless($link =~ /\@+/);
# $prefix = $`;
# $postfix = $';
$len = length($&);

$referer = $link;
{
	my $num = sprintf("%0${len}d", $s);
	$referer =~ s/\@{$len}/$num/;		# change @@@@ to $s
	$referer =~ s#(//.*)/.*\..*#$1#;	# remove file name from referer url
}

$proxy = $ENV{http_proxy} if(!$proxy && $ENV{http_proxy});
if($proxy) {
	$proxy = "http://".$proxy unless($proxy =~ /^(http|ftp)/);
	print ":: Using proxy $proxy\n";
}

print ":: Referenced from $referer ;)\n";

my (@agents, @threads);
for (1..$num_threads)
{
	my $ua;
	$ua = LWP::UserAgent->new;
	$ua->agent("MSIE 6.0 (Windows XP)");
	$ua->proxy("http", $proxy) if($proxy);
	$agents[$_] = $ua;
}

my $index : shared;
$sem = new Thread::Semaphore;

$inc = 0;
# forward scan
if ($s <= $e)
{
	$index = $s-1;
	$inc = 1;
}
# backward scan
else
{
	$index = $s+1;
	$inc = -1;
}


sub getNext
{
	$sem->down;
	$index += $inc;
	$sem->up;
	return "EOF" if ( ($index > $e && $inc > 0) ||
	                  ($index < $e && $inc < 0) );
	# return $prefix . sprintf("%0${len}d", $index) . $postfix;
	my $ret = $link;
	my $num = sprintf("%0${len}d", $index);
	$ret =~ s/\@+/$num/g;
	return $ret;
}

sub getter
{
	my $ua = shift;
	my $f;
	getLink($ua, $f) while (($f = getNext) ne "EOF");
}

$threads[$_] = threads->create("getter", $agents[$_]) for (1..$num_threads);
$threads[$_]->join() for (1..$num_threads);
