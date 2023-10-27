my $ids;
open(INDEX, '-|', "GET https://boardgamegeek.com/sitemapindex") or print "Reading sitemapindex failed, $!\n";
while( <INDEX> ) {
    if( m^(https://boardgamegeek.com/sitemap_geekitems_boardgame(expansion|accessory|)_page_\d+)^ ) {
	my $page = $1;
	open(PAGE, '-|', "GET $page") or print "Couldn't open $page\n";
	while( <PAGE> ) {
	    if( m^https://boardgamegeek.com/boardgame(expansion|accessory|)/(\d+)^ ) {
		$ids{$2} = "boardgame$1";
	    }
	}
	close(PAGE);
    }
}
close(INDEX);
open(Z, ">thingids.txt");
print Z "$_ $ids{$_}\n" foreach sort { $a <=> $b } keys %ids;
close(Z);