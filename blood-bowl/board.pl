#!/usr/bin/env perl

# This script generates a 3x3 board section as a test for bloodbowl

use v5.16;
use Template;

# Cut through - Edge of board including boarder
# Etch - Lines
# Cut part - Edges of cells

my $CUT_THROUGH = 'black';
my $CUT_PART = 'blue';
my $ETCH = 'yellow';

my $UNIT = 29; # Length of an edge of a square in mm

my $X_SQUARES = 5;
my $Y_SQUARES = 5;

my $X_TILES = 2;
my $Y_TILES = 2;

my $JIG_LINE = 10;
my $JIG_DEPTH = 5;
my $JIG_TAB_WIDTH = 20;

my $offset = $UNIT; # To contain the jigsaw stick outs and make sure we aren't going
                             # to run into issues with a misaligned main piece

# Just so the SVG itself is big enough to contain everything that needs to be cut
my $mat_width = ($X_TILES * $X_SQUARES * $UNIT) + (2 * $offset) + $UNIT;
my $mat_height= ($Y_TILES * $Y_SQUARES * $UNIT) + (2 * $offset) + $UNIT;

############

# TODO remove borders everywhere because of the jigsaw rules

begin();

# This is the tile for the bottom left of the board
edge(0, 0, { top => 0, right => 'cut', bottom => 'cut', left => 0 }, $CUT_THROUGH);
edge($X_SQUARES * $UNIT, 0, { top => 0, right => 'cut', bottom => 'cut', left => 'gap' }, $CUT_THROUGH);
edge(0, $Y_SQUARES * $UNIT, { top => 'gap', right => 'cut', bottom => 'cut', left => 0 }, $CUT_THROUGH);
edge($X_SQUARES * $UNIT, $Y_SQUARES * $UNIT, { top => 'gap', right => 'cut', bottom => 'cut', left => 'gap' }, $CUT_THROUGH);

grid(1, $X_SQUARES * 2 + 1, $Y_SQUARES * 2 + 1);
#edge({ top => 1, right => 1, bottom => 1, left => 0 }, $CUT_THROUGH);
end();

###########

sub begin {
    say qq{<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="${mat_width}mm" height="${mat_height}mm" version="1.1"
    xmlns="http://www.w3.org/2000/svg">        
    };
}

sub edge {
    # This is the area that will be cut out completely
    my ($x_start, $y_start, $borders, $colour) = @_;
    my $x_length = $X_SQUARES * $UNIT;
    my $y_length = $Y_SQUARES * $UNIT;
    my ($x, $y, @args);
    # Top
    $x = $x_start + 0;
    $y = $y_start + 0;
    $x += $offset; $y += $offset;
    tile_edge($borders->{top}, $x, $y, $x + $x_length, $y, $colour);
    # Right
    $x = $x_start + $x_length;
    $y = $y_start + 0;
    $x += $offset; $y += $offset;
    tile_edge($borders->{right}, $x, $y, $x, $y + $y_length, $colour);
    # Bottom
    $x = $x_start + 0;
    $y = $y_start + $y_length;
    $x += $offset; $y += $offset;
    tile_edge($borders->{bottom}, $x, $y, $x + $x_length, $y, $colour);
    # Left
    $x = $x_start + 0;
    $y = $y_start + 0;
    $x += $offset; $y += $offset;
    tile_edge($borders->{left}, $x, $y, $x, $y + $y_length, $colour);
}

sub grid {
    my ($starting_filled, $x, $y) = @_;
    for my $col (0 .. $y - 1) {
        my $fill = (($starting_filled + $col) % 2);
        # say "<!-- Start Col $col Filled $fill -->";
        for my $row (0 .. $x - 1) {
            # say "<!-- Start Row $row Filled $fill -->";
            square($col, $row, $ETCH) if $fill;
            $fill = ($fill + 1) % 2;
        }
    }
}

sub tile_edge {
    my ($jigsaw, $x, $y, $x2, $y2, $colour) = @_;
    if ($jigsaw) {
        my $direction = ($x == $x2) ? 'x' : 'y';
        my ($line_length, $edge_component_length);
        if ($direction eq 'y') {
            $line_length = $x2 - $x;
            $edge_component_length = ($line_length - 2 * $JIG_LINE) / 3;
            line($x, $y, $x + $edge_component_length, $y2, $colour);
            tab('down', $x + $edge_component_length, $y, $colour) if $jigsaw eq 'cut';
            line($x + $edge_component_length + $JIG_LINE, $y, $x + 2*$edge_component_length + $JIG_LINE, $y2, $colour);
            tab('up', $x + 2*$edge_component_length + 2*$JIG_LINE, $y, $colour) if $jigsaw eq 'cut';
            line($x + 2*$edge_component_length + 2*$JIG_LINE, $y, $x + 3*$edge_component_length + 2*$JIG_LINE, $y2, $colour);
        } else {
            $line_length = $y2 - $y;
            $edge_component_length = ($line_length - 2 * $JIG_LINE) / 3;
            line($x, $y, $x2, $y + $edge_component_length, $colour);
            tab('left', $x2, $y + $edge_component_length, $colour) if $jigsaw eq 'cut';
            line($x, $y + $edge_component_length + $JIG_LINE, $x2, $y + 2*$edge_component_length + $JIG_LINE, $colour);
            tab('right', $x2, $y + 2*$edge_component_length + $JIG_LINE, $colour) if $jigsaw eq 'cut';
            line($x, $y + 2*$edge_component_length + 2*$JIG_LINE, $x2, $y + 3*$edge_component_length + 2*$JIG_LINE, $colour);
        }
    } else {
        line($x, $y, $x2, $y2, $colour);
    }
}

