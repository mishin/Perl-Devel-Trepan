# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>

package Devel::Trepan::Client;
use strict;
use English qw( -no_match_vars );

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../..';
    use Devel::Trepan::Interface::ComCodes;
    use Devel::Trepan::Interface::Client;
    use Devel::Trepan::Interface::Script;
    @INC = @OLD_INC;
}

sub new
{
    my ($class, $settings) = @_;
    my $opts = {
	logger => $settings->{logger}
    };
    if ($settings->{'io'} eq 'tcp') {
	$opts = {
	    {host => $settings->{host},
	     port => $settings->{port}}
	}
    } else {
	print "We're tty!\n";
	$opts->{'io'} = 'tty';
	$opts->{inpty_name}  = $settings->{inpty_name};
	$opts->{outpty_name} = $settings->{outpty_name};
    }

    my  $intf = Devel::Trepan::Interface::Client->new(
        undef, undef, undef, $opts );
    my $self = {
        intf => $intf,
        user_inputs => [$intf->{user}]
    };
    bless $self, $class;
}

sub errmsg($$)
{
    my ($self, $msg) = @_;
    $self->{intf}{user}->errmsg($msg);
}

sub msg($$)
{
    my ($self, $msg) = @_;
    chomp $msg;
    $self->{intf}{user}->msg($msg);
}

sub run_command($$$$)
{
    my ($self, $intf, $current_command) = @_;
    if (substr($current_command, 0, 1) eq '.') {
        $current_command = substr($current_command, 1);
        my @args = split(' ', $current_command);
        my $cmd_name = shift @args;
        my $script_file = shift @args;
        if ('source' eq $cmd_name) {
            my $result =
                Devel::Trepan::Util::invalid_filename($script_file);
            unless (defined $result) {
                $self->errmsg($result);
                return 0;
            }
            my $script_intf =
                Devel::Trepan::Interface::Script->new($script_file);
            unshift @{$self->{user_inputs}}, $script_intf->{input};
            $current_command = $script_intf->read_command;
        } else {
            $self->errmsg(sprintf "Unknown command: '%s'", $cmd_name);
            return 0;
        };
    } eval {
        $intf->write_remote(COMMAND, $current_command);
    };
    return 1;
}

sub start_client($)
{
    my $options = shift;
    printf "Client option given\n";
    my $opts = {
        client      => 1,
	cmdfiles    => [],
	initial_dir => $options->{chdir},
	logger      => $options->{logger},
	nx          => 1,
    };

    if ($options->{'io'} eq 'tcp') {
	$opts->{host} = $options->{host},
	$opts->{port} = $options->{port};
    } else {
	$opts->{io} = 'tty';
	$opts->{inpty_name} = $options->{inpty_name};
	$opts->{outpty_name} = $options->{outpty_name};
    }

    my $client = Devel::Trepan::Client->new($opts);
    my $intf = $client->{intf};
    my ($control_code, $line);
    while (1) {
        eval {
            ($control_code, $line) = $intf->read_remote;
        };
        if ($EVAL_ERROR) {
            $client->msg("$EVAL_ERROR");
            $client->msg("Remote debugged process may have closed connection");
            last;
        }
        # p [control_code, line]
        if (PRINT eq $control_code) {
            $client->msg("$line");
        } elsif (CONFIRM_TRUE eq $control_code) {
            my $response = $intf->confirm($line, 1);
            $intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
        } elsif (CONFIRM_FALSE eq $control_code) {
            my $response = $intf->confirm($line, 1);
            $intf->write_remote(CONFIRM_REPLY, $response ? 'Y' : 'N');
        } elsif (PROMPT eq $control_code) {
            my $command;
            my $leave_loop = 0;
            until ($leave_loop) {
                eval {
                    $command = $client->{user_inputs}[0]->read_command($line);
                };
                # if ($intf->is_input_eof) {
                #       print "user-side EOF. Quitting...\n";
                #       last;
                # }
                if ($EVAL_ERROR) {
                    if (scalar @{$client->{user_inputs}} == 0) {
                        $client->msg("user-side EOF. Quitting...");
                        last;
                    } else {
                        shift @{$client->{user_inputs}};
                        next;
                    }
                };
                $leave_loop = $client->run_command($intf, $command);
                if ($EVAL_ERROR) {
                    $client->msg("Remote debugged process died");
                    last;
                }
            }
        } elsif (QUIT eq $control_code) {
            last;
        } elsif (RESTART eq $control_code) {
            $intf->close;
            # Make another connection..
            $client = Devel::Trepan::Client->new(
                {client      => 1,
                 cmdfiles    => [],
                 initial_dir => $options->{chdir},
                 nx          => 1,
                 host        => $options->{host},
                 port        => $options->{port}}
                );
            $intf = $client->{intf};
        } elsif (SERVERERR eq $control_code) {
            $client->errmsg($line);
        } else {
            $client->errmsg("Unknown control code: '$control_code'");
        }
    }
}

unless (caller) {

    # Devel::Trepan::Client::start_client({host=>'127.0.0.1', port=>1954});
    Devel::Trepan::Client::start_client({io=>'tty', logger => \*STDOUT});
    #Devel::Trepan::Client::start_client({io=>'tty', logger => \*STDOUT,
    #				inpty_name =>'/dev/pts/12', outpty_name =>'/dev/pts/11'});
}

1;
