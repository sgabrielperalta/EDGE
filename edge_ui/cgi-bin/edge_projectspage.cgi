#!/usr/bin/env perl
use strict;
use LWP::Simple qw();
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use CGI qw(:standard);
#use CGI::Carp qw(fatalsToBrowser);
use POSIX qw(strftime);
use Data::Dumper;
#use CGI::Pretty;
require "edge_user_session.cgi";

my $cgi   = CGI->new;
my %opt   = $cgi->Vars();
my $username    = $opt{'username'}|| $ARGV[0];
my $password    = $opt{'password'}|| $ARGV[1];
my $umSystemStatus    = $opt{'umSystem'}|| $ARGV[2];
my $userType    = $opt{'userType'}|| $ARGV[3];
my $viewType    = $opt{'view'}|| $ARGV[4];
my $protocol    = $opt{protocol}||'http:';
my $sid         = $opt{'sid'}|| $ARGV[5];
my $domain      = $ENV{'HTTP_HOST'} || 'edge-bsve.lanl.gov';
my ($webhostname) = $domain =~ /^(\S+?)\./;

# read system params from sys.properties
my $sysconfig    = "$RealBin/../sys.properties";
my $sys          = &getSysParamFromConfig($sysconfig);
$sys->{edgeui_output} = "$sys->{edgeui_output}"."/$webhostname" if ( -d "$sys->{edgeui_output}/$webhostname");
my $out_dir     = $sys->{edgeui_output};
my $um_config	= $sys->{user_management};
my $um_url      = $sys->{edge_user_management_url};
$um_url ||= "$protocol//$domain/userManagement";

# session check
if( $sys->{user_management} ){
	my $valid = verifySession($sid);
	if($valid){
		($username,$password) = getCredentialsFromSession($sid);
	}
}

#print Dumper ($list);
print  $cgi->header( "text/html" );
print  $cgi->h2("Project List");
if ( $username && $password || $um_config == 0){
	#Action buttons
	print "<div id='edge-projpage-action' class='flex-container'>\n";
	if ($userType =~ /admin/i){
		print '<a href="" title="See All Projects List (admin)" class="tooltip ui-btn ui-btn-d ui-icon-bars ui-btn-icon-notext ui-corner-all" data-role="button" role="button">show-all</a>';
	}
	print '<a href="" title="Force Selected Projects to rerun" class="tooltip ui-btn ui-btn-d ui-shadow-icon ui-icon-refresh ui-btn-icon-notext ui-corner-all" data-role="button" >rerun</a>';
	print '<a href="" title="Interrupt running Projects" class="tooltip ui-btn ui-btn-d ui-icon-forbidden ui-btn-icon-notext ui-corner-all" data-role="button" role="button">interrupt</a>';
	print '<a href="" title="Delete Selected Projects" class="tooltip ui-btn ui-btn-d ui-icon-delete ui-btn-icon-notext ui-corner-all" data-role="button" role="button">delete</a>';
	print '<a href="" title="Empty Selected Projects Output" class="tooltip ui-btn ui-btn-d ui-icon-recycle ui-btn-icon-notext ui-corner-all" data-role="button" role="button">empty</a>';
	if ($sys->{edgeui_archive}){
		print '<a href="" title="Archive Selected Projects" class="tooltip ui-btn ui-btn-d ui-icon-arrow-u-r ui-btn-icon-notext ui-corner-all" data-role="button" role="button">archive</a>';
 	}
	 if ($um_config != 0){
		print '<a href="" title="Share Selected Projects" class="tooltip ui-btn ui-btn-d ui-icon-forward ui-btn-icon-notext ui-corner-all" data-role="button" role="button">share</a>';
		print '<a href="" title="Make Selected Projects Public" class="tooltip ui-btn ui-btn-d ui-icon-eye ui-btn-icon-notext ui-corner-all" data-role="button" role="button">publish</a>';
 	}
	print '<a href="" title="Compare Selected Projects Taxonomy Classification (HeatMap)" class="tooltip ui-btn ui-btn-d ui-icon-bullets ui-btn-icon-notext ui-corner-all" data-role="button" role="button">compare</a>';
 	
#	if($sys->{edge_sample_metadata}) {
# 		print '<a href="" title="Share Selected Projects Metadata with BSVE" class="tooltip ui-btn ui-btn-d ui-icon-arrow-u ui-btn-icon-notext ui-corner-all" data-role="button" role="button">metadata-bsveadd</a>';
# 	}
 	print '</div>';
}

