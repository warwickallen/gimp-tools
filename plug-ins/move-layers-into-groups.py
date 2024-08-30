from gimpfu import *
from math import ceil, log10

def move_layers_into_groups(img, drawable):
    # Start an undo group, so the process can be undone with one undo command
    pdb.gimp_image_undo_group_start(img)
    
    try:
        #layers = img.layers
        layer_count = len(img.layers)
        group_name_format = "p%0" + str(ceil(log10(layer_count))) + "d %s"

        # Iterate through all layers in the image
        for i in range(layer_count):
            layer = img.layers[i]
            # Skip layer groups to avoid nesting them unnecessarily
            if pdb.gimp_item_is_group(layer):
                continue

            # Create a new layer group with the same name as the layer
            group = pdb.gimp_layer_group_new(img)
            group.name = group_name_format % (i + 1, layer.name)
            pdb.gimp_image_insert_layer(img, group, None, i)
            
            # Move the layer into the newly created layer group
            pdb.gimp_image_reorder_item(img, layer, group, i)
            
            # Lock the layer's content and position
            pdb.gimp_item_set_lock_content(layer, True)
            pdb.gimp_item_set_lock_position(layer, True)
            
    finally:
        # End the undo group
        pdb.gimp_image_undo_group_end(img)
    
    # Update the display
    gimp.displays_flush()

register(
    "python-fu-move-layers-into-groups",
    "Move Layers into Groups",
    "Create a layer group for each existing layer that is not already in a group, move that layer into the new group, then lock the layer",
    "Warwick Allen",
    "Warwick Allen",
    "2024",
    "<Image>/Layer/Group/Move Layers into Groups",  # Menu location
    "*",  # Image types
    [],  # Parameters
    [],  # Results
    move_layers_into_groups)

main()
