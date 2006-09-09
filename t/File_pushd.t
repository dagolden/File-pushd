# File::pushd - check module loading and create testing directory
use strict;
use warnings;

use Test::More tests =>  34 ;
use Cwd 'abs_path';
use File::Path 'rmtree';
use File::Spec::Functions qw( catdir curdir updir canonpath ); 

sub absdir { canonpath( abs_path( shift || curdir() ) ); }

#--------------------------------------------------------------------------#
# Test import
#--------------------------------------------------------------------------#

BEGIN { use_ok( 'File::pushd' ); }
can_ok( 'main', 'pushd', 'tempd' );

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#


my ( $new_dir, $temp_dir, $err );
my $original_dir = absdir();
my $target_dir = 't';
my $expected_dir = catdir($original_dir,$target_dir);
my $nonexistant = 'DFASDFASDFASDFAS';

#--------------------------------------------------------------------------#
# Test error handling on bad target
#--------------------------------------------------------------------------#

eval { $new_dir = pushd($nonexistant) };
$err = $@;
like( $@, qr/\ACouldn't chdir to nonexistant directory/,
    "pushd to nonexistant directory croaks" );

#--------------------------------------------------------------------------#
# Test changing to relative path directory
#--------------------------------------------------------------------------#

$new_dir = pushd($target_dir);

isa_ok( $new_dir, 'File::pushd' );

is( absdir(), $expected_dir, "change directory on pushd (relative path)" );

#--------------------------------------------------------------------------#
# Test stringification
#--------------------------------------------------------------------------#

is( "$new_dir", $expected_dir, "object stringifies" );

#--------------------------------------------------------------------------#
# Test reverting directory
#--------------------------------------------------------------------------#

undef $new_dir;

is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to absolute path directory and reverting
#--------------------------------------------------------------------------#

$new_dir = pushd($expected_dir);
is( absdir(), $expected_dir, "change directory on pushd (absolute path)" );

undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing upwards
#--------------------------------------------------------------------------#

$expected_dir = absdir(updir());
$new_dir = pushd("..");

is( absdir(), $expected_dir, "change directory on pushd (upwards)" );
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to root 
#--------------------------------------------------------------------------#

$new_dir = pushd( absdir('') );

my $curdir = absdir();

is( $curdir, absdir(''),
    "change directory on pushd (root)" );
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing in place
#--------------------------------------------------------------------------#

$new_dir = pushd( );

is( absdir(), $original_dir, 
    "pushd with no argument doesn't change directory" 
);
chdir "t";
is( absdir(), catdir( $original_dir, "t" ) ,
    "changing manually to another directory"
);
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

#--------------------------------------------------------------------------#
# Test changing to temporary dir
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, 
    "tempd changes to new temporary directory" );

undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( ! -e $temp_dir, "temporary directory removed" );

#--------------------------------------------------------------------------#
# Test changing to temporary dir but preserving it
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, 
    "tempd changes to new temporary directory" );

ok( $new_dir->preserve(1), "mark temporary directory for preservation" );
    
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( -e $temp_dir, "temporary directory preserved" );

ok( rmtree( $temp_dir ), "temporary directory manually cleaned up" ); 

#--------------------------------------------------------------------------#
# Test changing to temporary dir, preserve it, then revert
#--------------------------------------------------------------------------#

$new_dir = tempd();
$temp_dir = "$new_dir";

ok( absdir() ne $original_dir, 
    "tempd changes to new temporary directory" );

ok( $new_dir->preserve, "mark temporary directory for preservation" );
ok( ! $new_dir->preserve(0), "mark temporary directory for removal" );
    
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( ! -e $temp_dir, "temporary directory removed" );
#--------------------------------------------------------------------------#
# Test preserve failing on non temp directory
#--------------------------------------------------------------------------#

$new_dir = pushd( catdir( $original_dir, $target_dir ) );

is( absdir(), catdir( $original_dir, $target_dir ), 
    "change directory on pushd" );
$temp_dir = "$new_dir";

ok( $new_dir->preserve, "regular pushd is automatically preserved" );
ok( $new_dir->preserve(0), "can't mark regular pushd for deletion" );
    
undef $new_dir;
is( absdir(), $original_dir,
    "revert directory when variable goes out of scope"
);

ok( -e $expected_dir, "original directory not removed" );