#print "<div data-filter='true' id='edge-project-list-filter' data-filter-placeholder='Search projects ...'> \n";
#print "<form id='edge-projpage-form'>\n";
my $head_checkbox="<input type='checkbox' id='edge-projpage-ckall'>";
if ($umSystemStatus=~ /true/i && $username && $password && $viewType =~ /user/i ){
	# My Table
	my $list = &getUserProjFromDB("owner");
	my $list_g = &getUserProjFromDB("guest");
	my $list_p = &getUserProjFromDB("other_published");
	$list = &ref_merger($list, $list_g) if $list_g;
	$list = &ref_merger($list, $list_p) if $list_p;
	#print Dumper $list;

	#<div data-role='collapsible-set' id='edge-project-list-collapsibleset'> 

	my @theads = (th("$head_checkbox"),th("Project Name"),th("Status"),th("Submission Time"),th("Total Running Time"),th("Type"),th("Owner"));
	my $idxs = &sortList($list);
	my $table_id = "edge-project-page-table";
	&printTable($table_id,$idxs,$list,\@theads);

}elsif ($umSystemStatus=~ /true/i) {
	# show admin list or published project
	my $list =  &getUserProjFromDB();
	my $idxs = &sortList($list);
	my @theads = (th("$head_checkbox"),th("Project Name"),th("Status"),th("Submission Time"),th("Total Running Time"),th("Owner"));
	my $table_id = "edge-project-page-table";
	&printTable($table_id,$idxs,$list,\@theads);
}elsif ($um_config == 0) {
	# all projects in the EDGE_output
	my $list= &scanProjToList();
	my $idxs = &sortList($list);
	my @theads = (th("$head_checkbox"),th("Project Name"),th("Status"),th("Submission Time"),th("Total Running Time"),th("Last Run Time"));
	my $table_id = "edge-project-page-table";
	&printTable($table_id,$idxs,$list,\@theads);
}



## END MAIN## 

sub sortList {
	my $list = shift;
	
	my @idxs1 = grep { $list->{$_}->{PROJSTATUS} =~ /running/i } sort {$list->{$b}->{TIME} cmp $list->{$a}->{TIME}} keys %$list;
	my @idxs2 = grep { $list->{$_}->{PROJSTATUS} =~ /unstarted/i } sort {$list->{$a}->{REAL_PROJNAME} cmp $list->{$b}->{REAL_PROJNAME}} keys %$list;
	my @idxs3 = grep { $list->{$_}->{PROJSTATUS} !~ /running|unstarted/i } sort {$list->{$b}->{TIME} cmp $list->{$a}->{TIME}} keys %$list;
	my @idxs = (@idxs1,@idxs2,@idxs3);
	return \@idxs;
}

