# -*- coding: utf-8 -*-
# Copyright (C) 2013, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Substitute;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('sub');
=head2 Synopsis:

=cut
our $HELP   = <<"HELP";
=pod

B<set substitute> [I<subcommand>]

Sometimes the filename or line ranges reported inside the debugger
might not match the filenames or line ranges where you can find the
source in the OS filesystem. This may happen because of pathnames do
not match or program text comes from evaluated lines in code.

=head2 See Also

L<C<set substitute path>|Devel::Trepan::CmdProcessor::Command::Set::Substutute::Path>, and
L<C<set substitute string>|Devel::Trepan::CmdProcessor::Command::Set::Substutute::String>.

=cut
HELP

our $SHORT_HELP = "Set filename remapping";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false)
    # cmd              = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor,
    #                                                      parent_cmd)
    # cmd.run(cmd.prefix + ['string', '30'])

    # %w(s lis foo).each do |prefix|
    #   p [prefix, cmd.complete(prefix)]
    # end
}

1;
