# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Debug;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;

    eval <<"EOE";
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'debug into a Perl expression';
use constant MIN_ARGS  => 1;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE

use strict;
use Devel::Trepan::Util;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [STRING]

Recursive debug STRING.

Examples:

${NAME} finonacci(5)   # Debug fibonacci funcition
${NAME} \$x=1; \$y=2;    # Kind of pointless, but doable.
HELP

local $NEED_STACK       => 0;

# sub complete($$)
# { 
#     my ($self, $prefix) = @_;
# }

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $expr = $proc->{cmd_argstr};
    # Trim leading and trailing spaces.
    $expr =~ s/^\s+//; $expr =~ s/\s+$//;
    my $cmd_name = $args->[0];
    no warnings 'once';
    my $opts = {
	return_type => parse_eval_suffix($cmd_name),
	nest => $DB::level
    };

    # Have to use $^D rather than $DEBUGGER below since we are in the
    # user's code and they might not have English set.
    my $full_expr = 
	"\$DB::single = 1;\n\$^D |= DB::db_stop;\n\$DB::in_debugger=0;\n" . 
	$expr;
    $proc->evaluate($full_expr, $opts);
}

unless (caller) {
  # require_relative '../mock'
  # dbgr, cmd = MockDebugger::setup
  # arg_str = '1 + 2'
  # cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  # puts "eval ${arg_str} is: ${cmd.run([cmd.name, arg_str])}"
  # arg_str = 'return "foo"'
  # # def cmd.proc.current_source_text
  # #   'return "foo"'
  # # end
  # # cmd.proc.instance_variable_set('@cmd_argstr', arg_str)
  # # puts "eval? ${arg_str} is: ${cmd.run([cmd.name + '?'])}"
}