sub printTable {
	my $table_id = shift;
	my $idx_ref = shift;
	my $list = shift;
	my $theads = shift;
	my @idxs = @{$idx_ref};
	my @tbodys;
	#return if (@ARGV);
	if ($list->{INFO}->{ERROR})
	{
		print "<p class='error'>$list->{INFO}->{ERROR}</p>\n";
	}
	foreach (@idxs)
	{
		my $projOwner = $list->{$_}->{OWNER};
		my $projStatus = $list->{$_}->{PROJSTATUS};
		my $projID = $list->{$_}->{PROJNAME};
		my $projname = "<a href=\"#\" class=\"edge-project-page-link \" title=\"$list->{$_}->{PROJDESC}\" data-pid=\"$projID\">$list->{$_}->{REAL_PROJNAME}</a>";
		my $projSubTime = $list->{$_}->{PROJSUBTIME};
		my $projRunTime = $list->{$_}->{RUNTIME};
		my $projLastRunTime = $list->{$_}->{LASTRUNTIME};
		my $projType = $list->{$_}->{PROJ_TYPE};
		my $projCode = $list->{$_}->{PROJCODE} || $list->{$_}->{REAL_PROJNAME};
		my $checkbox = "<input type='checkbox' class='edge-projpage-ckb' name='edge-projpage-ckb' value=\'$projCode\'>";
		my $publish_action= ($projType =~ /published/)? "unpublished":"published";
		$projType =~ s/published/public/;
		my @tds;
		if ($umSystemStatus=~ /true/i){
			$checkbox="" if (!$username && !$password);
			if( scalar @$theads == 7 ){
				@tds = ( td($checkbox),td($projname),td($projStatus),td($projSubTime),td($projRunTime),td($projType),td($projOwner) );
			}
			else{
				@tds = ( td($checkbox), td($projname),td($projStatus),td($projSubTime),td($projRunTime),td($projOwner) );
			}
		}else{
			@tds = ( td($checkbox),td($projname),td($projStatus),td($projSubTime),td($projRunTime),td($projLastRunTime));
		}
		push @tbodys, \@tds;
	}

	if (scalar(@idxs)<1){
		my @tds = (td(""),td("No Projects"),td(""),td(""),td(""),td(""));
		if( scalar @$theads == 7 ){
			@tds = (td(""),td("No Projects"),td(""),td(""),td(""),td(""),td(""));
		}

		push @tbodys, \@tds;
	}
	print $cgi->table( 
			{-id=>"$table_id" , -class=>"output-table ui-responsive ui-table ui-table-reflow" },
			thead(Tr(@{$theads})),
			tbody(
			map { Tr(@{$_}) } @tbodys
			)
	);
}


