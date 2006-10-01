# BSD::Sysctl.pm - Access BSD sysctl(8) information directly
#
# Copyright (C) 2006 David Landgren, all rights reserved

package BSD::Sysctl;

use strict;
use warnings;

use Exporter;
use XSLoader;

use vars qw($VERSION @ISA %MIB_CACHE %MIB_SKIP @EXPORT_OK);

$VERSION = '0.01';
@ISA     = qw(Exporter);

use constant FMT_A           =>  1;
use constant FMT_INT         =>  2;
use constant FMT_UINT        =>  3;
use constant FMT_LONG        =>  4;
use constant FMT_ULONG       =>  5;
use constant FMT_N           =>  6;
use constant FMT_BOOTINFO    =>  7;
use constant FMT_CLOCKINFO   =>  8;
use constant FMT_DEVSTAT     =>  9;
use constant FMT_ICMPSTAT    => 10;
use constant FMT_IGMPSTAT    => 11;
use constant FMT_IPSTAT      => 12;
use constant FMT_LOADAVG     => 13;
use constant FMT_MBSTAT      => 14;
use constant FMT_NFSRVSTATS  => 15;
use constant FMT_NFSSTATS    => 16;
use constant FMT_NTPTIMEVAL  => 17;
use constant FMT_RIP6STAT    => 18;
use constant FMT_TCPSTAT     => 19;
use constant FMT_TIMEVAL     => 20;
use constant FMT_UDPSTAT     => 21;
use constant FMT_VMTOTAL     => 22;
use constant FMT_XINPCB      => 23;
use constant FMT_XVFSCONF    => 24;
use constant FMT_STRUCT_CDEV => 25;

# explicitly short-circuit a segfault until I can figure out why
# some of these might be nodes rather than leaves
%MIB_SKIP = map {($_,1)} qw(
    dev.acd.%parent
    dev.acd.0.%location
    dev.acd.0.%pnpinfo
    dev.acpi.%parent
    dev.acpi.0.%location
    dev.acpi.0.%pnpinfo
    dev.acpi_acad.%parent
    dev.acpi_button.%parent
    dev.acpi_ec.%parent
    dev.acpi_lid.%parent
    dev.acpi_sysresource.%parent
    dev.acpi_timer.%parent
    dev.ad.%parent
    dev.ad.0.%location
    dev.ad.0.%pnpinfo
    dev.agp.%parent
    dev.ata.%parent
    dev.ata.0.%location
    dev.ata.0.%pnpinfo
    dev.ata.1.%location
    dev.ata.1.%pnpinfo
    dev.atapci.%parent
    dev.atdma.%parent
    dev.atkbd.%parent
    dev.atkbd.0.%location
    dev.atkbd.0.%pnpinfo
    dev.atkbdc.%parent
    dev.atpic.%parent
    dev.attimer.%parent
    dev.battery.%parent
    dev.cardbus.0.%location
    dev.cardbus.0.%pnpinfo
    dev.cardbus.1.%location
    dev.cardbus.1.%pnpinfo
    dev.cbb.%parent
    dev.cpu.%parent
    dev.drmsub.%parent
    dev.fd.%parent
    dev.fd.0.%location
    dev.fd.0.%pnpinfo
    dev.fdc.%parent
    dev.fxp.%parent
    dev.hostb.%parent
    dev.inphy.%parent
    dev.isa.%parent
    dev.isa.0.%location
    dev.isa.0.%pnpinfo
    dev.isab.%parent
    dev.miibus.%parent
    dev.miibus.0.%location
    dev.miibus.0.%pnpinfo
    dev.nexus.%parent
    dev.nexus.0.%desc
    dev.nexus.0.%location
    dev.nexus.0.%pnpinfo
    dev.npx.%parent
    dev.npx.0.%location
    dev.npx.0.%pnpinfo
    dev.npxisa.%parent
    dev.orm.%parent
    dev.orm.0.%location
    dev.orm.0.%pnpinfo
    dev.pccard.%parent
    dev.pccard.0.%location
    dev.pccard.0.%pnpinfo
    dev.pccard.1.%location
    dev.pccard.1.%pnpinfo
    dev.pci.%parent
    dev.pci.0.%location
    dev.pci.0.%pnpinfo
    dev.pci.2.%location
    dev.pci.2.%pnpinfo
    dev.pcib.%parent
    dev.pci_link.%parent
    dev.pmtimer.%parent
    dev.pmtimer.0.%desc
    dev.pmtimer.0.%location
    dev.pmtimer.0.%pnpinfo
    dev.ppc.%parent
    dev.ppbus.%parent
    dev.ppbus.0.%location
    dev.ppbus.0.%pnpinfo
    dev.psm.%parent
    dev.psm.0.%location
    dev.psm.0.%pnpinfo
    dev.psmcpnp.%parent
    dev.sc.%parent
    dev.sc.0.%location
    dev.sc.0.%pnpinfo
    dev.sio.%parent
    dev.sio.0.%desc
    dev.sio.0.%location
    dev.sio.0.%pnpinfo
    dev.uhci.%parent
    dev.uhub.%parent
    dev.uhub.0.%location
    dev.uhub.0.%pnpinfo
    dev.uhub.1.%location
    dev.uhub.1.%pnpinfo
    dev.uhub.2.%location
    dev.uhub.2.%pnpinfo
    dev.usb.%parent
    dev.usb.0.%location
    dev.usb.0.%pnpinfo
    dev.usb.1.%location
    dev.usb.1.%pnpinfo
    dev.usb.2.%location
    dev.usb.2.%pnpinfo
    dev.vga.%parent
    dev.vga.0.%location
    dev.vga.0.%pnpinfo
    hw.dri.0.bufs
    machdep.siots
);

