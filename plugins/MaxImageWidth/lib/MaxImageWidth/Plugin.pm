package MaxImageWidth::Plugin;

use strict;
use warnings;

sub xfrm_asset_options {
    my ( $cb, $app, $tmpl ) = @_;
    my $slug = <<END_TMPL;
<style type="text/css">
  .width-slider {
    width: 200px;
    margin-top: 10px;
  }

  .w-h {
      text-align: left;
    width: 120px;
    display: inline;
    margin-top: 10px;
  }

  .w-h input {
      width: 3.5em;
      text-align: center;
  }
</style>
END_TMPL
    $$tmpl =~ s{(<style>)}{$slug $1}msi;

}

sub asset_options_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog   = $app->blog;
    my $q      = $app->param;
    my $author = $app->user;
    my $plugin = $app->component('MaxImageWidth');
    my $config = $plugin->get_config_hash( 'blog:' . $blog->id );

    my $max_width = $config->{max_image_width};
    my $asset = $app->model('asset')->load({ id => $param->{id} })
        or die $app->error('No asset specified!?');
    $max_width ||= $param->{width} || $asset->image_width;
    my $asset_height = $asset->image_height || 0;

    my $old_html = q{\(<label for="thumb_width"><__trans phrase="width:"></label> <input type="text" name="thumb_width" id="thumb_width-<mt:var name="id">" class="text num" value="<mt:var name="thumb_width" escape="html">"/> <__trans phrase="pixels">\)\s+<input type="hidden" name="thumb_height" value="<mt:var name="thumb_height" escape="html">" />};
    use Data::Dumper;
    # MT->log("Image size: $param->{width}, ".Dumper($param));
    my $new_html = <<NEW_HTML;
<script type="text/javascript">
    var full_width = <mt:Var name="thumb_width" escape="html">;
    var full_height = $asset_height;
    var max_width = $max_width;
    jQuery(document).ready( function() {
        jQuery('#thumb_width-<mt:Var name="id">').change( function() {
            var new_w = jQuery(this).val();
            if (new_w > max_width) {
                jQuery(this).val( max_width );
            }
            jQuery('#thumb_height-<mt:Var name="id">')
                .val( Math.floor( (full_height * jQuery(this).val() ) / full_width) );
            jQuery('#width-slider-<mt:Var name="id">')
                .slider('option', 'value', jQuery(this).val());
        });

        jQuery('#thumb_height-<mt:Var name="id">').change( function() {
            var new_h = jQuery(this).val();
            var new_w = Math.floor( (full_width * new_h ) / full_height );
            if (new_w > max_width) {
                jQuery('#thumb_width-<mt:Var name="id">').val( max_width ).trigger('change');
                return;
            }
            jQuery('#thumb_width-<mt:Var name="id">').val( new_w );
            jQuery('#width-slider-<mt:Var name="id">').slider('option', 'value', new_w);
        });

        jQuery('#width-slider-<mt:Var name="id">').slider({
            slide: function(event, ui) {
                jQuery('#thumb_width-<mt:Var name="id">').val( ui.value );
                jQuery('#thumb_height-<mt:Var name="id">')
                    .val( Math.floor( (full_height * ui.value ) / full_width) );
            },
            max: max_width
        });

        jQuery('#width-slider-<mt:Var name="id">').slider('value', max_width);

        if (full_width > max_width) {
            jQuery('#thumb_width-<mt:Var name="id">').trigger('change');
        }
    });
</script>
        <div id="w-h-<mt:Var name="id">" class="w-h">
            <span>(width &times; height)</span>
            <input type="text" size="3"
                name="thumb_width"
                id="thumb_width-<mt:var name="id">"
                class="text num"
                value="<mt:Var name="thumb_width" escape="html">" />
            &times;
            <input type="text" size="3"
                name="thumb_height"
                id="thumb_height-<mt:Var name="id">"
                class="text num"
                value="$asset_height" />
        </div>
        <div id="width-slider-<mt:Var name="id">" class="width-slider"></div>
NEW_HTML

    my $text = $tmpl->text;
    $text =~ s/$old_html/$new_html/msi;
    $tmpl->text($text);

}

1;
__END__