sub getSysParamFromConfig {
	my $config = shift;
	my $sys;
	open CONF, $config or die "Can't open $config: $!";
	while(<CONF>){
		if( /^\[system\]/ ){
			while(<CONF>){
				chomp;
				last if /^\[/;
				if ( /^([^=]+)=([^=]+)/ ){
					$sys->{$1}=$2;
				}
			}
		}
		last;
	}
	close CONF;
	return $sys;
}

sub scanProjToList {
	my $cnt = 0;
	my $list;
	opendir(BIN, $out_dir) or die "Can't open $out_dir: $!";
	while( defined (my $file = readdir BIN) ) {
		next if $file eq '.' or $file eq '..';
		if ( -d "$out_dir/$file" && -r "$out_dir/$file/process.log"  ) {
			++$cnt;
			$list=&pull_summary("$out_dir/$file/process.log",$cnt,$list);
			$list=&pull_summary("$out_dir/$file/config.txt",$cnt,$list) if ($list->{$cnt}->{PROJSTATUS} =~ /unstart/i);
			$list->{$cnt}->{REAL_PROJNAME} = $list->{$cnt}->{PROJNAME} || $file;
			$list->{$cnt}->{PROJNAME} = $file;
		}
	}
	closedir(BIN);
	return $list;
}

sub getUserProjFromDB{
	my $project_type = shift;
	my $list = {};
        my %data = (
                email => $username,
                password => $password
        );
        # Encode the data structure to JSON
        #w Set the request parameters
	my $service;
	if ($username && $password){ 
		$service= ($viewType =~ /admin/i)? "WS/user/admin/getProjects" :"WS/user/getProjects";
		$data{project_type} = $project_type if ($viewType =~ /user/i && $project_type);
	}else{
		$service="WS/user/publishedProjects";
	}
        my $data = to_json(\%data);
        my $url = $um_url .$service;
        my $browser = LWP::UserAgent->new;
        my $req = PUT $url;
        $req->header('Content-Type' => 'application/json');
        $req->header('Accept' => 'application/json');
        #must set this, otherwise, will get 'Content-Length header value was wrong, fixed at...' warning
        $req->header( "Content-Length" => length($data) );
        $req->content($data);

        my $response = $browser->request($req);
        my $result_json = $response->decoded_content;
	
	if ($result_json =~ /\"error_msg\":"(.*)"/)
        {
                $list->{INFO}->{ERROR}=$1;
                return;
        }
        my $array_ref =  from_json($result_json);
	foreach my $hash_ref (@$array_ref)
	{
		my $id = $hash_ref->{id};
		my $projCode = $hash_ref->{code};
		my $project_name = $hash_ref->{name};
		my $status = $hash_ref->{status};
		next if ($status =~ /delete/i);
		next if (! -r "$out_dir/$id/process.log" && ! -r "$out_dir/$projCode/process.log");
		my $processlog=(-r "$out_dir/$projCode/process.log")?"$out_dir/$projCode/process.log":"$out_dir/$id/process.log";
		$list=&pull_summary($processlog,$id,$list);
		$list->{$id}->{PROJNAME} = $id;
		$list->{$id}->{PROJSTATUS} = $status if (!$list->{$id}->{PROJSTATUS});
		$list->{$id}->{REAL_PROJNAME} = $project_name if (!$list->{$id}->{REAL_PROJNAME});
		$list->{$id}->{PROCODE} = $projCode;
		$list->{$id}->{OWNER} = "$hash_ref->{owner_firstname} $hash_ref->{owner_lastname}";
		$list->{$id}->{OWNER_EMAIL} = $hash_ref->{owner_email};
		$list->{$id}->{PROJ_TYPE} = $hash_ref->{type};
	}
	return $list;
}


sub pull_summary {
	my $log = shift;
	my $cnt= shift;
	my $list = shift;
	my @INFILES;
	
	my ($step,$lastline);
	my $tol_running_sec=0;

	open(my $sumfh, "<", "$log") or die $!;
	while(<$sumfh>) {
		chomp;
		#parse input files
		if( /runPipeline/ ) {
			undef @INFILES;	
		}
		if( /runPipeline .*-p (.*) -\w/ || /runPipeline .*-p (.*) >/ || /runPipeline .*-p (.*)$/) {
			push @INFILES, split /\s+/,$1;
		}
		if(/runPipeline .*-u (.*) -\w/ || /runPipeline .*-u (.*) >/ || /runPipeline .*-u (.*)$/){
			push @INFILES, split /\s+/,$1;
		}

		#parse reference files
		if( /runPipeline .*-ref (\S+)/){
			$list->{$cnt}->{REFFILE} = $1;
		}
		elsif( /^reference=(\S+)/ ){
			 $list->{$cnt}->{REFFILE} = $1;
		}

		if( /Total Running time: (\d+):(\d+):(\d+)/){
			$list->{$cnt}->{LASTRUNTIME} = "$1h $2m $3s";
			next;
		}
		elsif( /^Host=(.*)/ ){
			$list->{$cnt}->{HOSTFILE} = $1;
			next;
		}
		elsif( /^SNPdbName=(.*)/ ){
			$list->{$cnt}->{SPDB} = $1;
			next;
		}

		if( /^\[(.*)\]/ ){
			$step = $1;
			if( $step eq "project" or $step eq "system"){
				while(<$sumfh>){
					chomp;
					if ( /^([^=]+)=([^=]+)/ ){
						$list->{$cnt}->{uc($1)}=$2;
						$list->{$cnt}->{REAL_PROJNAME}=$2 if ($1 eq "projname");
					}
					elsif ( /^\[(.*)\]/ ){
						$step = $1;
						last;
					}
				}
			}
			
		}
		elsif( /Project Start: (.*)/ ){
			$list->{$cnt}->{PROJSUBTIME} = $1;
			my ($yyyy,$mm,$dd,$hms) = $list->{$cnt}->{PROJSUBTIME} =~ /(\d{4}) (\w{3})\s+(\d+)\s+(.*)/;
			my %mon2num = qw(jan 1  feb 2  mar 3  apr 4  may 5  jun 6  jul 7  aug 8  sep 9  oct 10 nov 11 dec 12);
			$mm = $mon2num{ lc substr($mm, 0, 3) };
			$mm = sprintf "%02d", $mm;
			$dd = sprintf "%02d", $dd;
			my $proj_start  = "$yyyy-$mm-$dd $hms";
			$list->{$cnt}->{TIME} = $proj_start;
			$list->{$cnt}->{PROJSTATUS} = "Unfinished";
		}
		elsif( /^Do.*=(.*)$/ ){
			my $do = $1;
			$list->{$cnt}->{$step}->{GNLRUN}= "Auto";
			$list->{$cnt}->{$step}->{GNLRUN}= "On" if $do eq 1;
			$list->{$cnt}->{$step}->{GNLRUN}= "Off" if $do eq 0;
			
			$list->{$cnt}->{$step}->{GNLSTATUS}="Skipped";
			$list->{$cnt}->{$step}->{GNLSTATUS}="Incomplete" if $do eq 1;
		}
		elsif( /Finished/ ){
			$list->{$cnt}->{$step}->{GNLSTATUS} = "Skipped (result exists)";
		}
		elsif( /Running time: (\d+:\d+:\d+)/ ){
			$list->{$cnt}->{$step}->{GNLSTATUS} = "Complete";
			$list->{$cnt}->{$step}->{GNLTIME} = $1;
        	        my ($h,$m,$s) = $1 =~ /(\d+):(\d+):(\d+)/;
                	$tol_running_sec += $h*3600+$m*60+$s;
		}
		elsif( / Running/ ){
			$list->{$cnt}->{$step}->{GNLSTATUS} = "<span class='edge-fg-orange'>Running</span>";
			$list->{$cnt}->{PROJSTATUS} = "<span class='edge-fg-orange'>Running</span>";
		}
		elsif( /failed/ ){
			$list->{$cnt}->{$step}->{GNLSTATUS} = "<span class='edge-fg-red'>Failed</span>";
			$list->{$cnt}->{PROJSTATUS} = "<span class='edge-fg-red'>Failure</span>";
		}
		elsif( /All Done/){
			$list->{$cnt}->{PROJSTATUS} = "Complete";
		}
		$lastline = $_;
	}

        #$list->{$cnt}->{RUNTIME} = strftime("\%H:\%M:\%S", gmtime($tol_running_sec));
	$list->{$cnt}->{RUNTIME} = sprintf("%02d:%02d:%02d", int($tol_running_sec / 3600), int(($tol_running_sec % 3600) / 60), int($tol_running_sec % 60));

	$list->{$cnt}->{PROJSTATUS}        = "Unstarted"   if $lastline =~ /EDGE_UI.*unstarted/;
	$list->{$cnt}->{PROJSTATUS}        = "Interrupted" if $lastline =~ /EDGE_UI.*interrupted/;
	$list->{$cnt}->{PROJSTATUS}        = "Archived"    if $lastline =~ /EDGE_UI.*archived/;
	$list->{$cnt}->{TIME}              = $1            if $lastline =~ /\[(\S+ \S+)\] EDGE_UI/;
	$list->{$cnt}->{$step}->{GNLSTATUS} = "Interrupted" if $list->{$cnt}->{$step}->{PROJSTATUS} eq "Interrupted"; #turn last step to unfinished
	
	$list->{$cnt}->{INFILES} = join ", ", @INFILES;
	$list->{$cnt}->{TIME} ||= strftime "%F %X", localtime;
	
	close ($sumfh);
	return $list;
}

sub check_um_service {
	my $url=shift;
	if (! LWP::Simple::head($url)) {
  	#	warn "The User managment Service is DOWN!!!! Will pull all projects from EDGE output direcotry";
  		return 0; 
	}else{
		return 1;
	}
}

sub ref_merger {
	my ($r1, $r2) = @_;
	foreach my $key (keys %$r2){
		$r1->{$key} = $r2->{$key};
	}
	return $r1;
}
