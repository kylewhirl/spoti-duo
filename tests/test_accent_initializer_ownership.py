"""The init-family hook must not return a +0 factory color to a +1 caller."""
from pathlib import Path
import unittest
class AccentInitializerOwnership(unittest.TestCase):
 def test_instance_initializer_only_forwards_original_ownership(self):
  s=(Path(__file__).resolve().parents[1]/'tweak/Sources/Redesigned/Kit/SGRAccent.x').read_text()
  start=s.index('- (UIColor *)initWithRed:');end=s.index('+ (UIColor *)colorWithRed:',start)
  method=s[start:end]
  self.assertNotIn('colorWithDynamicProvider',method)
  self.assertIn('return%orig(r,g,b,a);', ''.join(method.split()))
