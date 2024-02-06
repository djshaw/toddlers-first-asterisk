""" Unit tests for generate_extensions.py """

import unittest

from generate_extensions import * # pylint: disable=wildcard-import, unused-wildcard-import

class GenerateExtensionsTest( unittest.TestCase ):
    maxDiff = None

    """ Test functions defined in generate_extensions.py """
    def test_get_extension_for_character( self ):
        """ Execute tests against get_extension_for_character() """
        self.assertEqual( 1,    get_extension_for_character( 'chase' ) )
        self.assertEqual( None, get_extension_for_character( 'asdf' ) )

    def test_get_extension_definition( self ):
        """ Execute tests against get_extension_for_character() """
        # pylint: disable-next=line-too-long
        self.assertEqual( """# This is a generated file, do not edit. Regenerate with generate_extensions.py

[from-internal]
exten => _X!,1,Answer()
 same =>     n,Goto(paw-patrol,s,1)

exten => i,1,Goto(1,1)

[paw-patrol]
exten => i,1,Goto(s,1)
exten => t,1,Goto(s,1)

exten => s,1,Background(intro)
 same =>   n,WaitExten(600)

""", get_extension_definition( {} ) )


        filename = 'foo'
        # pylint: disable-next=line-too-long
        self.assertEqual( """# This is a generated file, do not edit. Regenerate with generate_extensions.py

[from-internal]
exten => _X!,1,Answer()
 same =>     n,Goto(paw-patrol,s,1)

exten => i,1,Goto(1,1)

[paw-patrol]
exten => i,1,Goto(s,1)
exten => t,1,Goto(s,1)

exten => s,1,Background(intro)
 same =>   n,WaitExten(600)

exten => 1,1,Goto(1,${RAND(1,1)} * 2)
 same =>   n,Background(foo)
 same =>   n,Goto(s,2)
""", get_extension_definition( { 'chase': [filename + '.wav'] } ) )

        # TODO: tests for get_wavs()
