use warnings;
use strict;
package Clusterize::Pattern;
use Digest::MD5;
our $VERSION = '0.01';

my @char_group = qw ( \d [a-f] [a-z] [A-F] [A-Z] [a-f\d] [a-z\d] [A-F\d]
	[A-Z\d] [A-Fa-f] [A-Za-z] [A-Fa-f\d] [A-Za-z\d] );
my @char_group_rx = map { [ $_, qr/^$_+$/ ] } @char_group;
my $regexp = eval 'qr/('.join('|', map { $_.'+' } @char_group).')/';

sub new { 
	my ($class, $pairs) = @_;
	my $md5 = Digest::MD5->new;
	for ( sort keys %{$pairs} ) { $md5->add($_) }
	return bless { size => scalar keys %{$pairs},
	pairs => $pairs, digest => $md5->hexdigest }, $class 
}

sub regexp { return join("", map {$_->[0].$_->[1]}  @{_build_pattern($_[1])}) }
sub char_group { for (@char_group_rx) {return $_->[0] if $1 =~ /$_->[1]/} }
sub pairs { shift->{pairs} }
sub digest { shift->{digest} }
sub size { shift->{size} }

sub text2digest {
	my %digest;
	for my $str (grep { /\S/ } @{$_[1]}) {
		for (_str2digest($str)) { $digest{$_} = $str }
	}
	\%digest;
}

sub _str2digest {
	my $str = shift;
	chomp $str;
	my %digest;
	$digest{_digest($str, { regexp => qr/^(.*)$/, sub => sub { '\w' } })} = 1;
	$digest{_digest($str, { regexp => qr/^(.*)$/, sub => sub { '\w' }, len => 1 })} = 1;
	$digest{_digest($str, { regexp => $regexp })} = 1;
	$digest{_digest($str, { regexp => $regexp, len => 1 })} = 1;
	$digest{_digest($str, { regexp => qr/\b$regexp\b/ })} = 1;
	$digest{_digest($str, { regexp => qr/\b$regexp\b/, len => 1 })} = 1;
	keys %digest;
}

sub _digest {
	my ($str, $opt) = @_;
	$str =~ s/([A-Za-z\d]+)/&_build_char_group($opt)/ge;
	$str;	
}

sub _build_char_group {
	my ($str, $opt) = ($1, shift);
	$opt->{sub} ||= \&char_group;
	if ($opt->{len}) {
		$str =~ s/$opt->{regexp}/&{$opt->{sub}}.'{'.length($1).'}'/ge;
	} else { $str =~ s/$opt->{regexp}/&{$opt->{sub}}.'+'/ge }
	$str;
}

sub _build_pattern {
	my $min_len = length $_[0][0] if @{$_[0]};
	my @pos = ();
	for (@{$_[0]}) {
		chomp;
		my $j = 0;
		for (split //) { $pos[$j++]{$_} = 1 }
		$min_len = $j if $j < $min_len;
	}
	_join_pattern($min_len, @pos);
}

sub _join_pattern {
	my $min_len = shift;
	my @pat = _unix_uniq(map { _char_interval($_) } @_[0..($min_len - 1)]);
	my @pat_rest = _unix_uniq(map { _char_interval($_) } @_[$min_len..$#_]);
	my $bound_pat;
	if (@pat && @pat_rest && $pat[$#pat][0] eq $pat_rest[0][0]) {
		my ($p1, $p2) = (pop @pat, shift @pat_rest);
		$bound_pat = [ $p1->[0], '{'.$p1->[1].','.($p1->[1] + $p2->[1]).'}' ];
	}
	@pat = map { [ $_->[0], $_->[1] > 1 ? "{$_->[1]}" : "" ] } @pat;
	push @pat, $bound_pat if $bound_pat;
	push @pat, map { [ $_->[0], $_->[1] > 1 ? "{0,$_->[1]}" : "?" ] } @pat_rest;
	\@pat;
}

sub _unix_uniq {
	my @str;
	for (@_) {
		if (!@str || $str[$#str][0] ne $_ || /^.$/) {
			push @str, [ $_, 1 ];
		} else { $str[$#str][1]++ }
	}
	@str;
}

sub _char_interval {
	my $str = join '', sort keys %{$_[0]};
	return $str if length $str == 1;
	return '['.$str.']' if length $str == 2;
	for ( @char_group_rx ) { return $_->[0] if $str =~ /$_->[1]/ }
	return '.';
}

sub _calc_accuracy {
	my ($self, $pattern_parts_ref) = @_;
	my $other_cnt = scalar(map { $_ } $self->{pattern} =~ /[^A-Za-z\d\s]/g);
	my $space_cnt = scalar(map { $_ } $self->{pattern} =~ /\s/g) || 0;
	my $char_cnt = scalar(grep { $_->[0] =~ /^.$/ && $_->[1] eq '' }
		map { @{$_} } @{$pattern_parts_ref});
	my $length_factor = -exp(-0.05 * $self->{avg_len}) + 1;
	my $space_factor = ($char_cnt + $other_cnt < $space_cnt) ?
		-exp(-0.2 * ($char_cnt + $other_cnt)) + 1 : 1;
	$length_factor * ($char_cnt + $other_cnt + ($space_factor * $space_cnt))
	/ $self->{avg_len};
}

sub pattern {
	my $self = shift;
	return $self->{pattern} if exists $self->{pattern};
	my @parts;
	for (values %{$self->{pairs}}) {
		my $i = 0;
		for (/([A-Za-z\d]+)/g) { push @{$parts[$i++]}, $_ }
		$self->{avg_len} += length $_;
	}
	$self->{avg_len} /= $self->size;
	my @pattern_parts = map { _build_pattern($_) } @parts;
	chomp($self->{pattern} = (values %{$self->{pairs}})[0]);
	$self->{accuracy} = $self->_calc_accuracy(\@pattern_parts);
	$self->{pattern} =~ s/([A-Za-z\d]+)/
		join('', map { $_->[0].$_->[1] } @{shift(@pattern_parts)})/xge;
	$self->{pattern};
}

sub accuracy { 
	my $self = shift;
	$self->pattern unless exists $self->{pattern};
	$self->{accuracy}
}

1;

=head1 NAME

Clusterize::Pattern - provides various information about clusters built by Clusterize module.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

B<Clusterize::Pattern> module is used by B<Clusterize> module to provide the following information for the cluster: B<pattern>, B<accuracy>, B<size>, B<digest>.

=head1 METHODS

=head2 pattern

Returns regular expression that matches all strings in given cluster.

=head2 accuracy

Returns the value between 0 and 1 that reflects the similarity of strings in the given cluster.
The accuracy value tends to 1 for very accurate clusters and to 0 for fuzzy clusters.

=head2 size

Returns the number of unique keys in given cluster.

=head2 digest

Returns MD5 hex digest for given cluster. It could be used to identify unique clusters.

=head2 pairs

Returns hash of key/value pairs for given cluster.


=head1 AUTHOR

Slava Moiseev, <slava.moiseev@yahoo.com>

