package Apache::Options;
require Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(&OPT_NONE &OPT_INDEXES &OPT_INCLUDES 
	     &OPT_SYMLINKS &OPT_EXECCGI &OPT_UNSET &OPT_INCNOEXEC
	     &OPT_SYM_OWNER &OPT_MULTI &OPT_ALL);

#we'll save h2xs for a rainy day 
#define OPT_NONE 0
#define OPT_INDEXES 1
#define OPT_INCLUDES 2
#define OPT_SYM_LINKS 4
#define OPT_EXECCGI 8
#define OPT_UNSET 16
#define OPT_INCNOEXEC 32
#define OPT_SYM_OWNER 64
#define OPT_MULTI 128
#define OPT_ALL (OPT_INDEXES|OPT_INCLUDES|OPT_SYM_LINKS|OPT_EXECCGI)

sub OPT_NONE {0}
sub OPT_INDEXES {1}
sub OPT_INCLUDES {2}
sub OPT_SYM_LINKS {4}
sub OPT_EXECCGI {8}
sub OPT_UNSET {16}
sub OPT_INCNOEXEC {32}
sub OPT_SYM_OWNER {64}
sub OPT_MULTI {128}
sub OPT_ALL { OPT_INDEXES|OPT_INCLUDES|OPT_SYM_LINKS|OPT_EXECCGI }

1;

__END__

=head1 NAME

Apache::Options - OPT_* defines from httpd_core.h

=head1 DESCRIPTION

Constants for PerlModule's to behave like apache modules

