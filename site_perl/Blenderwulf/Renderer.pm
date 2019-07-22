package Blenderwulf::Renderer;

use strict;
use warnings;

use File::Temp qw(tempfile);
use Blenderwulf::Config qw(conf_value);

my $blender_command = conf_value('blender_command');
    
sub new {
    
}

sub pack_libraries {
    my $infile = shift;
    my $outfile = shift;

    my $script = <<"EOT";
import bpy
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath="$outfile")
EOT

    my ($fh, $fn) = tempfile(UNLINK => 1);
    print $fh $script;
    close $fh;

    system("$blender_command -b $infile -P $fn");
}

sub get_render_size_from_file {
    my $infile = shift;

    my $script = <<"EOT";
import bpy
print("######## DIMS", bpy.context.scene.render.resolution_x, "#", bpy.context.scene.render.resolution_y)
EOT

    my ($fh, $fn) = tempfile(UNLINK => 1);
    print $fh $script;
    close $fh;

    my $output = `$blender_command -b $infile -P $fn`;
    $output =~ /^######## DIMS (\d+) # (\d+)$/m;
    return ($1, $2);
}

sub render_from_area {
    my $infile = shift;
    my $outfile = shift;
    my ($x, $y, $w, $h, $threads, $output_callback) = @_;
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
scene.render.use_placeholder = False
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
x = $x
y = $y
left = (width + (2 * x)) / orig_res_x
top = (height + (2 * y)) / orig_res_y

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
render.use_placeholder = False
render.use_file_extension = False
render.filepath = "$outfile"

bpy.ops.render.render(write_still=True)

EOT
    my ($fh, $fn) = tempfile(UNLINK => 1);
    print $fh $script;
    close $fh;
    my $blender_fh;
    open $blender_fh, "$blender_command -b $infile -t $threads -P $fn|";
    while(<$blender_fh>) {
        $output_callback->($_);
    }
    close $blender_fh;
}


1;
