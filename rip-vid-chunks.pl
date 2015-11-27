#!/usr/bin/env perl

# 1) URL of first video
#    file01 = http://teamfourstar.com/video/tfs-abridged-parody-episode-2-2/
# 2) Find player script at this location
#    file02 = grep video-container file01
# 3) Find Server var SWMServer = "174.127.86.19" and VidId ('vidid':  "TeamFourStar-2nYozPLpJRE")
#    ServerIP = grep SWMServer
#    VideoID  = grep \'vidid\' file02
# 4) http://174.127.86.19/vod/smil:TeamFourStar-2nYozPLpJRE.smil/TeamFourStar-2nYozPLpJRE__hd1.mp4-n_[0-2]_0_0.ts?nimblesessionid=7466337


# http://206.217.201.111/vod/smil:TeamFourStar-55b9c630b7268.smil/playlist.m3u8

use strict;
use warnings;

#print "$ENV{PWD}\n";
main();

sub main {
    my $newUrl = "";
    my $oldUrl = "http://teamfourstar.com/video/tfs-abridged-parody-episode-3-2/";
    while (1==1)
    {
        my $title = `curl $oldUrl | grep heroheadingtitle | awk -F'>' '{print \$2}' | awk -F'<' '{print \$1}'`; chomp($title);
        my $date  = `curl $oldUrl | grep heroheadingdate | awk -F'>' '{print \$2}' | awk -F'<' '{print \$1}'`; chomp($date);
        my $dir = "$date - $title";
        mkdir $dir;

        `curl $oldUrl -o \'./$dir/page.html\'`;
        my $scriptUrl = `cat \'./$dir/page.html\' | grep id=\\"video-container | awk -F'src=\\"' '{print \$2}' | awk -F'"' '{print \$1}'`; chomp($scriptUrl);
        
        `curl $scriptUrl -o \'./$dir/page.js\'`;
        my $ip        = `cat \'./$dir/page.js\' | grep SWMServer | awk -F'"' '{print \$2}' | head -n 1`; chomp($ip);
        my $vidid     = `cat \'./$dir/page.js\' | grep \\'vidid\\' | awk -F'"' '{print \$2}' | head -n 1`; chomp($vidid);
        my $smilPath  = "http://$ip/vod/smil:$vidid.smil";
        `curl $smilPath/playlist.m3u8 -o \'./$dir/page.smil\'`;
        my $chunksUrl = `cat \'./$dir/page.smil\' | grep _hd1 | head -n 1`; chomp($chunksUrl);
        `curl $smilPath/$chunksUrl -o \'./$dir/page.m3u8\'`;

        print "\n\n".
            "TITLE : $title\n".
            "DATE  : $date \n".
            "JS    : $scriptUrl \n".
            "SMIL  : $smilPath \n".
            "M3U8  : $chunksUrl \n".
            "\n\n";

        my @lines = split /\n/, `cat \'./$dir/page.m3u8\'`;
        foreach my $line (@lines) {
            chomp($line);
            if($line =~ /^(.+\.ts)/i) {
                print "curl $smilPath/$line -o \'./$dir/$1\'\n";
                `curl $smilPath/$line -o \'./$dir/$1\'`;
            }
        }
        print "\n--------------------------------------\n";
        # grab next pages URL
        $newUrl = nextVideoURL($oldUrl);
        return if($newUrl eq "");
        $oldUrl = $newUrl;
    }
}

sub nextVideoURL {
    return ""; # if((scalar @_) != 1);
    my ($str) = @_;
    $str = `curl $str | awk -F\'href=\\"\' \'\/nextlistitem listitem\/{print \$NF}\' | awk -F\'\#video-container' \'{print \$1}\' | sort -u`;
    chomp($str);
    return $str;
}