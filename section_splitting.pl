
#----------------------------------------------------------------------------
# Module   : Section splinting for based on toc.xhtml
# Author   : Deepan P.
# Function : CT & E
#----------------------------------------------------------------------------

# Histroy
#----------------------------------------------------------------------------
# v1.0 | 04152015 | Parthiban U. | Initial Development
#----------------------------------------------------------------------------

my $ver = "1.0";

# Module declaration
	use strict;
	use warnings;
	
	undef $/;
	use Win32;
	use File::Basename;
	use File::Copy;
	use iPerl::Basic qw(_open_file _save_file _element_leveling _get_file_list _open_utf8 _save_utf8 _make_path _get_filelist_from_zip);
	use Tie::IxHash;
	use EasyQC::ErrorLog;

	if(!defined ($ARGV[0]) or ! -d $ARGV[0])
	{
		Win32::MsgBox("Syntax: section_splitting.exe <folderpath>", 16, "MetroDigi ePUB Automation");
		exit;
	}

	my $dirname = $ARGV[0];
	opendir(DIR, $dirname);
	my @files = grep {/^pg0*[1-9][0-9]*\.xhtml$/i} readdir(DIR);
	closedir(DIR);

	my ($id, $txt, $main, $idvalue, $log, $pgname) = "";
	my %splited_files = ();
	tie %splited_files, "Tie::IxHash";
	
	
	my $tocfile = _open_utf8("$dirname\\toc\.xhtml");
	
	my $pre_txt = "";	
	mkdir("$dirname\\..\\..\\back_up") unless(-d "$dirname\\..\\..\\back_up");
	mkdir("$dirname\\..\\..\\back_up\\1_rename_files") unless(-d "$dirname\\..\\..\\back_up\\1_rename_files");
	mkdir("$dirname\\..\\..\\back_up\\2_section_split") unless(-d "$dirname\\..\\..\\back_up\\2_section_split");

	foreach my $xhtml (@files) {		
		my $xhtmlcnt = _open_utf8("$dirname\\$xhtml");
		
		copy("$dirname\\$xhtml", "$dirname\\..\\..\\back_up\\1_rename_files\\$xhtml");
		#unlink "$dirname\\$xhtml";		
		
		if($xhtmlcnt =~ m{<title>\s*cover\s*</title>}i and $xhtmlcnt =~ m{<img(?: [^>]+)? src="[^">]*[\\\/]cover.jpg"}i) {
			_save_utf8("$dirname\\cover.xhtml", $xhtmlcnt);	
			_save_utf8("$dirname\\..\\..\\back_up\\2_section_split\\cover.xhtml", $xhtmlcnt);
		}
		elsif($xhtmlcnt =~ m{<body(?: [^>]+)?>(.*?)</body>}is) {
			$main .= "$1\n";#<<file:$xhtml>>
			$pre_txt = $` if($pre_txt eq "");
		}
	}

	$pre_txt =~ s{<title>.*?</title>}{<title>##title-text##</title>}is;
	$main =~ s{^\s*(.*?)\s*$}{$1}is;
	
	my @chaps = $tocfile =~ m{<a(?: [^>]+)? href="ch[0-9]+\_introduction\.xhtml"[^>]*>(?:(?!<a(?: [^>]+)? href="ch[0-9]+\_introduction\.xhtml"[^>]*>|</nav>|</body>).)*(?=<a(?: [^>]+)? href="ch[0-9]+\_introduction\.xhtml"[^>]*>|</nav>|</body>)}isg;
	
	$main =~ s{(<section(?: [^>]+)? epub:type="chapter"[^>]*)(>(?:(?!</?section[ >]|</?header>).)*<header>((?:(?!</?header>).)*)</header>)}{qq($1 delchaptext=")._clear_label_text($3).qq("$2)}isge;
	$main =~ s{(<section(?: [^>]+)? class="(?:[^">]* )?level1(?: [^">]*)?"[^>]*)(>(?:(?!</?section[ >]|</?header>).)*<header>((?:(?!</?header>).)*)</header>)}{qq($1 delsec1text=")._clear_label_text($3).qq("$2)}isge;
	$main =~ s{(<section(?: [^>]+)? class="(?:[^">]* )?level2(?: [^">]*)?"[^>]*)(>(?:(?!</?section[ >]|</?header>).)*<header>((?:(?!</?header>).)*)</header>)}{qq($1 delsec2text=")._clear_label_text($3).qq("$2)}isge;

	$main = _element_leveling($main, "section");

	my %files_cnt = ();
	tie %files_cnt, "Tie::IxHash";
	my $prev_chapfile = "";
	my $prev_secfile = "";
	
	my @main_tocs = ();
	my @main_chaps = ();
	
	my @tmp_tocs = ();
	my @tmp_chaps = ();

	foreach my $toc_chaps (@chaps) {
		my $chap_title = "";
		my $new_name = "";
		
		if($toc_chaps =~ m{<a(?: [^>]+)? href="(ch[0-9]+\_introduction\.xhtml)"[^>]*>(.*?)</a>}i) {
			$chap_title = $2;
			$new_name = $1;
			$splited_files{$1} = "$2";
		}

		$chap_title =~ s{^\s*(?:(?:chapter|ch|chap|session|sec|section|Stage)[\s\.]+)?[0-9]+[\.0-9]*\s*:\s*}{}ig;
		$chap_title = _clear_label_text($chap_title);

		if($main =~ s{<section[1-9]+(?: [^>]+)? delchaptext="$chap_title"(?:(?! delchaptext="|$).)*(?=<section[1-9]+(?: [^>]+)? delchaptext="|$)}{}is) {
			$files_cnt{$new_name} = [$&, $toc_chaps];
			delete $splited_files{$new_name} if(exists $splited_files{$new_name});
			
			my $pre = $`;
			my $pre1 = $pre;
			
			@tmp_chaps = $pre =~ m{(<section[1-9]+(?: [^>]+)? delchaptext="[^">]*"(?:(?! delchaptext="|$).)*)(?=<section[1-9]+(?: [^>]+)? delchaptext="|$)}isg;
			$pre =~ s{(<section[1-9]+(?: [^>]+)? delchaptext="[^">]*"(?:(?! delchaptext="|$).)*)(?=<section[1-9]+(?: [^>]+)? delchaptext="|$)}{}isg;
			
			$main =~ s{\Q$pre1\E}{$pre}isx;
			
			if(scalar(@tmp_chaps) == scalar(@tmp_tocs) and scalar(@tmp_tocs) > 0) {
				for(my $i=0; $i<scalar(@tmp_tocs);$i++) {
					my ($tmp_chap_title, $tmp_new_name) = ("", "");
					if($tmp_tocs[$i] =~ m{<a(?: [^>]+)? href="(ch[0-9]+\_introduction\.xhtml)"[^>]*>(.*?)</a>}i) {
						$tmp_chap_title = $2;
						$tmp_new_name = $1;

						delete $splited_files{$tmp_new_name} if(exists $splited_files{$tmp_new_name});
						$files_cnt{$tmp_new_name} = [$tmp_chaps[$i], $tmp_tocs[$i]];
					}
				}
				@tmp_tocs = ();
				@tmp_chaps = ();
			}
			elsif( @tmp_tocs or @tmp_chaps) {
				@main_tocs = (@main_tocs, @tmp_tocs) if(@tmp_tocs);
				@main_chaps = (@main_chaps, @tmp_chaps) if(@tmp_chaps);
				@tmp_tocs = ();
				@tmp_chaps = ();
			}
		}
		else {
			push @tmp_tocs, $toc_chaps;
		}
	}

	#$main =~ s{^\s*(.*?)\s*$}{$1}is;
	#if(@main_chaps or $main ne "" or @main_tocs) {
	#	$files_cnt{'unsplited_content.xhtml'} = [$main.join("\n", @main_chaps), join("\n", @main_tocs)];
	#	$splited_files{'unsplited_content.xhtml'} = "";
	#}

	my $Errors = "";
	
	if(%splited_files) {
		foreach my $tm (keys %splited_files) {
			$Errors .= AddErrWarn("Unable to split chapter. \"$tm\" (<font color=\"green\">$splited_files{$tm}</font>)",1,1,"$dirname\\toc\.xhtml");
		}
		
		Win32::MsgBox("Some Chapters are not split. Please check.",64,"MetroDigi ePUB Automation");
		#-------------- Error Report Generation -------------
		CreateErrorLog("$ARGV[0]","MetroDigi ePUB Automation - Ver 1.0","$Errors","");
		#-----------------------------------------------------
		exit;
	}
	
	foreach my $tm (@files) {
		unlink "$dirname\\$tm" if(-f "$dirname\\$tm");
	}

	%splited_files = ();
	my %sections = ();
	tie %sections, "Tie::IxHash";
	foreach my $chap_filename (sort keys %files_cnt) {
		$files_cnt{$chap_filename}[1] =~ s{^(?:(?!</?ol[ >]).)*(<ol(?: [^>]+)?>.+</ol>)(?:(?!</?ol[ >]).)*$}{$1}is;
		$files_cnt{$chap_filename}[1] = _element_leveling($files_cnt{$chap_filename}[1], "ol");

		$files_cnt{$chap_filename}[1] =~ s{<a(?: [^>]+)? href="[^">]*#(?:(?!</?a[ >]).)*</a>}{}isg;
		$files_cnt{$chap_filename}[1] =~ s{<a(?: [^>]+)? href="ch[0-9]+\-(?:q[0-9]*|chq[0-9]*)\-(?:(?!</?a[ >]).)*</a>}{}isg;
		
		while($files_cnt{$chap_filename}[1] =~ s{<li(?: [^>]+)?>\s*(?:</?li(?: [^>]+)?>\s*)*\s*</li>\s*}{}isg){}
		while($files_cnt{$chap_filename}[1] =~ s{<ol[0-9]+(?: [^>]+)?>\s*(?:</?li(?: [^>]+)?>\s*)*\s*</ol[0-9]*>\s*}{}isg){}
		
		while($files_cnt{$chap_filename}[1] =~ s{<ol([0-9]+)[ >](?:(?!</?ol[0-9]+[ >]).)*</ol\1>}{
			my $tmcnt = $&;
			my $tmlvl = $1;
			
			$tmcnt =~ s{(</?li)([ >])}{${1}$tmlvl$2}ig;
			$tmcnt =~ s{(</?)(ol[0-9]+)}{$1&del;$2}ig;
			qq($tmcnt)
		}isge){}

		$files_cnt{$chap_filename}[1] =~ s{&del;}{}ig;
		
		$files_cnt{$chap_filename}[0] = _make_section($files_cnt{$chap_filename}[1], $files_cnt{$chap_filename}[0], 1);
	}
	
	my $fl_count = 1;
	foreach my $fl (keys %files_cnt) {
		$fl_count++;
		_save_utf8("$dirname\\..\\..\\back_up\\2_section_split\\$fl", _final_changes(qq($pre_txt\n<body>\n$files_cnt{$fl}[0]\n</body></html>)));
		_save_utf8("$dirname\\$fl", _final_changes(qq($pre_txt\n<body>\n$files_cnt{$fl}[0]\n</body></html>)));
	}
	
	foreach my $fl (keys %sections) {
		$fl_count++;
		_save_utf8("$dirname\\..\\..\\back_up\\2_section_split\\$fl", _final_changes(qq($pre_txt\n<body>\n$sections{$fl}\n</body></html>)));
		_save_utf8("$dirname\\$fl", _final_changes(qq($pre_txt\n<body>\n$sections{$fl}\n</body></html>)));
	}
		
	$Errors = "";
	my $not_fl_count = 0;
	if(%splited_files) {
		foreach my $tm (sort {lc($a) cmp lc($b)} keys %splited_files) {
			if($tm !~ m{(?:\-q[0-9]*|\-chq[0-9]*|\-sw|credits|references|summary)[\.\-]}i){
				$not_fl_count++;
				$Errors .= AddErrWarn("Unable to split sections. \"$tm\" (<font color=\"green\">$splited_files{$tm}</font>)",1,1,"$dirname\\toc\.xhtml");
			}
		}
		
		$Errors = "\n<tr><td/></tr>\n".AddSubLabel("Total Files: ".($not_fl_count + $fl_count).", Converted Files: $fl_count & Failed Files: $not_fl_count \(".sprintf("%2d",((100 * $fl_count)/($not_fl_count + $fl_count))).'%)').'<tr><td><font size="2" face="Verdana"><ol type="number">'.$Errors.'</ol></font></td></tr>';
		
		Win32::MsgBox("Some sections are not split. Please check.",64,"MetroDigi ePUB Automation");
		#-------------- Error Report Generation -------------
		CreateErrorLog("$ARGV[0]","MetroDigi ePUB Automation - Ver 1.0","$Errors","");
		#-----------------------------------------------------
		exit;
	}


print "Process completed!!!";	
exit;

sub _final_changes {
	my $cnt = shift;
	
	my $main_title = "";
	if($cnt =~ m{<body>(?:(?!</?header[ >]).)*<header>((?:(?!</?header>).)*<h1[ >](?:(?!</?header>).)*)</header>}is) {
		$main_title = $1;
		$main_title =~ s{^.*?<h1(?: [^>]+)?>(.*?)</h1>.*?$}{$1}is;
		$main_title =~ s{<span class="(?:label|number)">.*?</span>}{}ig;
		$main_title =~ s{</?[a-z][^>]*>}{}ig;
		$main_title =~ s{\s*[\n\r]+\s*}{ }g;
		$main_title =~ s{^\s*(.*?)\s*$}{$1};
	}

	$cnt =~ s{<title>##title-text##</title>\s*}{<title>$main_title</title>\n}i;
	$cnt =~ s{(</?(?:section|ol|li))[0-9]+([ >])}{$1$2}ig;
	$cnt =~ s{ del(?:sec[12]|chap)text="[^>"]*"}{}ig;
	$cnt =~ s{\s*</body></html>}{</body></html>}i;
	$cnt =~ s{[\n\r][\n\r]+}{\n}g;
	
	return $cnt;
}

sub _make_section{
	my ($toc_sections, $chapter_cnt, $level) = @_;

	my @levels = $toc_sections =~ m{<li$level>\s*(<a(?: [^>]+)? href="ch[0-9]*_sec_[0-9]*\.xhtml"[^>]*>(?:(?!</?li$level>).)*)</li$level>}isg;

	
	my ($pre, $body, $back) = ("", "", "");
	if($chapter_cnt =~ m{^((?:(?!<section[0-9]*(?: [^>]+)? class="(?:[^">]* )?level${level}(?: [^">]*)?").)*)(<section[0-9]*(?: [^>]+)? class="(?:[^">]* )?level${level}(?: [^">]*)?".+<(section[0-9]*)(?: [^>]+)? class="(?:[^">]* )?level${level}(?: [^">]*)?".*?</\3>)((?:(?!<section[0-9]*(?: [^>]+)? class="(?:[^">]* )?level${level}(?: [^">]*)?").)*)$}is) {
		($pre, $body, $back) = ($1, $2, $4);
	}
	
	$pre = $chapter_cnt if($pre eq "" and $body eq "");
	
	my $matchstr = "";
	my %tmphash = ();
	tie %tmphash, "Tie::IxHash";
	
	foreach my $sec_toc_val (@levels) {			
		if($sec_toc_val =~ s{^\s*<a(?: [^>]+)? href="(ch[0-9]*_sec_[0-9]*\.xhtml)"[^>]*>(.*?)</a>}{}i) {
			my $sec_title1 = $2;
			my $sec_title = $2;
			my $file_name = $1;
			$splited_files{$1} = "$sec_title";
			
			$sec_title =~ s{^\s*(?:(?:chapter|ch|chap|session|sec|section|Stage)[\s\.]+)?[0-9]+[\.0-9]*\s*:\s*}{}ig;
			$sec_title = _clear_label_text($sec_title);
			$tmphash{lc($sec_title)} = [$file_name, $sec_toc_val, $sec_title1]  ;

			$matchstr .= "$sec_title\|";
		}
	}
	
	while($toc_sections =~ m{<a(?: [^>]+)? href="([^">]*\.xhtml)"[^>]*>\s*(.*?)\s*</a>}isg) {
		my $flnm = $1;
		my $fltit = $2;
		# print $fltit;system("pause");
		if($fltit !~ m{(?:\-q[0-9]*|\-chq[0-9]*|\-sw)[\.\-]}i) {
			$splited_files{$flnm} = "$fltit";
		}
	}

	$matchstr = substr($matchstr, 0, -1);
	my $matchstr2 = "|".$matchstr."|";
	
	$body =~ s{<section[1-9]+(?: [^>]+)? delsec${level}text="($matchstr)"}{<<split:$1>>$&}ig;
	
	my @section_splited = split(/<<split:[^><]*>>/i, $body);
	
	my @extra_arrs = ();
	for(my $i = 1; $i <= scalar(@section_splited);$i++) {
		if($i < scalar(@section_splited)) {
			if($section_splited[$i] =~ s{^<(section[1-9]+(?: [^>]+)? delsec[1-9]+text="($matchstr)")}{<&del;$1}i) {
				my $tmtxt = $2;
				
				if($matchstr2 =~ s{^(.*?)\|$tmtxt(?=\||$)}{}i) {
					my $tmpre = $1;
					
					if(defined($tmpre) and $tmpre !~ m{^\s*$} and length($tmpre) > 1) {
						$tmpre = substr($tmpre, 1);
						my @arr = split(/\|/, $tmpre);
						
						my @arr2 = $section_splited[$i-1] =~ m{(<section[1-9]+(?: [^>]+)? delsec${level}text="[^>"]+"(?:(?! delsec${level}text="[^>"]+"|$).)*)(?=<section[1-9]+(?: [^>]+)? delsec${level}text="[^>"]+"|$)}isg;
						
						if(scalar(@arr) == scalar(@arr2)) {
							$section_splited[$i-1] =~ s{(<section[1-9]+(?: [^>]+)? delsec${level}text="[^>"]*"(?:(?! delsec${level}text="|$).)*)(?=<section[1-9]+(?: [^>]+)? delsec${level}text="|$)}{}ig;
							
							for(my $j=0; $j<=$#arr2; $j++) {
								$arr2[$j] =~ s{(<section[1-9]+(?: [^>]+)? delsec${level}text=")[^>"]*"}{$1$arr[$j]"}i;
								push @extra_arrs, $arr2[$j]; 
							}
						}
					}
				}
			}
		}
		else {
			if($matchstr2 =~ s{^(\|.+)\|}{}i) {
				my $tmpre = $1;
				
				if(defined($tmpre) and $tmpre !~ m{^\s*$} and length($tmpre) > 1) {
					$tmpre = substr($tmpre, 1);
					my @arr = split(/\|/, $tmpre);
					
					my @arr2 = $section_splited[$i-1] =~ m{(<section[1-9]+(?: [^>]+)? delsec${level}text="[^>"]*"(?:(?! delsec${level}text="|$).)*)(?=<section[1-9]+(?: [^>]+)? delsec${level}text="|$)}ig;
					
					if(scalar(@arr) == scalar(@arr2)) {
						$section_splited[$i-1] =~ s{(<section[1-9]+(?: [^>]+)? delsec${level}text="[^>"]*"(?:(?! delsec${level}text="|$).)*)(?=<section[1-9]+(?: [^>]+)? delsec${level}text="|$)}{}ig;
						
						for(my $j=0; $j<=$#arr2; $j++) {
							$arr2[$j] =~ s{(<section[1-9]+(?: [^>]+)? delsec${level}text=")[^>"]*"}{$1$arr[$j]"}i;
							push @extra_arrs, $arr2[$j]; 
						}
					}
				}
			}
			
		}
	}
	
	if(@extra_arrs) {
		@section_splited = (@section_splited, @extra_arrs);
	}
		
	my $pre1 = shift @section_splited;
	$pre .= "\n$pre1";
	
	foreach my $tm (@section_splited) {
		$tm =~ s{&del;}{}ig;
		if($tm =~ m{^<section[1-9]+(?: [^>]+)? delsec[1-9]+text="($matchstr)"}i) {
			my $tmtxt = $1;
					
			if($tmphash{lc($tmtxt)}[1] =~ m{<ol2[ >]}i) {
				$sections{$tmphash{lc($tmtxt)}[0]} = _make_section($tmphash{lc($tmtxt)}[1], $tm, 2);
				delete $splited_files{$tmphash{lc($tmtxt)}[0]} if(exists $splited_files{$tmphash{lc($tmtxt)}[0]});
			}
			else {
				$sections{$tmphash{lc($tmtxt)}[0]} = $tm;
				delete $splited_files{$tmphash{lc($tmtxt)}[0]} if(exists $splited_files{$tmphash{lc($tmtxt)}[0]});
			}
		}
	}

	return qq($pre\n$back);
}