push @EXPORT_OK, 'sysctl';
sub sysctl {
    my $mib = shift;
    return -1 if exists $MIB_SKIP{$mib};
    return undef unless exists $MIB_CACHE{$mib} or _mib_info($mib);
    return _mib_lookup($mib);
}

push @EXPORT_OK, 'sysctl_exists';
sub sysctl_exists {
    return _mib_exists($_[0]);
}

XSLoader::load 'BSD::Sysctl', $VERSION;

=head1 NAME

BSD::Sysctl - Fetch sysctl values from BSD-like systems

=head1 VERSION

This document describes version 0.01 of BSD::Sysctl,
release 2006-07-22.

=head1 SYNOPSIS

  use BSD::Sysctl 'sysctl';

  # exact values will vary
  print sysctl('kern.lastpid'); # 20621

  my $loadavg = sysctl('vm.loadavg');
  print $loadavg->[1]; # 0.1279 (5 minute load average)

  my $vm = sysctl('vm.vmtotal');
  print "number of free pages: $vm->{pagefree}\n";

=head1 DESCRIPTION

Note: this is an alpha release.

C<BSD::Sysctl> offers a native Perl interface for fetching sysctl
values that describe the kernel state of BSD-like operating systems.
This is around 80 times faster than scraping the output of the
C<sysctl(8)> program.

This module handles the conversion of symbolic sysctl variable names
to the internal numeric format, and this information, along with
the details of how to format the results, are cached. Hence, the
first call to C<sysctl> requires three system calls, however,
subsequent calls require only one call.

=head2 ROUTINES

=over 4

=item sysctl

Perform a sysctl system call. Takes the symbolic name of a sysctl
variable name, for instance C<kern.maxfilesperproc>, C<net.inet.ip.ttl>.
In most circumstances, a scalar is returned (in the event that the
variable has a single value).

In some circumstances a reference to an array is returned, when the
variable represents a list of values (for instance, C<kern.cp_time>).

In other circumstances, a reference to a hash is returned, when the
variable represents a heterogeneous collection of values (for
instance, C<kern.clockrate>, C<vm.vmtotal>). In these cases, the
hash key names are reasonably self-explanatory, however, passing
familiarity with kernel data structures is expected.

A certain number of opaque variables are fully decoded (and the
results are returned as hashes), whereas the C<sysctl> binary renders
them as a raw hexdump (for example, C<net.inet.tcp.stats>).

=item sysctl_set

Perform a sysctl system call to set a sysctl variable to a new
value. This requires C<root> privileges. NOT YET IMPLEMENTED.

=item sysctl_exists

Check whether the variable name exists. Returns true or false
depending on whether the name is recognised by the system.

Checking whether a variable exists does not perform the
conversion to the numeric OID (and the attendant caching).

=back

=head1 DIAGNOSTICS

  "uncached mib: [sysctl name]"

A sysctl variable name was passed to the internal function
C<_mib_lookup>, but C<_mib_lookup> doesn't now how to deal with it,
since C<_mib_info> has not been called for this variable name. This
is normally impossible if you stick to the public functions.

  "get sysctl [sysctl name] failed"

The kernel system call to get the value associated with a sysctl
variable failed. If C<sysctl ...> from the command line succeeds
(that is, using the C<sysctl(8)> program), this is a bug that should
be reported.

  "[sysctl name] unhandled format type=[number]"

The sysctl call returned a variable that we don't know how to format,
at least for the time being. This is a bug that should be reported.

=head1 LIMITATIONS

At the current time, only FreeBSD versions 4.x through 6.x are
supported.

Setting sysctl values is currently not supported. This functionality
will be developed in subsequent versions.

I am looking for volunteers to help port this module to NetBSD and
OpenBSD (or access to such machines), and possibly even Solaris.
If you are interested in helping, please consult the README file
for more information.

=head1 BUGS

This is my first XS module. I may be doing wild and dangerous things
and not realise it. Gentle nudges in the right direction will be
gratefully received.

Some sysctl values cannot be fetched, even though the C<sysctl>
program can (as it uses an undocumented approach). This functionality
may be added in the future.

Other sysctl values cannot be displayed, since they appear to be
pointers, and dump core when dereferenced. In this case, a result
of -1 is returned. Most values of this type occur in the C<dev.>
hierarchy.

Some sysctl values are 64-bit quantities. I am not all sure that
these are handled correctly.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BSD-Sysctl|rt.cpan.org>.

A short snippet demonstrating the problem, along with the expected
and actual output, and the version of BSD::Sysctl used, will be
appreciated.

=head1 AUTHOR

David Landgren.

Copyright (C) 2006, all rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
