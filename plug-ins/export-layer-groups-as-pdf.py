from gimpfu import *
from datetime import datetime
from os import path
from tempfile import gettempdir

def export_layer_groups_as_pdf(img, drawable):

    # Create a copy of the current image.
    img_copy = pdb.gimp_image_duplicate(img)
    
    # For each layer group in the copied image, merge the group into a single layer.
    for layer in img_copy.layers:
        if pdb.gimp_item_is_group(layer):
            merged_layer = pdb.gimp_image_merge_layer_group(img_copy, layer)

    # Export the copied image as a PDF.
    if img.filename:
        directory, filename = path.split(img.filename)
        name = path.splitext(filename)[0]
    else:
        directory = gettempdir()
        name = 'gimp_export'
    timestamp = datetime.now().strftime(' %Y%m%d-%H%M%S')
    filename = path.join(directory, name + timestamp + '.pdf')
    pdb.gimp_progress_init("Exporting Layers to PDF", None)
    pdb.file_pdf_save2(img_copy, img_copy.layers[0], filename, '?', 1, 1, 1, 1, 1)

    # Close the copied image without saving it.
    pdb.gimp_image_delete(img_copy)

    # Provide feedback that the PDF has been saved.
    pdb.gimp_message("Exported layer groups as PDF to: " + filename)

register(
    "python-fu-export-layer-groups-as-pdf",
    "Export Layer Groups as PDF",
    "Export each layer of the image as a separate page in a PDF",
    "Warwick Allen",
    "Warwick Allen",
    "2024",
    "<Image>/File/Custom/Export Layer Groups as PDF",  # Menu location
    "*",  # Image types
    [],  # Parameters
    [],  # Results
    export_layer_groups_as_pdf)

main()
