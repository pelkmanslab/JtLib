import re


def get_microscope_type(image_filename):
    '''
    Determine the microscope type based on the image filename. Also return
    the regular expression pattern to determine the unique index of the image.
    '''
    # Visitron spinning disk
    if re.search(r'_s[0-9]+_r[0-9]+_c[0-9]+', image_filename):
        microscope = 'visi'
        pattern = re.compile('(_s[0-9]+_r[0-9]+_c[0-9]+)')
    # Yokogawa, a.k.a CV7k
    elif re.search(r'_[A-Z][0-9]+_T[0-9]+_F[0-9]+', image_filename):
        microscope = 'cv7k'
        pattern = re.compile('(_[A-Z][0-9]+_T[0-9]+_F[0-9]+)')
    else:
        raise Exception('Image filename didn\'t match any known patterns')
        microscope = None
        pattern = None
    return(microscope, pattern)


def get_image_channel(image_filename, microscope):
    '''
    Get image channel information form filename via regular expression pattern.
    '''
    if microscope == 'visi' or microscope == 'cv7k':
        r = re.compile('C(\d+)\.png$')
        channel = re.search(r, image_filename).group(1)
        channel = int(channel)
    else:
        raise Exception('Microscope type not supported.')
    return channel
