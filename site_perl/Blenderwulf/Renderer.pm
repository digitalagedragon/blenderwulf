package Blenderwulf::Renderer;

use strict;
use warnings;

use File::Temp qw(tempfile);

sub new {
    
}

sub _get_render_size_from_file {
    my $infile = shift;

    my $script = <<"EOT";
import bpy
print("######## DIMS", bpy.context.scene.render.resolution_x, "#", bpy.context.scene.render.resolution_y)
EOT

    my ($fh, $fn) = tempfile(UNLINK => 1);
    print $fh $script;
    close $fh;

    my $output = `blender -b $infile -P $fn`;
    $output =~ /^######## DIMS (\d+) # (\d+)$/m;
    return ($1, $2);
}

sub _render_from_area {
    my $infile = shift;
    my $outfile = shift;
    my ($x, $y, $w, $h) = @_;
=comment
    my $script = <<"EOT";
import bpy
scene = bpy.context.scene

scene.render.tile_x = 32
scene.render.tile_y = 32
scene.render.border_min_x = $x1
scene.render.border_max_x = $x2
scene.render.border_min_y = $y1
scene.render.border_max_y = $y2
scene.render.use_border = True
scene.render.use_crop_to_border = True
scene.render.resolution_percentage = 100
scene.render.display_mode = 'NONE'
EOT
=cut

    my $script = <<"EOT";
import bpy
scene = bpy.context.scene
render = scene.render
camera = scene.camera

orig_res_x = render.resolution_x
orig_res_y = render.resolution_y

width = $w
height = $h
left = (width + (2 * $x)) / orig_res_x
top = (height + (2 * $y)) / orig_res_y

if orig_res_x > orig_res_y:
    if width > height:
        camera.data.lens /= width / orig_res_x
    else:
        camera.data.lens *= orig_res_x / height
else:
    if width > height:
        camera.data.lens *= orig_res_y / width
    else:
        camera.data.lens /= height / orig_res_y

render.resolution_x = width
render.resolution_y = height

if width > height:
    camera.data.shift_x = (0.5 * (top - 1)) / (width / orig_res_x)
else:
    camera.data.shift_x = (0.5 * width * (left - 1)) / (height * (width / orig_res_x))

if width > height:
    camera.data.shift_y = (0.5 * height * (left - 1)) / (width * (height / orig_res_y))
else:
    camera.data.shift_y = (0.5 * (top - 1)) / (height / orig_res_y)

render.resolution_percentage = 100
render.tile_x = 32
render.tile_y = 32
EOT
    my ($fh, $fn) = tempfile(UNLINK => 1);
    print $fh $script;
    close $fh;
    system("blender -b $infile -o $outfile -P $fn -F PNG -E CYCLES -f 1");
}


1;