sub _clear_label_text {
	my $cnt = shift;

	if($cnt =~ m{<h[1-8](?: [^>]+)?>|<p(?: [^>]+)? class="subtitle"}i) {
		$cnt = join("", $cnt =~ m{<(?:h[1-8](?: [^>]+)?|p(?: [^>]+)? class="subtitle")[^>]*>((?:(?!</?h[1-8][ >]|</?p[ >]).)*)</(?:h[1-8]|p)>}ig);
	}

	$cnt =~ s{<span class="(?:label|number)">.*?</span>}{}ig;
	$cnt =~ s{</?[a-z][^>]*>}{}ig;
	$cnt =~ s{([a-rt-z])s(?= |$)}{$1}g;
	$cnt =~ s{&#x([0-9a-f]{4});}{lc(chr(hex($1)))}ige;
	$cnt =~ s{[\.,\-\_:\?;\\\/\(\)\[\]]}{}g;
	$cnt =~ s{\s+}{}g;

	return lc($cnt);
}
	
sub _clear_title {
	my $cnt = shift;	
	 # $cnt =~ s{^(?:[^\d]+)?(?:[0-9]+\.?[0-9]*:?)\s*(.*?)$}{$1}igs;
	 # $cnt =~ s{^(?:[0-9]+\.?[0-9]*:?)\s*(.*?)$}{$1}igs;
	 $cnt =~ s{</?[a-z][^>]*>}{}ig;
	 $cnt =~ s{^\s*(?:session|chapter|section)?\s*[0-9.:]*\s*(.*?)\s*$}{$1}igs;

	 $cnt =~ s{&#x([0-9a-f]{4});}{lc(chr(hex($1)))}ige;
	 $cnt =~ s{\s+}{}g;
	 $cnt =~ s{[^0-9a-z]+$}{}i;
	 
	return lc($cnt);
}

sub _tab_title {
	my $cnt = shift;	
	 $cnt =~ s{</?[a-z][^>]*>}{}ig;
	return $cnt;
}
 sub fileopen{
		my $path = shift;
		open(FF,"$path");
		my $cnt = do {local $/;<FF>};
		close FF;
		return $cnt;
}