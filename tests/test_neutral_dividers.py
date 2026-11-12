"""Dividers must not inherit artwork or accent color."""
from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]/'tweak/Sources'
class NeutralDividers(unittest.TestCase):
    def test_shared_hairline_is_neutral(self):
        s=(R/'Redesigned/Kit/SGRTokens.m').read_text().split('UIColor *SGRHairline(void)',1)[1].split('UIColor *SGRElevated',1)[0]
        self.assertIn('SGAppearanceColor(',s)
        self.assertIn('colorWithWhite:0 alpha:alpha',s)
        self.assertIn('colorWithWhite:1 alpha:alpha',s)
        self.assertNotIn('tonalToken(',s)
        self.assertNotIn('SGRAccent',s)
    def test_row_surfaces_share_neutral_token(self):
        for surface in ['Playlist','Album','Library']:
            s=(R/f'Redesigned/{surface}/{surface}Rows.x').read_text()
            self.assertIn('SGRHairline().CGColor',s)
