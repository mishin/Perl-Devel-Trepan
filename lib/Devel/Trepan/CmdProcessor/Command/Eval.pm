# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
use warnings; no warnings 'redefine';

use lib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Eval;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;
use Devel::Trepan::Util;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [STRING]

Run code in the context of the current frame.

The value of the expression is stored into a global variable so it
may be used again easily. The name of the global variable is printed
next to the inspect output of the value.

If no string is given, we run the string from the current source code
about to be run. If the command ends ? (via an alias) and no string is
given we will the following translations occur:

   {if|elsif|unless} (expr) [{]  => expr
   {until|while} (expr) [{]      => expr
   return expr [;]               => expr
   my (expr) = val ;             => expr = val 
   my var = val ;                => var = val 
   case expr                     => expr
   def fn(params)                => (params)
   var = expr                    => expr

The above is done via regular expression. No fancy parsing is done, say,
to look to see if expr is split across a line or whether var an assigment
might have multiple variables on the left-hand side.

Normally, eval runs in a scalar context and so the result is a
scalar. However you can force the type of the result by adding the
apprpropriate sigil @, %, or \$.

Examples:

${NAME} 1+2  # 3
${NAME}\$ 3   # Same as above, but the return type is explicit
${NAME} \$v
${NAME}      # Run current source-code line
${NAME}?     # but strips off leading 'if', 'while', ..
          # from command 
${NAME}@ \@ARGV  # Make sure the result saved is an array rather than 
             # an array converted to a scalar.

See also 'set autoeval'. The command helps one predict future execution.
See 'set buffer trace' for showing what may have already been run.
HELP

use constant ALIASES    => qw(eval? ev? ev eval@ eval$ eval% ev@ ev$ ev%);
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Run code in the current context';
local $NEED_STACK       => 1;

sub complete($$)
{ 
    my ($self, $prefix) = @_;
    if (!$prefix) {
	# if ($self->{proc}.leading_str.start_with?('eval?')) {
	#     Devel::Trepan::Util::extract_expression(
	# 	$self->{proc}->current_source_text());
	# } else {
	    $self->{proc}->current_source_text();
	# }
    } else {
	$prefix;
    }
}

sub run($$)
{
    my ($self, $args) = @_;
    my $text;
    my $cmd_name = $args->[0];
    if (1 == scalar @$args) {
	$text  = $self->{proc}->current_source_text();
	if ('?' eq substr($cmd_name, -1)) {
	    $cmd_name = substr($cmd_name, 0, length($cmd_name)-1);
	    $text = Devel::Trepan::Util::extract_expression($text);
	    $self->{proc}->msg("eval: ${text}");
	}
    } else {
	$text = $self->{proc}->{cmd_argstr};
    }
    {
	my $opts->{return_type} = parse_eval_suffix($cmd_name);
	my $dbgr = $self->{proc}->{dbgr};
	no warnings 'once';
	$DB::eval_str = $dbgr->evalcode($text);
	$DB::eval_opts = $opts;
	$DB::result_opts = $opts;
	$self->{proc}->{leave_cmd_loop} = 1;
    }
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
