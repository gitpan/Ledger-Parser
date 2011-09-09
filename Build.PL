
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Parse Ledger journals',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Ledger-Parser',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Ledger::Parser',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Array::Iterator' => '0.07',
    'File::Slurp' => '0',
    'Log::Any' => '0',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
