package MaxImageWidth::Plugin;

use strict;

sub xfrm_asset_options {
    my ( $cb, $app, $tmpl ) = @_;
    my $slug;
    $slug = <<END_TMPL;
<link type="text/css" href="<mt:StaticWebPath>jquery/themes/flora/flora.all.css" rel="stylesheet" />
<style type="text/css">
  #create_thumbnail-field {
    display: none;
  }

  #create_thumbnail_cb {
    float: left;
    padding-right: 10px;
    margin-top: 10px;
  }

  #width-slider {
    float: left;
    width: 200px;
    margin-top: 10px;
  }

  #w-h {
    width: 120px;
    float: left;
    margin-top: 10px;
  }

  #w-h input {
      width: 3.5em;
      text-align: center;
  }

  .dialog #image_alignment-field {
      top: 0;
  }
</style>
END_TMPL
    $$tmpl =~ s{(<mt:setvarblock name="html_head" append="1">)}{$1 $slug}msi;

}

sub asset_options_param {
    my ( $cb, $app, $param, $tmpl ) = @_;

    my $blog          = $app->blog;
    my $q             = $app->param;
    my $author        = $app->user;
    my $plugin        = MT->component('MaxImageWidth');
    my $config        = $plugin->get_config_hash( 'blog:' . $blog->id );

    my $max_width     = $config->{max_image_width};
    $max_width ||= $param->{width};

    my $ct_field = $tmpl->getElementById('create_thumbnail')
      or return $app->error('cannot get the create thumbnail block');
    my $new_field = $tmpl->createElement(
        'app:setting',
        {
            id    => 'create_thumbnail2',
            class => '',
            label => $app->translate("Use thumbnail"),
            label_class => "no-header",
            hint => "",
            show_hint => "0",
            help_page => "file_upload",
            help_section => "creating_thumbnails"
        }
    ) or return $app->error('cannot create the su_twitter element');
    my $mt = ($param->{make_thumb} ? 'checked="checked"' : '');
    my $html = <<HTML;
<script type="text/javascript">
    var full_width = $param->{width};
    var full_height = $param->{height};
    var max_width = $max_width;
    jQuery(document).ready( function() {
        jQuery('#thumb_width').change( function() {
            var new_w = jQuery(this).val();
            if (new_w > max_width) {
                jQuery(this).val( max_width );
            }
            jQuery('#thumb_height').val( Math.floor( (full_height * jQuery(this).val() ) / full_width) );
            jQuery('#width-slider').slider('option', 'value', jQuery(this).val());
        });

        jQuery('#thumb_height').change( function() {
            var new_h = jQuery(this).val();
            var new_w = Math.floor( (full_width * new_h ) / full_height );
            if (new_w > max_width) {
                jQuery('#thumb_width').val( max_width ).trigger('change');
                return;
            }
            jQuery('#thumb_width').val( new_w );
            jQuery('#width-slider').slider('option', 'value', new_w);
        });

        jQuery('#width-slider').slider({
            slide: function(event, ui) {
                jQuery('#thumb_width').val( ui.value );
                jQuery('#thumb_height').val( Math.floor( (full_height * ui.value ) / full_width) );
            },
            max: max_width
        });

        jQuery('#width-slider').slider('value', max_width);

        if (full_width > max_width) {
            jQuery('#thumb_width').trigger('change');
        }
    });
</script>
        <div id="create_thumbnail_cb">
            <input type="checkbox" name="thumb" id="create_thumbnail" value="1" $mt />
            <label for="create_thumbnail">Use thumbnail?</label>
        </div>
        <div id="w-h">
            <input type="text" id="thumb_width" size="3" name="thumb_width" value="$param->{width}" />
            &times;
            <input type="text" id="thumb_height" size="3" name="thumb_height" value="$param->{height}" />
        </div>
        <div id="width-slider"></div>
HTML
    $new_field->innerHTML($html);
    $tmpl->insertAfter( $new_field, $ct_field )
      or return $app->error('failed to insertAfter.');
    $ct_field->innerHTML('');

    $param;
}

1;
__END__
