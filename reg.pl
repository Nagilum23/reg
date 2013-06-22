#!/usr/local/bin/perl -w
use strict;
use WWW::Mechanize;
use WWW::Mechanize::FormFiller;
use URI::URL;

$|=1;
print "Logging into www.freshports.org";
my $agent = WWW::Mechanize->new( autocheck => 1 );
my $formfiller = WWW::Mechanize::FormFiller->new();
$agent->env_proxy();

$agent->get('http://www.freshports.org/login.php');
$agent->form_number(1) if $agent->forms and scalar @{$agent->forms};
$agent->form_number(1);
$agent->current_form->value('UserID', 'myuser');
$agent->current_form->value('Password', 'mypassword');
$agent->click('submit');
my %origins;
my $trigger;
print "\nObtaining installed ports..";
for (`pkg_info -ao`) {
  if($trigger){
		$trigger=0;
		if(/(\S+\/\S+)/) {
			$origins{$1}=1;
		}
	}
	if(/Origin:/) {
		$trigger=1;
	}
}
print "\ngetting list of subscribed ports..";
my %subscribed;
$agent->get('http://www.freshports.org/watch.php');
print ".";
for my $link ($agent->find_all_links(url_regex => qr/search.php\?stype=/)) {
	my $newurl=$link->url();
	$newurl=~/.*=(\S+\/\S+)$/;
	$subscribed{$1}=1;
}
# subscribe to unsubscribed ports
print "\nsubscribing ";
for(keys %origins) {
	if($subscribed{$_}) {
		$subscribed{$_}=0;
	} else {
		$agent->get('http://www.freshports.org/'.$_);
		my $link=$agent->find_link( text_regex => qr/Click to add this to your default watch list/ );
		if($link) {
			print "$_, ";
			$agent->get($link->url);
		}
	}
}
print "done.\nunsubscribing to not installed ports ";
for(keys %subscribed) {
	if($subscribed{$_}) {
		$agent->get('http://www.freshports.org/'.$_);
		my $link=$agent->find_link( text_regex => qr/Click to remove this from your default watch list/ );
		if($link) {
			print "$_, ";
			$agent->get($link->url);
		}
	}
} 
print "done.\n";
