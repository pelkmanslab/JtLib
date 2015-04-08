import re


def microscope_type(image_filename):
    '''
    Determine the microscope type based on the image filename. Also return
    the regular expression pattern to determine the unique index of the image.
    '''
    # Visitron spinning disk
    if re.search('[^_]+_s[0-9]+_r[0-9]+_c[0-9]+', image_filename):
        microscope = 'visi'
        pattern = '[^_]+(_s[0-9]+_r[0-9]+_c[0-9]+)'
    # Yokogawa, a.k.a CV7k
    elif re.search('[^_]+_[A-Z][0-9]+_T[0-9]+_F[0-9]+', image_filename):
        microscope = 'cv7k'
        pattern = '[^_]+(_[A-Z][0-9]+_T[0-9]+_F[0-9]+)'
    else:
        raise Exception('Image filename didn\'t match any known patterns')
        microscope = None
        pattern = None
    return(microscope, pattern)
