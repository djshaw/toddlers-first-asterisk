import argparse
import logging
import os
import sys


PREAMBLE = """# This is a generated file, do not edit. Regenerate with generate_extensions.py

[from-internal]
exten => _X!,1,Answer()
 same =>     n,Goto(paw-patrol,s,1)

exten => i,1,Goto(1,1)

[paw-patrol]
exten => i,1,Goto(s,1)
exten => t,1,Goto(s,1)

exten => s,1,Background(intro)
 same =>   n,WaitExten(600)

"""

CHARACTER_EXTENSION_MAP = {
    'chase': 1,
    'rocky': 2,
    'marshall': 3,
    'rubble': 4,
    'zuma': 5,
    'sky': 6,
    'ryder': 7
}

def get_wavs( directory ):
    """ For each .wav file in the provided directory, get the character that speaks the callout,
        and generate a multimap of character name to list of wav files.

        Call out wav files are of the form
            $CHARACTER-$UNIQUE_IDENTIFIER.wav
    """
    wavs = {}
    if not os.path.isdir( directory ):
        return wavs

    for file in os.listdir( directory ):
        if not file.endswith('wav') or not os.path.isfile( file ):
            continue

        character = file.split('-')[0]
        if character not in wavs:
            wavs[character] = [file]
        else:
            wavs[character].append( file )

    return wavs


def get_extension_for_character(character: str) -> str:
    """ For a given character, get their phone extension """
    if character in CHARACTER_EXTENSION_MAP:
        return CHARACTER_EXTENSION_MAP[character]

    logging.warning( 'Could not find an extension for character %s', character )

    return None


def get_extension_definition( wavs: dict[str, set[str]] ) -> str:
    """ For a set of characters with a set of callout wav files, generate an asterisk extension
        definition """
    character_block = PREAMBLE

    for character, callouts in wavs.items():
        assert len( callouts ) > 0

        extension = get_extension_for_character(character)
        if extension is None:
            continue
        character_block += \
            "exten => %(extension)d,1,Goto(%(extension)d,${RAND(1,%(callout_count)d)} * 2)\n" % \
                {'callout_count': len( callouts ),
                 'extension':     extension}

        for file in callouts:
            # pylint: disable-next=consider-using-f-string
            character_block += " same =>   n,Background(%(file)s)\n same =>   n,Goto(s,2)\n" % \
                { 'file': file.replace( '.wav', '' ) } # TODO: use regex replace: /.wav$//

    return character_block


def get_argparser() -> argparse.ArgumentParser:
    """ Gets an argument parser for the extensions generator """
    parser = argparse.ArgumentParser()
    parser.add_argument('--source',
                        help='The directory of sounds to create a asterisk dialplan',
                        action='store',
                        dest='source_dir',
                        default='sounds')
    return parser

def main( args: list[str] ) -> int:
    """ For a given directory of sounds, print an asterisk extension definition """
    parsed_args = get_argparser().parse_args(args[1:])

    directory = parsed_args.source_dir
    if not os.path.exists( directory ):
        parsed_args.print_help()
        return 1

    sys.stdout.write( get_extension_definition( get_wavs( directory ) ) )

    return 0


if __name__ == "__main__":
    sys.exit( main( sys.argv ) )