sub line {
    my ($x, $y, $x2, $y2, $colour) = @_;
    say qq{<line x1="${x}mm" y1="${y}mm" x2="${x2}mm" y2="${y2}mm" stroke-width="0.5mm" stroke="${colour}" />};
}

sub tab {
    my ($direction, $x, $y, $colour) = @_;
        say "<!-- Tab Direction: $direction -->";
    if (grep { $_ eq $direction } qw/up down/) {
        my $jig_depth = ($direction eq 'down') ? $JIG_DEPTH : 0 - $JIG_DEPTH;
        my $jig_line = ($direction eq 'down') ? $JIG_LINE : 0 - $JIG_LINE;
        #line($x, $y, $x, $y + $jig_depth, $colour);
        line($x, $y, $x, $y + $jig_depth, $colour);
        line($x + $jig_line, $y, $x + $jig_line, $y + $jig_depth, $colour);

        line($x - $jig_depth, $y + $jig_depth, $x, $y + $jig_depth, $colour);
        line($x + $jig_line, $y + $jig_depth, $x + $jig_line + $jig_depth, $y + $jig_depth, $colour);

        line($x - $jig_depth, $y + $jig_depth, $x - $jig_depth, $y + 2*$jig_depth, $colour);
        line($x + $jig_line + $jig_depth, $y + $jig_depth, $x + $jig_line + $jig_depth, $y + 2*$jig_depth, $colour);

        line($x - $jig_depth, $y + 2*$jig_depth, $x + $jig_line + $jig_depth, $y + 2*$jig_depth, $colour);
    } else {
        my $jig_depth = ($direction eq 'right') ? $JIG_DEPTH : 0 - $JIG_DEPTH;
        my $jig_line = ($direction eq 'right') ? $JIG_LINE : 0 - $JIG_LINE;
        if ($direction eq 'left') {
            # Because we draw the left ones backwards, the point of origin needs to be offset
            $y = $y + $JIG_LINE;
        }
        line($x, $y, $x + $jig_depth, $y, $colour);
        line($x, $y + $jig_line, $x + $jig_depth, $y + $jig_line, $colour);

        line($x + $jig_depth, $y - $jig_depth, $x + $jig_depth, $y, $colour);
        line($x + $jig_depth, $y + $jig_line, $x + $jig_depth, $y + $jig_line + $jig_depth, $colour);

        line($x + $jig_depth, $y - $jig_depth, $x + 2*$jig_depth, $y - $jig_depth, $colour);
        line($x + $jig_depth, $y + $jig_line + $jig_depth, $x + 2*$jig_depth, $y + $jig_line + $jig_depth, $colour);

        line($x + 2*$jig_depth, $y - $jig_depth, $x + 2*$jig_depth, $y + $jig_line + $jig_depth, $colour);
    }
}

sub square {
    my ($x, $y, $colour) = @_;
    my $start_x = ($x) * $UNIT + $offset;
    my $start_y = ($y) * $UNIT + $offset;
    say qq{<rect x="${start_x}mm" y="${start_y}mm" width="${UNIT}mm" height="${UNIT}mm" fill="${colour}" style="opacity: 0.5" />}
    # say qq{<rect x="${start_x}mm" y="${start_y}mm" width="${UNIT}mm" height="${UNIT}mm" fill="none" stroke="${colour}" />}
}

sub end {
    say q{</svg>
    };
}

__DATA__
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="[% material.width %]mm" height="[% material.height %]mm" version="1.1"
    xmlns="http://www.w3.org/2000/svg">

    [% FOREACH tray IN trays %]
	<!-- [% tray.number %] -->
	<!-- Frame -->
	<rect x="[% tray.x %]mm" y="[% tray.y %]mm" width="48mm" height="109mm" fill="none" stroke="black" />
	<!-- Cutout -->
	<rect x="[% tray.x + 3 %]mm" y="[% tray.y + 3 %]mm" width="42mm" height="103mm" fill="none" stroke="black" />
	<!-- Base -->
	<rect x="[% tray.x + 48 %]mm" y="[% tray.y %]mm" width="48mm" height="109mm" fill="none" stroke="black" />
    [% END %]
</svg>