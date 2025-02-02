#!/usr/bin/env python3

import unittest
import os

class TestBasic(unittest.TestCase):
    def test_message_directory_exists(self):
        """Test that the message directory exists"""
        message_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'message')
        self.assertTrue(os.path.exists(message_dir), "message directory should exist")
        self.assertTrue(os.path.isdir(message_dir), "message directory should be a directory")

if __name__ == '__main__':
    unittest.main()
