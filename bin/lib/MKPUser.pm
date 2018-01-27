package MKPUser ;

use base qw(Exporter);
use strict;

our @EXPORT = qw($userdbh validate dienice dbdie);
our @EXPORT_OK = qw();

use DBI;
use CGI qw(:standard);

our $userdbh = DBI->connect( "dbi:mysql:usertable", "usertable", "jutedi2") or
    &dienice("Can't connect to db: $DBI::errstr");

sub validate
{
    # look for the cookie. if it exists and is valid, return the
    # username associated with that cookie.
     my $username = "";
     if (cookie('cid'))
     {
         my $sth = $userdbh->prepare("select * from user_cookies where cookie_id=?") or &dbdie;
         $sth->execute(cookie('cid')) or &dbdie;
         my $rec;

         # there's a cookie set in the browser but we don't have a record
         # for it in the db.
         unless ($rec = $sth->fetchrow_hashref)
         {
             &goto_login() ;
         }

         # their IP address has changed since the last time they 
         # were here.
         if ($rec->{remote_ip} ne $ENV{REMOTE_ADDR})
         {
             &goto_login() ;
         }
         $username = $rec->{username};
    }
    else
    {
        # no cookie is set. go to the login page.
        &goto_login() ;
    }
    return $username ;
}

sub dienice
{
    my($msg) = @_;
    print header;
    print start_html("Error");
    print "<h2>Error</h2>\n";
    print $msg;
    exit;
}

sub goto_login
{
    # by passing the attempted URL on to login.cgi, you can
    # redirect to that URL once they successfully log in
    my $url = $ENV{REQUEST_URI};
    print redirect("http://prod.mkpproducts.com/login.cgi");
    exit;
}

sub dbdie {
    my($package, $filename, $line) = caller;
    my($errmsg) = "Database error: $DBI::errstr<br>\n called from $package $filename line $line";
    &dienice($errmsg);
}

1;